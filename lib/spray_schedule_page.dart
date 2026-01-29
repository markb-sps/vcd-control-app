import 'dart:math' as math;

import 'package:flutter/material.dart';

class SpraySchedulePage extends StatefulWidget {
  final List<int> allowedAmounts;

  const SpraySchedulePage({super.key, required this.allowedAmounts});

  @override
  State<SpraySchedulePage> createState() => _SpraySchedulePageState();
}

class _SpraySchedulePageState extends State<SpraySchedulePage> {
  static const int _wakeMagicEpochSeconds = 1;
  static final DateTime _wakeMagicDateTime =
      DateTime.fromMillisecondsSinceEpoch(
    _wakeMagicEpochSeconds * 1000,
    isUtc: true,
  );

  late TimeOfDay _startTime;
  late DateTime _startDate;
  bool _startOnWake = false;
  int _initialRepeatSeconds = 60;
  int _secondaryRepeatSeconds = 0;
  int _initialRepeatCount = _repeatCountForever;
  int _secondaryRepeatCount = _repeatCountForever;
  late List<int> _amountOptions;
  int _initialAmountMl = 0;
  int _secondaryAmountMl = 0;

  static const int _repeatCountForever = 0xFFFFFFFF;
  static final List<int> _repeatCountOptions = [
    ...List<int>.generate(21, (index) => index),
    _repeatCountForever,
  ];

  static const List<_PeriodOption> _periodOptions = [
    _PeriodOption(seconds: 0, label: 'Never'),
    _PeriodOption(seconds: 30, label: '30 sec'),
    _PeriodOption(seconds: 60, label: '1 min'),
    _PeriodOption(seconds: 300, label: '5 min'),
    _PeriodOption(seconds: 900, label: '15 min'),
    _PeriodOption(seconds: 1800, label: '30 min'),
    _PeriodOption(seconds: 3600, label: '1 hour'),
    _PeriodOption(seconds: 7200, label: '2 hours'),
    _PeriodOption(seconds: 21600, label: '6 hours'),
    _PeriodOption(seconds: 43200, label: '12 hours'),
    _PeriodOption(seconds: 86400, label: '24 hours'),
  ];

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _startTime = TimeOfDay.fromDateTime(_startDate);
    _amountOptions = widget.allowedAmounts.toSet().toList()..sort();
    if (_amountOptions.isNotEmpty) {
      _initialAmountMl = _amountOptions.first;
    }
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
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
    final startDateTime = _startOnWake
        ? _wakeMagicDateTime
        : DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
    Navigator.of(context).pop({
      'start': startDateTime,
      'initialRepeatSeconds': _initialRepeatSeconds,
      'initialRepeatCount': _initialRepeatCount,
      'initialAmountMl': _initialAmountMl,
      'secondaryRepeatSeconds': _secondaryRepeatSeconds,
      'secondaryRepeatCount': _secondaryRepeatCount,
      'secondaryAmountMl': _secondaryAmountMl,
    });
  }

  Widget _buildStartModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFB300)],
                  )
                : null,
            border: isSelected
                ? null
                : Border.all(
                    color: Colors.black.withOpacity(0.2),
                  ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.deepOrange : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSection({
    required String title,
    required int repeatSeconds,
    required ValueChanged<int> onRepeatSecondsChanged,
    required int amountMl,
    required ValueChanged<int> onAmountChanged,
    required int repeatCount,
    required ValueChanged<int> onRepeatCountChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Spray Period:'),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: repeatSeconds,
                onChanged: (value) {
                  if (value != null) {
                    onRepeatSecondsChanged(value);
                  }
                },
                items: _periodOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.seconds,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Amount:'),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: amountMl,
                  onChanged: _amountOptions.isEmpty
                      ? null
                      : (value) {
                          if (value != null) {
                            onAmountChanged(value);
                          }
                        },
                  items: [
                    const DropdownMenuItem(
                      value: 0,
                      child: Text('None'),
                    ),
                    ..._amountOptions.map(
                      (amount) => DropdownMenuItem(
                        value: amount,
                        child: Text('$amount ml'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Repeat Count:'),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: repeatCount,
                onChanged: (value) {
                  if (value != null) {
                    onRepeatCountChanged(value);
                  }
                },
                items: _repeatCountOptions
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text(
                          count == _repeatCountForever
                              ? 'Forever'
                              : '$count times',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
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
              Row(
                children: [
                  _buildStartModeButton(
                    label: 'Start Date/Time',
                    isSelected: !_startOnWake,
                    onPressed: () {
                      setState(() {
                        _startOnWake = false;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildStartModeButton(
                    label: 'Start on Wake',
                    isSelected: _startOnWake,
                    onPressed: () {
                      setState(() {
                        _startOnWake = true;
                      });
                    },
                  ),
                ],
              ),
              if (!_startOnWake) ...[
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Start Date'),
                  subtitle: Text(
                    MaterialLocalizations.of(context).formatFullDate(_startDate),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickStartDate,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(_startTime.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: _pickStartTime,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _buildScheduleSection(
                title: 'Initial Spray',
                repeatSeconds: _initialRepeatSeconds,
                onRepeatSecondsChanged: (value) {
                  setState(() {
                    _initialRepeatSeconds = value;
                  });
                },
                amountMl: _initialAmountMl,
                onAmountChanged: (value) {
                  setState(() {
                    _initialAmountMl = value;
                  });
                },
                repeatCount: _initialRepeatCount,
                onRepeatCountChanged: (value) {
                  setState(() {
                    _initialRepeatCount = value;
                  });
                },
              ),
              _buildScheduleSection(
                title: 'Secondary Spray',
                repeatSeconds: _secondaryRepeatSeconds,
                onRepeatSecondsChanged: (value) {
                  setState(() {
                    _secondaryRepeatSeconds = value;
                  });
                },
                amountMl: _secondaryAmountMl,
                onAmountChanged: (value) {
                  setState(() {
                    _secondaryAmountMl = value;
                  });
                },
                repeatCount: _secondaryRepeatCount,
                onRepeatCountChanged: (value) {
                  setState(() {
                    _secondaryRepeatCount = value;
                  });
                },
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
                onPressed: _save,
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

class _PeriodOption {
  final int seconds;
  final String label;

  const _PeriodOption({required this.seconds, required this.label});
}
