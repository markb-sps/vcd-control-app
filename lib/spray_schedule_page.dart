import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SpraySchedulePage extends StatefulWidget {
  final List<int> allowedAmounts;
  final SprayScheduleInitialData? initialData;

  const SpraySchedulePage({
    super.key,
    required this.allowedAmounts,
    this.initialData,
  });

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
    _PeriodOption(seconds: 28800, label: '8 hours'),
    _PeriodOption(seconds: 43200, label: '12 hours'),
    _PeriodOption(seconds: 86400, label: '24 hours'),
  ];
  static const String _savedConfigFileName = 'spray_schedule_saved_config.json';

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _startTime = TimeOfDay.fromDateTime(_startDate);
    final Set<int> amountSet = widget.allowedAmounts.toSet();
    final SprayScheduleInitialData? initial = widget.initialData;
    if (initial != null) {
      if (initial.initialAmountMl > 0) {
        amountSet.add(initial.initialAmountMl);
      }
      if (initial.secondaryAmountMl > 0) {
        amountSet.add(initial.secondaryAmountMl);
      }
    }
    _amountOptions = amountSet.toList()..sort();
    if (_amountOptions.isNotEmpty) {
      _initialAmountMl = _amountOptions.first;
    }
    if (initial != null) {
      final DateTime localStart = initial.start.toLocal();
      _startOnWake = initial.startOnWake;
      _startDate = DateTime(localStart.year, localStart.month, localStart.day);
      _startTime = TimeOfDay.fromDateTime(localStart);
      _initialRepeatSeconds =
          _coerceRepeat(initial.initialRepeatSeconds, _initialRepeatSeconds);
      _secondaryRepeatSeconds =
          _coerceRepeat(initial.secondaryRepeatSeconds, _secondaryRepeatSeconds);
      _initialRepeatCount =
          _coerceRepeatCount(initial.initialRepeatCount, _initialRepeatCount);
      _secondaryRepeatCount =
          _coerceRepeatCount(initial.secondaryRepeatCount, _secondaryRepeatCount);
      _initialAmountMl = _coerceAmount(initial.initialAmountMl, _initialAmountMl);
      _secondaryAmountMl =
          _coerceAmount(initial.secondaryAmountMl, _secondaryAmountMl);
    }
  }

  Future<void> _pickStartDate() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime initialDate = _startDate.isBefore(today) ? today : _startDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 5)),
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

  int _coerceAmount(dynamic value, int fallback) {
    final int? candidate = switch (value) {
      int v => v,
      String v => int.tryParse(v),
      _ => null,
    };
    if (candidate == null) {
      return fallback;
    }
    if (candidate == 0 || _amountOptions.contains(candidate)) {
      return candidate;
    }
    return fallback;
  }

  int _coerceRepeat(dynamic value, int fallback) {
    final int? candidate = switch (value) {
      int v => v,
      String v => int.tryParse(v),
      _ => null,
    };
    if (candidate == null) {
      return fallback;
    }
    return _periodOptions.any((option) => option.seconds == candidate)
        ? candidate
        : fallback;
  }

  int _coerceRepeatCount(dynamic value, int fallback) {
    final int? candidate = switch (value) {
      int v => v,
      String v => int.tryParse(v),
      _ => null,
    };
    if (candidate == null) {
      return fallback;
    }
    return _repeatCountOptions.contains(candidate) ? candidate : fallback;
  }

  Future<File> _savedConfigFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_savedConfigFileName');
  }

  Map<String, dynamic> _currentStateAsJson() {
    return {
      'startOnWake': _startOnWake,
      'startDateYear': _startDate.year,
      'startDateMonth': _startDate.month,
      'startDateDay': _startDate.day,
      'startTimeHour': _startTime.hour,
      'startTimeMinute': _startTime.minute,
      'initialRepeatSeconds': _initialRepeatSeconds,
      'secondaryRepeatSeconds': _secondaryRepeatSeconds,
      'initialRepeatCount': _initialRepeatCount,
      'secondaryRepeatCount': _secondaryRepeatCount,
      'initialAmountMl': _initialAmountMl,
      'secondaryAmountMl': _secondaryAmountMl,
    };
  }

  Future<void> _saveConfigSnapshot() async {
    final File file = await _savedConfigFile();
    await file.writeAsString(jsonEncode(_currentStateAsJson()), flush: true);
  }

  Future<void> _restoreConfigSnapshot() async {
    try {
      final File file = await _savedConfigFile();
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No saved schedule configuration found.')),
          );
        }
        return;
      }

      final String content = await file.readAsString();
      final dynamic parsed = jsonDecode(content);
      if (parsed is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved schedule configuration format');
      }

      setState(() {
        final bool restoredStartOnWake = parsed['startOnWake'] == true;
        final int year = (parsed['startDateYear'] as num?)?.toInt() ?? _startDate.year;
        final int month = (parsed['startDateMonth'] as num?)?.toInt() ?? _startDate.month;
        final int day = (parsed['startDateDay'] as num?)?.toInt() ?? _startDate.day;
        _startDate = DateTime(year, month, day);

        final int hour = (parsed['startTimeHour'] as num?)?.toInt() ?? _startTime.hour;
        final int minute =
            (parsed['startTimeMinute'] as num?)?.toInt() ?? _startTime.minute;
        _startTime = TimeOfDay(
          hour: hour.clamp(0, 23).toInt(),
          minute: minute.clamp(0, 59).toInt(),
        );

        _startOnWake = restoredStartOnWake;
        _initialRepeatSeconds =
            _coerceRepeat(parsed['initialRepeatSeconds'], _initialRepeatSeconds);
        _secondaryRepeatSeconds =
            _coerceRepeat(parsed['secondaryRepeatSeconds'], _secondaryRepeatSeconds);
        _initialRepeatCount =
            _coerceRepeatCount(parsed['initialRepeatCount'], _initialRepeatCount);
        _secondaryRepeatCount =
            _coerceRepeatCount(parsed['secondaryRepeatCount'], _secondaryRepeatCount);
        _initialAmountMl = _coerceAmount(parsed['initialAmountMl'], _initialAmountMl);
        _secondaryAmountMl = _coerceAmount(parsed['secondaryAmountMl'], _secondaryAmountMl);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule configuration restored.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to restore saved configuration.')),
        );
      }
    }
  }

  Future<void> _saveConfigOnly() async {
    try {
      await _saveConfigSnapshot();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save schedule configuration.')),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule configuration saved.')),
      );
    }
  }

  void _writeToVcd() {
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
    final double bottomActionInset = MediaQuery.of(context).size.height * 0.05;
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
              SafeArea(
                top: false,
                minimum: EdgeInsets.only(bottom: bottomActionInset),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _writeToVcd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Write to VCD'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _restoreConfigSnapshot,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade300,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Restore From File'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveConfigOnly,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Save To File'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

class SprayScheduleInitialData {
  final DateTime start;
  final bool startOnWake;
  final int initialRepeatSeconds;
  final int initialRepeatCount;
  final int initialAmountMl;
  final int secondaryRepeatSeconds;
  final int secondaryRepeatCount;
  final int secondaryAmountMl;

  const SprayScheduleInitialData({
    required this.start,
    required this.startOnWake,
    required this.initialRepeatSeconds,
    required this.initialRepeatCount,
    required this.initialAmountMl,
    required this.secondaryRepeatSeconds,
    required this.secondaryRepeatCount,
    required this.secondaryAmountMl,
  });
}
