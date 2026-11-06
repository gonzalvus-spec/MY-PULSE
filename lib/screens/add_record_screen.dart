import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddRecordScreen extends StatefulWidget {
  final Map<String, dynamic>? existingReading;

  const AddRecordScreen({super.key, this.existingReading});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _sys = TextEditingController();
  final _dia = TextEditingController();
  final _pulse = TextEditingController();

  late DateTime _date;

  bool get _editing => widget.existingReading != null;

  @override
  void initState() {
    super.initState();

    final reading = widget.existingReading;

    _date = reading == null ? DateTime.now() : _parseDate(reading['fecha']);

    _sys.text = (reading?['sys'] ?? '').toString();
    _dia.text = (reading?['dia'] ?? '').toString();
    _pulse.text = (reading?['pulso'] ?? reading?['pulse'] ?? '').toString();
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }

    if (value is String) {
      for (final format in ['dd/MM/yyyy HH:mm', 'dd/MM/yyyy']) {
        try {
          return DateFormat(format).parseStrict(value);
        } catch (_) {}
      }

      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return DateTime.now();
  }

  @override
  void dispose() {
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();

    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );

    if (time != null && mounted) {
      setState(() {
        _date = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  String? _validateNumber(
    String? value,
    String label, {
    int min = 1,
    int max = 300,
  }) {
    final number = int.tryParse(value ?? '');

    if (number == null) {
      return 'Ingresa un valor numérico para $label';
    }

    if (number < min || number > max) {
      return 'El valor debe estar entre $min y $max';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar medición' : 'Nueva medición'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'Modifica las lecturas' : 'Ingresa las lecturas',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text('Completa los datos mostrados en tu tensiómetro.'),

                const SizedBox(height: 20),

                // Selector de fecha y hora
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          color: Color(0xFF006689),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            DateFormat('dd/MM/yyyy - hh:mm a').format(_date),
                          ),
                        ),

                        const Icon(Icons.edit_calendar),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Presión sistólica
                TextFormField(
                  controller: _sys,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Presión sistólica (SYS)',
                    suffixText: 'mmHg',
                    prefixIcon: Icon(Icons.arrow_upward),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateNumber(value, 'SYS', max: 300),
                ),

                const SizedBox(height: 16),

                // Presión diastólica
                TextFormField(
                  controller: _dia,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Presión diastólica (DIA)',
                    suffixText: 'mmHg',
                    prefixIcon: Icon(Icons.arrow_downward),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _validateNumber(value, 'DIA', max: 200),
                ),

                const SizedBox(height: 16),

                // Pulso cardíaco
                TextFormField(
                  controller: _pulse,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pulso cardíaco',
                    suffixText: 'bpm',
                    prefixIcon: Icon(Icons.favorite_border),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      _validateNumber(value, 'pulso', max: 250),
                ),

                const SizedBox(height: 28),

                // Botón para guardar o actualizar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'sys': int.parse(_sys.text),
                          'dia': int.parse(_dia.text),
                          'pulse': int.parse(_pulse.text),
                          'fecha': _date,
                        });
                      }
                    },
                    icon: Icon(_editing ? Icons.save : Icons.check_circle),
                    label: Text(
                      _editing ? 'Actualizar medición' : 'Guardar medición',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
