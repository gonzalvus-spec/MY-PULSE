import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

/// Servicio de conexión a MongoDB.
///
/// La cadena de conexión se lee de la variable `MONGO_URI` del archivo `.env`,
/// que no se versiona. Copia `.env.example` como `.env` y coloca tus datos.
class MongoService {
  MongoService._();

  static mongo.Db? _db;

  /// Nombre de la variable de entorno que contiene la URI de MongoDB.
  static const String _variableUri = 'MONGO_URI';

  static String get _uri {
    final uri = dotenv.isInitialized
        ? dotenv.maybeGet(_variableUri)?.trim()
        : null;

    if (uri == null || uri.isEmpty) {
      throw StateError(
        'Falta la variable $_variableUri en el archivo .env. '
        'Copia .env.example como .env y coloca tu cadena de conexión.',
      );
    }

    return uri;
  }

  static Future<mongo.Db> getDb() async {
    if (_db == null || !_db!.isConnected) {
      _db = await mongo.Db.create(_uri);
      await _db!.open();
    }
    return _db!;
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
