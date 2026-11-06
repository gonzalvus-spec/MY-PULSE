import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../mongo_service.dart';
import '../services/pdf_service.dart';
import 'add_record_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, String> paciente;

  const HomeScreen({super.key, required this.paciente});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================

  late Map<String, String> _patient;

  List<Map<String, dynamic>> _readings = [];

  bool _loading = true;
  String? _error;

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================

  @override
  void initState() {
    super.initState();

    _patient = Map<String, String>.from(widget.paciente);

    _fetch();
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  int _number(dynamic value) {
    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _date(dynamic value) {
    return PdfService.parseDate(value);
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // CARGAR HISTORIAL DESDE MONGODB
  // ============================================================

  Future<void> _fetch() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final db = await MongoService.getDb();

      final docs = await db.collection('mediciones').find().toList();

      final rows =
          docs.map((doc) {
              final row = Map<String, dynamic>.from(doc);
              final id = row['_id'];

              if (id is mongo.ObjectId) {
                row['_id'] = id.toHexString();
              }

              return row;
            }).toList()
            ..sort((a, b) => _date(b['fecha']).compareTo(_date(a['fecha'])));

      if (!mounted) return;

      setState(() {
        _readings = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar las mediciones: $e';
        _loading = false;
      });
    }
  }

  // ============================================================
  // AGREGAR MEDICIÓN
  // ============================================================

  Future<void> _add(Map<String, dynamic> data) async {
    try {
      final db = await MongoService.getDb();

      await db.collection('mediciones').insert({
        '_id': mongo.ObjectId(),
        'sys': data['sys'].toString(),
        'dia': data['dia'].toString(),
        'pulso': data['pulse'].toString(),
        'fecha': DateFormat('dd/MM/yyyy HH:mm')
            .format(data['fecha'] as DateTime),
      });

      await _fetch();

      if (mounted) {
        _message('Medición guardada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _message('Error al guardar: $e', error: true);
      }
    }
  }

  // ============================================================
  // EDITAR MEDICIÓN
  // ============================================================

  Future<void> _edit(Map<String, dynamic> row) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => AddRecordScreen(existingReading: row)),
    );

    if (result == null || !mounted) return;

    try {
      final id = mongo.ObjectId.fromHexString(row['_id'].toString());

      final db = await MongoService.getDb();

      await db
          .collection('mediciones')
          .updateOne(
            {'_id': id},
            {
              '\$set': {
                'sys': result['sys'].toString(),
                'dia': result['dia'].toString(),
                'pulso': result['pulse'].toString(),
                'fecha': DateFormat('dd/MM/yyyy HH:mm')
                    .format(result['fecha'] as DateTime),
              },
            },
          );

      await _fetch();

      if (mounted) {
        _message('Medición actualizada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _message('Error al actualizar: $e', error: true);
      }
    }
  }

  // ============================================================
  // ELIMINAR MEDICIÓN
  // ============================================================

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text(
          '¿Seguro que deseas eliminar esta medición? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final db = await MongoService.getDb();

      await db.collection('mediciones').deleteOne({
        '_id': mongo.ObjectId.fromHexString(row['_id'].toString()),
      });

      await _fetch();

      if (mounted) {
        _message('Registro eliminado');
      }
    } catch (e) {
      if (mounted) {
        _message('Error al eliminar: $e', error: true);
      }
    }
  }

  // ============================================================
  // ESTADO DE LA PRESIÓN ARTERIAL
  // ============================================================

  Color _statusColor(int sys, int dia) {
    if (sys < 120 && dia < 80) {
      return Colors.green.shade700;
    }

    if (sys <= 129 && dia < 80) {
      return Colors.amber.shade800;
    }

    if (sys <= 139 || dia <= 89) {
      return Colors.orange.shade800;
    }

    return Colors.red.shade700;
  }

  String _status(int sys, int dia) {
    if (sys < 120 && dia < 80) {
      return 'Normal';
    }

    if (sys <= 129 && dia < 80) {
      return 'Elevada';
    }

    if (sys <= 139 || dia <= 89) {
      return 'Alta';
    }

    return 'Muy alta';
  }

  // ============================================================
  // ETIQUETAS DE FECHA
  // ============================================================

  String _dayLabel(DateTime date) {
    final now = DateTime.now();

    final day = DateTime(date.year, date.month, date.day);

    final today = DateTime(now.year, now.month, now.day);

    if (day == today) {
      return 'Hoy';
    }

    if (day == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    }

    return DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(date);
  }

  // ============================================================
  // EDITAR DATOS DEL PACIENTE
  // ============================================================

  Future<void> _editPatient() async {
    final name = TextEditingController(text: _patient['nombre']);

    final dni = TextEditingController(text: _patient['dni']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dni,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'DNI'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true || name.text.trim().isEmpty) {
      name.dispose();
      dni.dispose();
      return;
    }

    try {
      final db = await MongoService.getDb();

      await db.collection('paciente').deleteMany({});

      await db.collection('paciente').insert({
        'nombre': name.text.trim(),
        'dni': dni.text.trim(),
        'actualizado': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _patient = {'nombre': name.text.trim(), 'dni': dni.text.trim()};
        });
      }
    } catch (e) {
      if (mounted) {
        _message('Error al actualizar paciente: $e', error: true);
      }
    }

    name.dispose();
    dni.dispose();
  }

  // ============================================================
  // EXPORTAR HISTORIAL A PDF
  // ============================================================

  Future<void> _exportPdf() async {
    if (_readings.isEmpty) {
      _message('No hay mediciones para exportar', error: true);
      return;
    }

    final dates = _readings.map((r) => _date(r['fecha'])).toList()..sort();

    DateTime from = DateTime(
      dates.first.year,
      dates.first.month,
      dates.first.day,
    );

    DateTime to = DateTime(dates.last.year, dates.last.month, dates.last.day);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Exportar PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Desde'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(from)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: from,
                    firstDate: DateTime(2020),
                    lastDate: to,
                    initialDatePickerMode: DatePickerMode.day,
                    helpText: 'Selecciona la fecha inicial',
                  );

                  if (d != null) {
                    setDialog(() => from = d);
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Hasta'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(to)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: to,
                    firstDate: from,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDatePickerMode: DatePickerMode.day,
                    helpText: 'Selecciona la fecha final',
                  );

                  if (d != null) {
                    setDialog(() => to = d);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    if (from.isAfter(to)) {
      _message(
        'La fecha inicial no puede ser posterior a la fecha final.',
        error: true,
      );
      return;
    }

    try {
      await PdfService.generate(
        readings: _readings,
        patient: _patient,
        from: from,
        to: to,
      );
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  // ============================================================
  // CONSTRUIR ELEMENTOS DEL HISTORIAL
  // ============================================================

  List<Map<String, dynamic>> _buildHistoryItems() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final reading in _readings) {
      final date = _date(reading['fecha']);

      final key = DateFormat('yyyy-MM-dd').format(date);

      (grouped[key] ??= <Map<String, dynamic>>[]).add(reading);
    }

    final items = <Map<String, dynamic>>[];

    for (final entry in grouped.entries) {
      items.add({'type': 'day', 'date': entry.key});

      for (final reading in entry.value) {
        items.add({'type': 'reading', 'reading': reading});
      }
    }

    return items;
  }

  // ============================================================
  // WIDGET: CABECERA DEL PACIENTE
  // ============================================================

  Widget _patientHeader() {
    final initials = (_patient['nombre'] ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006689), Color(0xFF00A0C6)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient['nombre'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'DNI: ${_patient['dni'] ?? ''}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _editPatient,
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Editar paciente',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: TÍTULO DEL HISTORIAL
  // ============================================================

  Widget _historyTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Historial de mediciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${_readings.length} en total',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: HISTORIAL VACÍO
  // ============================================================

  Widget _emptyHistory() {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('No hay mediciones registradas'),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: TARJETA DE UNA MEDICIÓN
  // ============================================================

  Widget _readingCard(Map<String, dynamic> r) {
    final sys = _number(r['sys']);
    final dia = _number(r['dia']);
    final pulse = _number(r['pulso'] ?? r['pulse']);
    final date = _date(r['fecha']);
    final color = _statusColor(sys, dia);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _edit(r),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.favorite, color: color, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$sys / $dia',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'mmHg',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _status(sys, dia),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '$pulse bpm',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') {
                          _edit(r);
                        } else if (value == 'delete') {
                          _delete(r);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                      icon: const Icon(Icons.more_vert, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INTERFAZ PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final historyItems = _buildHistoryItems();

    final itemCount = 2 + (historyItems.isEmpty ? 1 : historyItems.length);

    return Scaffold(
      // --------------------------------------------------------
      // BARRA SUPERIOR
      // --------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Aplicación de Presión',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: _fetch,
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
          ),
          IconButton.filledTonal(
            onPressed: _exportPdf,
            tooltip: 'Exportar PDF',
            icon: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // --------------------------------------------------------
      // CONTENIDO PRINCIPAL
      // --------------------------------------------------------
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Colors.red,
                    ),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _fetch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: itemCount,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                cacheExtent: 500,
                itemBuilder: (context, index) {
                  // Cabecera del paciente.
                  if (index == 0) {
                    return _patientHeader();
                  }

                  // Título del historial.
                  if (index == 1) {
                    return _historyTitle();
                  }

                  // Historial vacío.
                  if (historyItems.isEmpty) {
                    return _emptyHistory();
                  }

                  final item = historyItems[index - 2];

                  // Separador por día.
                  if (item['type'] == 'day') {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(
                        _dayLabel(DateTime.parse(item['date'] as String)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }

                  // Tarjeta de medición.
                  return _readingCard(item['reading'] as Map<String, dynamic>);
                },
              ),
            ),

      // --------------------------------------------------------
      // BOTÓN PARA AGREGAR UNA MEDICIÓN
      // --------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const AddRecordScreen()),
          );

          if (result != null) {
            await _add(result);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva lectura'),
      ),
    );
  }
}
