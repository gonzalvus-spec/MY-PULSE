import 'package:flutter_test/flutter_test.dart';
import 'package:presion_arterial_app/services/pdf_service.dart';

void main() {
  group('PdfService.parseDate', () {
    test('interpreta el formato guardado por la app (dd/MM/yyyy HH:mm)', () {
      final fecha = PdfService.parseDate('15/10/2026 14:30');

      expect(fecha, DateTime(2026, 10, 15, 14, 30));
    });

    test('interpreta una fecha sin hora (dd/MM/yyyy)', () {
      final fecha = PdfService.parseDate('15/10/2026');

      expect(fecha, DateTime(2026, 10, 15));
    });

    test('interpreta fechas ISO 8601', () {
      final fecha = PdfService.parseDate('2026-10-15T14:30:00.000Z');

      expect(fecha.toUtc(), DateTime.utc(2026, 10, 15, 14, 30));
    });

    test('usa la fecha actual cuando el valor no es válido', () {
      final antes = DateTime.now();
      final fecha = PdfService.parseDate('no-es-una-fecha');
      final despues = DateTime.now();

      expect(fecha.isBefore(antes), isFalse);
      expect(fecha.isAfter(despues), isFalse);
    });
  });
}
