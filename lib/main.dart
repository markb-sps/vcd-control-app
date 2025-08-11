import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'spray_schedule_page.dart';

/// Entry point of the application.
void main() {
  runApp(const MyApp());
}

/// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber.shade700),
        primaryColor: Colors.amber.shade700,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// A splash screen that shows an image for two seconds then navigates to the device list page.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeviceListPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/bee.png',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

/// Page that scans for BLE devices and lists them.
class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _initBle() async {
    await _ensureLocationService();
    await _requestPermissions();
    await _startScan();
  }

  Future<void> _ensureLocationService() async {
    final serviceStatus = await Permission.location.serviceStatus;
    if (serviceStatus != ServiceStatus.enabled) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Disabled'),
          content: const Text(
              'Location services must be enabled for Bluetooth scanning.'),
          actions: [
            TextButton(
              onPressed: () async {
                await openAppSettings();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    // Wait until Bluetooth is turned on before scanning:contentReference[oaicite:0]{index=0}.
    await FlutterBluePlus.adapterState
        .where((state) => state == BluetoothAdapterState.on)
        .first;

    // Listen for scan results. New results are emitted through this stream:contentReference[oaicite:1]{index=1}.
    _scanSubscription = FlutterBluePlus.onScanResults.listen(
          (results) {
        setState(() {
          _scanResults = results
              .where((r) {
                final advName = r.advertisementData.advName;
                final deviceName = r.device.platformName;
                return advName == 'SPSA-VCD' || deviceName == 'SPSA-VCD';
              })
              .toList();
        });
      },
      onError: (error) {
        debugPrint('Scan error: $error');
      },
    );

    // Start scanning with a timeout; it stops automatically after the given duration:contentReference[oaicite:2]{index=2}.
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    // Wait for scanning to finish:contentReference[oaicite:3]{index=3}.
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive Sprayers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isScanning
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
            transform: GradientRotation(30 * math.pi / 180),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _scanResults.isEmpty
                  ? const Center(child: Text('No devices found.'))
                  : ListView.builder(
                      itemCount: _scanResults.length,
                      itemBuilder: (context, index) {
                        final result = _scanResults[index];
                        final device = result.device;
                        final name = result.advertisementData.advName.isNotEmpty
                            ? result.advertisementData.advName
                            : (device.platformName.isNotEmpty
                                ? device.platformName
                                : device.remoteId.str);
                        return ListTile(
                          leading: Image.asset(
                            'assets/images/bee.png',
                            width: 24,
                            height: 24,
                          ),
                          title: Text(name),
                          subtitle: Text(device.remoteId.str),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CurrentTimePage(
                                  device: device,
                                  name: name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'If your device does not appear, power cycle spray equipment and then rescan.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page that connects to a BLE device and reads the current time from the
/// Current Time Service.
class CurrentTimePage extends StatefulWidget {
  final BluetoothDevice device;
  final String name;

  const CurrentTimePage({super.key, required this.device, required this.name});

  @override
  State<CurrentTimePage> createState() => _CurrentTimePageState();
}

class _CurrentTimePageState extends State<CurrentTimePage> {
  bool _isConnecting = true;
  String _status = 'Connecting...';
  String? _currentTime;

  @override
  void initState() {
    super.initState();
    _connectAndRead();
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  /// Connect to the device, discover services, and read the current time
  /// characteristic from the Current Time Service.
  Future<void> _connectAndRead() async {
    try {
      await widget.device.connect();
      setState(() {
        _status = 'Discovering services...';
      });

      final services = await widget.device.discoverServices();
      const String ctsServiceUuid = '1805';
      const String ctsCharUuid = '2A2B';
      BluetoothCharacteristic? ctsChar;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() == ctsServiceUuid.toLowerCase()) {
          for (final c in service.characteristics) {
            if (c.uuid.str.toLowerCase() == ctsCharUuid.toLowerCase()) {
              ctsChar = c;
              break;
            }
          }
        }
        if (ctsChar != null) break;
      }

      if (ctsChar != null) {
        setState(() {
          _status = 'Setting current time...';
        });
        await _setCurrentUtcTime(ctsChar);
        setState(() {
          _status = 'Reading current time characteristic...';
        });
        final List<int> value = await ctsChar.read();
        if (value.length >= 7) {
          final int year = value[0] | (value[1] << 8);
          final int month = value[2];
          final int day = value[3];
          final int hour = value[4];
          final int minute = value[5];
          final int second = value[6];
          final dateTime =
              DateTime.utc(year, month, day, hour, minute, second);
          _currentTime = dateTime.toUtc().toString();
          setState(() {
            _status = 'Current time received';
          });
        } else {
          setState(() {
            _status = 'Current time characteristic returned no data';
          });
        }
      } else {
        setState(() {
          _status = 'Current Time characteristic not found';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  /// Write the current UTC time to the Current Time Service characteristic.
  Future<void> _setCurrentUtcTime(BluetoothCharacteristic ctsChar) async {
    final now = DateTime.now().toUtc();
    final int year = now.year;
    final List<int> data = [
      year & 0xFF,
      (year >> 8) & 0xFF,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.weekday,
      0x00, // Fractions256
      0x01, // Adjust Reason: manual time update
    ];
    await ctsChar.write(data, withoutResponse: false);
  }

  /// Write a value to the LED characteristic to turn the LED on or off.
  Future<void> _setLed(bool on) async {
    try {
      const String ledServiceUuid = 'FFB0';
      const String ledCharUuid = 'FFB1';
      final services = await widget.device.discoverServices();
      BluetoothCharacteristic? ledChar;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() == ledServiceUuid.toLowerCase()) {
          for (final c in service.characteristics) {
            if (c.uuid.str.toLowerCase() == ledCharUuid.toLowerCase()) {
              ledChar = c;
              break;
            }
          }
        }
        if (ledChar != null) break;
      }

      if (ledChar != null) {
        await ledChar.write([on ? 0x01 : 0x00], withoutResponse: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('LED ${on ? 'on' : 'off'} command sent')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('LED characteristic not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Trigger the pump test characteristic.
  Future<void> _testPump() async {
    try {
      const String serviceUuid = 'FFB0';
      const String pumpCharUuid = 'FFB2';
      final services = await widget.device.discoverServices();
      BluetoothCharacteristic? pumpChar;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
          for (final c in service.characteristics) {
            if (c.uuid.str.toLowerCase() == pumpCharUuid.toLowerCase()) {
              pumpChar = c;
              break;
            }
          }
        }
        if (pumpChar != null) break;
      }

      if (pumpChar != null) {
        await pumpChar.write([0x01], withoutResponse: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pump test command sent')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pump characteristic not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Trigger the heater test characteristic.
  Future<void> _testHeater() async {
    try {
      const String serviceUuid = 'FFB0';
      const String heaterCharUuid = 'FFB3';
      final services = await widget.device.discoverServices();
      BluetoothCharacteristic? heaterChar;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
          for (final c in service.characteristics) {
            if (c.uuid.str.toLowerCase() == heaterCharUuid.toLowerCase()) {
              heaterChar = c;
              break;
            }
          }
        }
        if (heaterChar != null) break;
      }

      if (heaterChar != null) {
        await heaterChar.write([0x01], withoutResponse: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Heater test command sent')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Heater characteristic not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Write the spray schedule to the device.
  Future<void> _setSchedule(
      TimeOfDay start, int repeatSeconds, int amountMl, String periodLabel) async {
    try {
      const String serviceUuid = '01001234-5678-1234-1234-5678abcdeff0';
      const String scheduleCharUuid = '02001234-5678-1234-1234-5678abcdeff1';
      final services = await widget.device.discoverServices();
      BluetoothCharacteristic? scheduleChar;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() == serviceUuid) {
          for (final c in service.characteristics) {
            if (c.uuid.str.toLowerCase() == scheduleCharUuid) {
              scheduleChar = c;
              break;
            }
          }
        }
        if (scheduleChar != null) break;
      }

      if (scheduleChar != null) {
        // Interpret the picked time in the local time zone then convert to UTC
        // before sending over BLE so the device receives a UTC epoch value.
        DateTime nowLocal = DateTime.now();
        DateTime startLocal = DateTime(
            nowLocal.year, nowLocal.month, nowLocal.day, start.hour, start.minute);
        if (startLocal.isBefore(nowLocal)) {
          startLocal = startLocal.add(const Duration(days: 1));
        }
        final int startEpoch = startLocal.toUtc().millisecondsSinceEpoch ~/ 1000;
        final int repeatPeriod = repeatSeconds;
        const int repeatCount = 0xFFFFFFFF;

        final data = ByteData(20);
        data.setUint64(0, startEpoch, Endian.little);
        data.setUint32(8, repeatPeriod, Endian.little);
        data.setUint32(12, repeatCount, Endian.little);
        data.setUint16(16, amountMl, Endian.little);
        data.setUint16(18, 0, Endian.little);

        await scheduleChar.write(data.buffer.asUint8List(), withoutResponse: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Schedule set for ${start.format(context)} every $periodLabel, $amountMl ml')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule characteristic not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openSchedule() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const SpraySchedulePage()),
    );
    if (result != null && mounted) {
      final TimeOfDay start = result['start'] as TimeOfDay;
      final int repeat = result['repeatSeconds'] as int;
      final int amount = result['amountMl'] as int;
      final String label = _formatPeriod(repeat);
      await _setSchedule(start, repeat, amount, label);
    }
  }

  String _formatPeriod(int seconds) {
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      return hours == 1 ? '1 hour' : '$hours hours';
    } else if (seconds >= 60) {
      final minutes = seconds ~/ 60;
      return minutes == 1 ? '1 min' : '$minutes min';
    } else {
      return '$seconds sec';
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.amber.shade700,
      foregroundColor: Colors.black,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
            transform: GradientRotation(30 * math.pi / 180),
          ),
        ),
        child: Center(
          child: _isConnecting
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_status),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _openSchedule,
                        style: buttonStyle,
                        child: const Text('Schedule Spray'),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => _setLed(true),
                            style: buttonStyle,
                            child: const Text('LED On'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _setLed(false),
                            style: buttonStyle,
                            child: const Text('LED Off'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _testPump,
                            style: buttonStyle,
                            child: const Text('Test Pump'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _testHeater,
                            style: buttonStyle,
                            child: const Text('Test Heater'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_currentTime != null)
                        Text(
                          'Device Time (UTC): $_currentTime',
                          style: const TextStyle(fontSize: 20),
                        )
                      else
                        Text(
                          _status,
                          style: const TextStyle(fontSize: 20),
                        ),
                      const Spacer(),
                      Text(
                        'MAC: ${widget.device.remoteId.str}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
