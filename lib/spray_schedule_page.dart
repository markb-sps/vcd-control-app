import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpraySchedulePage extends StatefulWidget {
  final List<int> allowedAmounts;

  const SpraySchedulePage({super.key, required this.allowedAmounts});

  @override
  State<SpraySchedulePage> createState() => _SpraySchedulePageState();
}

class _SpraySchedulePageState extends State<SpraySchedulePage> {
  late TimeOfDay _startTime;
  int _repeatSeconds = 60;
  late List<int> _amountOptions;
  int? _amountMl;

  @override
  void initState() {
    super.initState();
    _startTime = TimeOfDay.now();
    _amountOptions = widget.allowedAmounts.toSet().toList()..sort();
    if (_amountOptions.isNotEmpty) {
      _amountMl = _amountOptions.first;
    }
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  void _save() {
    if (_amountMl == null) {
      return;
    }
    Navigator.of(context).pop({
      'start': _startTime,
      'repeatSeconds': _repeatSeconds,
      'amountMl': _amountMl!,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spray Schedule'),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickStartTime,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Repeat Every:'),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: _repeatSeconds,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _repeatSeconds = value;
                        });
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 sec')),
                      DropdownMenuItem(value: 60, child: Text('1 min')),
                      DropdownMenuItem(value: 300, child: Text('5 min')),
                      DropdownMenuItem(value: 900, child: Text('15 min')),
                      DropdownMenuItem(value: 1800, child: Text('30 min')),
                      DropdownMenuItem(value: 3600, child: Text('1 hour')),
                      DropdownMenuItem(value: 7200, child: Text('2 hours')),
                      DropdownMenuItem(value: 21600, child: Text('6 hours')),
                      DropdownMenuItem(value: 43200, child: Text('12 hours')),
                      DropdownMenuItem(value: 86400, child: Text('24 hours')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Amount:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _amountMl,
                      hint: const Text('Select amount'),
                      onChanged: _amountOptions.isEmpty
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _amountMl = value;
                                });
                              }
                            },
                      items: _amountOptions
                          .map(
                            (amount) => DropdownMenuItem(
                              value: amount,
                              child: Text('$amount ml'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              if (_amountOptions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No calibration data available. Please add a calibration first.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _amountMl == null ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
