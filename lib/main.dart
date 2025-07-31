import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
        primarySwatch: Colors.blue,
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
    await _requestPermissions();
    await _startScan();
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
        title: const Text('BLE Devices'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: _scanResults.isEmpty
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
    );
  }
}

/// Page that connects to a BLE device and reads its battery level.
class DeviceDetailPage extends StatefulWidget {
  final BluetoothDevice device;
  final String name;

  const DeviceDetailPage({super.key, required this.device, required this.name});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  bool _isConnecting = true;
  double? _batteryValue;
  String _status = 'Connecting...';

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

  /// Connect to the device, discover services, and read the battery level characteristic.
  Future<void> _connectAndRead() async {
    try {
      await widget.device.connect(); // connect to device:contentReference[oaicite:4]{index=4}.
      setState(() {
        _status = 'Discovering services...';
      });

      final services = await widget.device.discoverServices(); // discover services:contentReference[oaicite:5]{index=5}.

      const String batteryServiceUuid = '180F';
      const String batteryCharUuid = '2A19';
      BluetoothCharacteristic? batteryChar;

      for (final service in services) {
        if (service.uuid.str.toLowerCase() ==
            batteryServiceUuid.toLowerCase()) {
          for (final c in service.characteristics) {
            if (c.uuid.str.toLowerCase() ==
                batteryCharUuid.toLowerCase()) {
              batteryChar = c;
              break;
            }
          }
        }
        if (batteryChar != null) break;
      }

      if (batteryChar != null) {
        setState(() {
          _status = 'Reading battery characteristic...';
        });
        final List<int> value = await batteryChar.read(); // read characteristic:contentReference[oaicite:6]{index=6}.
        if (value.isNotEmpty) {
          double voltage;
          if (value.length >= 2) {
            final int raw = value[0] | (value[1] << 8);
            voltage = raw / 1000.0; // two‑byte voltage in mV converted to V.
          } else {
            voltage = value[0].toDouble() / 100.0; // heuristic for one‑byte battery level.
          }
          _batteryValue = voltage;
          setState(() {
            _status = 'Battery value received';
          });
        } else {
          setState(() {
            _status = 'Battery characteristic returned no data';
          });
        }
      } else {
        setState(() {
          _status = 'Battery characteristic not found';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Center(
        child: _isConnecting
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_batteryValue != null)
              Text(
                'Battery: ${_batteryValue!.toStringAsFixed(2)} V',
                style: const TextStyle(fontSize: 32),
              )
            else
              Text(
                _status,
                style: const TextStyle(fontSize: 20),
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
          final dateTime = DateTime(year, month, day, hour, minute, second);
          _currentTime = dateTime.toLocal().toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Center(
        child: _isConnecting
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MAC: ${widget.device.remoteId.str}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_currentTime != null)
              Text(
                _currentTime!,
                style: const TextStyle(fontSize: 20),
              )
            else
              Text(
                _status,
                style: const TextStyle(fontSize: 20),
              ),
          ],
        ),
      ),
    );
  }
}
