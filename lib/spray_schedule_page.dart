import 'package:flutter/material.dart';

class SpraySchedulePage extends StatefulWidget {
  const SpraySchedulePage({super.key});

  @override
  State<SpraySchedulePage> createState() => _SpraySchedulePageState();
}

class _SpraySchedulePageState extends State<SpraySchedulePage> {
  TimeOfDay _startTime = TimeOfDay.now();
  int _repeatMinutes = 60;

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
      'repeatMinutes': _repeatMinutes,
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
                  value: _repeatMinutes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _repeatMinutes = value;
                      });
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                    DropdownMenuItem(value: 120, child: Text('2 hours')),
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
