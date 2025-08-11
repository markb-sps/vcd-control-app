import 'package:flutter/material.dart';

class SpraySchedulePage extends StatefulWidget {
  const SpraySchedulePage({super.key});

  @override
  State<SpraySchedulePage> createState() => _SpraySchedulePageState();
}

class _SpraySchedulePageState extends State<SpraySchedulePage> {
  TimeOfDay _startTime = TimeOfDay.now();
  int _repeatSeconds = 60;
  int _amountMl = 5;

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
    Navigator.of(context).pop({
      'start': _startTime,
      'repeatSeconds': _repeatSeconds,
      'amountMl': _amountMl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spray Schedule'),
      ),
      body: Padding(
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Amount:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _amountMl,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _amountMl = value;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 ml')),
                    DropdownMenuItem(value: 10, child: Text('10 ml')),
                    DropdownMenuItem(value: 15, child: Text('15 ml')),
                    DropdownMenuItem(value: 20, child: Text('20 ml')),
                    DropdownMenuItem(value: 25, child: Text('25 ml')),
                    DropdownMenuItem(value: 30, child: Text('30 ml')),
                    DropdownMenuItem(value: 50, child: Text('50 ml')),
                    DropdownMenuItem(value: 100, child: Text('100 ml')),
                  ],
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
