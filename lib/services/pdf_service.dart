import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static DateTime parseDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is int)
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    if (value is String) {
      for (final format in ['dd/MM/yyyy HH:mm', 'dd/MM/yyyy']) {
        try {
          return DateFormat(format).parseStrict(value);
        } catch (_) {}
      }
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.now();
  }

  static int _int(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

  static Future<void> generate({
    required List<Map<String, dynamic>> readings,
    required Map<String, String> patient,
    required DateTime from,
    required DateTime to,
  }) async {
    final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final filtered =
        readings.where((r) {
          final date = parseDate(r['fecha']);
          return !date.isBefore(DateTime(from.year, from.month, from.day)) &&
              !date.isAfter(endOfDay);
        }).toList()..sort(
          (a, b) => parseDate(a['fecha']).compareTo(parseDate(b['fecha'])),
        );
    if (filtered.isEmpty)
      throw Exception('No hay mediciones en ese rango de fechas.');

    final generatedAt = DateTime.now();
    final pdf = pw.Document();
    final primary = PdfColor.fromInt(0xFF006689);
    final light = PdfColor.fromInt(0xFFEAF4F7);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 32, 34, 48),
        header: (context) {
          if (context.pageNumber != 1) return pw.SizedBox(height: 8);
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: primary,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 42,
                      height: 42,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(21),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'IC',
                          style: pw.TextStyle(
                            color: primary,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'REPORTE DE PRESIÓN ARTERIAL',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 17,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Historial de mediciones del paciente',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: light,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DATOS DEL PACIENTE',
                            style: pw.TextStyle(
                              color: primary,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            patient['nombre'] ?? 'Sin nombre',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'DNI: ${patient['dni'] ?? 'No registrado'}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PERÍODO DEL INFORME',
                            style: pw.TextStyle(
                              color: primary,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '${DateFormat('dd/MM/yyyy').format(from)} - ${DateFormat('dd/MM/yyyy').format(to)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Total de mediciones: ${filtered.length}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
            ],
          );
        },
        footer: (context) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Divider(color: PdfColors.grey400, thickness: 0.6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Control de Presión Arterial - Generado ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            'DETALLE DE MEDICIONES',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: primary,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: const [
              'Fecha',
              'Hora',
              'Sistólica',
              'Diastólica',
              'Pulso',
            ],
            // headerCount: 0 hace que la cabecera se dibuje una sola vez y no se repita
            // automáticamente en las páginas posteriores.
            headerCount: 0,
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: primary),
            cellStyle: const pw.TextStyle(fontSize: 8),
            oddRowDecoration: pw.BoxDecoration(color: light),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.4),
              ),
            ),
            cellAlignment: pw.Alignment.center,
            cellPadding: const pw.EdgeInsets.symmetric(
              vertical: 7,
              horizontal: 5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.2),
              1: const pw.FlexColumnWidth(1.0),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(0.8),
            },
            data: filtered.map((r) {
              final date = parseDate(r['fecha']);
              return [
                DateFormat('dd/MM/yyyy').format(date),
                DateFormat('hh:mm a').format(date),
                '${_int(r['sys'])} mmHg',
                '${_int(r['dia'])} mmHg',
                '${_int(r['pulso'] ?? r['pulse'])} bpm',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'Nota: este documento registra las mediciones ingresadas en la aplicación. No sustituye la evaluación ni el diagnóstico de un profesional de salud.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }
}
