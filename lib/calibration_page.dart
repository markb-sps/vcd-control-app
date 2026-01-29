import 'package:flutter/material.dart';

import 'calibration_entry.dart';

class CalibrationPageData {
  final List<CalibrationEntry> calibrations;
  final String? error;
  final bool isReading;

  const CalibrationPageData({
    required this.calibrations,
    required this.error,
    required this.isReading,
  });
}

class CalibrationPage extends StatefulWidget {
  final CalibrationPageData initialData;
  final Future<CalibrationPageData> Function() onRefresh;
  final Future<void> Function(int slot) onEditSlot;

  const CalibrationPage({
    super.key,
    required this.initialData,
    required this.onRefresh,
    required this.onEditSlot,
  });

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  late List<CalibrationEntry> _calibrations;
  String? _error;
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _calibrations = widget.initialData.calibrations;
    _error = widget.initialData.error;
    _isReading = widget.initialData.isReading;
  }

  Future<void> _refresh() async {
    setState(() {
      _isReading = true;
    });
    final data = await widget.onRefresh();
    if (!mounted) {
      return;
    }
    setState(() {
      _calibrations = data.calibrations;
      _error = data.error;
      _isReading = data.isReading;
    });
  }

  Future<void> _editSlot(int slot) async {
    await widget.onEditSlot(slot);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibration Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
            transform: GradientRotation(30 * 3.141592653589793 / 180),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildCalibrationSection(),
        ),
      ),
    );
  }

  Widget _buildCalibrationSection() {
    if (_isReading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _calibrations.isEmpty) {
      return Text(
        _error!,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      );
    }
    final cards = List<Widget>.generate(kMaxCalibrationEntries, (slot) {
      final entry =
          _calibrations.cast<CalibrationEntry?>().firstWhere(
                (item) => item?.slot == slot,
                orElse: () => null,
              );
      final subtitle = entry != null
          ? 'Dose: ${entry.dosageMl} ml\nSpray Time: ${entry.sprayTimeMs} ms'
          : 'Empty slot';
      return Card(
        color: Colors.white,
        child: ListTile(
          title: Text('Slot ${slot + 1}'),
          subtitle: Text(subtitle),
          isThreeLine: entry != null,
          trailing: const Icon(Icons.edit),
          onTap: () => _editSlot(slot),
        ),
      );
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calibration Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: [
              ...cards,
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_calibrations.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Tap a slot above to add calibration data for the device.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

const int kMaxCalibrationEntries = 5;
