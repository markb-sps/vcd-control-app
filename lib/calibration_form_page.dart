import 'package:flutter/material.dart';

class CalibrationFormPage extends StatefulWidget {
  final Future<void> Function(int slot, int dosageMl, int sprayTimeMs) onSubmit;
  final List<int> slotOptions;
  final int? initialSlot;
  final int? initialDosageMl;
  final int? initialSprayTimeMs;

  const CalibrationFormPage({
    super.key,
    required this.onSubmit,
    required this.slotOptions,
    this.initialSlot,
    this.initialDosageMl,
    this.initialSprayTimeMs,
  });

  @override
  State<CalibrationFormPage> createState() => _CalibrationFormPageState();
}

class _CalibrationFormPageState extends State<CalibrationFormPage> {
  late final TextEditingController _doseController;
  late final TextEditingController _timeController;
  int? _selectedSlot;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(
      text: widget.initialDosageMl?.toString() ?? '',
    );
    _timeController = TextEditingController(
      text: widget.initialSprayTimeMs?.toString() ?? '',
    );
    _selectedSlot = widget.initialSlot ??
        (widget.slotOptions.isNotEmpty ? widget.slotOptions.first : null);
  }

  @override
  void dispose() {
    _doseController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedSlot == null) {
      setState(() {
        _error = 'Select which entry slot to update.';
      });
      return;
    }
    final dosage = int.tryParse(_doseController.text.trim());
    final sprayTime = int.tryParse(_timeController.text.trim());
    if (dosage == null || dosage <= 0) {
      setState(() {
        _error = 'Enter a valid dose amount greater than 0.';
      });
      return;
    }
    if (sprayTime == null || sprayTime <= 0) {
      setState(() {
        _error = 'Enter a valid spray time (ms) greater than 0.';
      });
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit(_selectedSlot!, dosage, sprayTime);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to send calibration: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Calibration'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE082), Color(0xFFFFCA28)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedSlot,
                decoration: const InputDecoration(
                  labelText: 'Entry Slot',
                  border: OutlineInputBorder(),
                ),
                items: widget.slotOptions
                    .map(
                      (slot) => DropdownMenuItem(
                        value: slot,
                        child: Text('Slot ${slot + 1}'),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSlot = value;
                        });
                      },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _doseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dose Amount (ml)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Required Spray Time (ms)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.black,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Calibration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
