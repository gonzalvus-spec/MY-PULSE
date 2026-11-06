import 'package:flutter/material.dart';

import '../mongo_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final db = await MongoService.getDb();
      final doc = await db.collection('paciente').findOne();
      final paciente = doc == null
          ? null
          : <String, String>{
              'nombre': (doc['nombre'] ?? '').toString(),
              'dni': (doc['dni'] ?? '').toString(),
            };
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => paciente == null || paciente['nombre']!.isEmpty
              ? const PatientSetupScreen()
              : HomeScreen(paciente: paciente),
        ),
      );
    } catch (e) {
      debugPrint('Error inicializando MongoDB: $e');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientSetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, size: 72, color: Color(0xFF006689)),
          SizedBox(height: 20),
          Text(
            'Control de Presión',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}

class PatientSetupScreen extends StatefulWidget {
  const PatientSetupScreen({super.key});
  @override
  State<PatientSetupScreen> createState() => _PatientSetupScreenState();
}

class _PatientSetupScreenState extends State<PatientSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _dni = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _nombre.dispose();
    _dni.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = await MongoService.getDb();
      final col = db.collection('paciente');
      await col.deleteMany({});
      await col.insert({
        'nombre': _nombre.text.trim(),
        'dni': _dni.text.trim(),
        'creado': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            paciente: {'nombre': _nombre.text.trim(), 'dni': _dni.text.trim()},
          ),
        ),
      );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 76,
                    color: Color(0xFF006689),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bienvenido',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Ingresa tus datos para comenzar'),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nombre,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Ingresa tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dni,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'DNI / Documento',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Ingresa tu DNI' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Guardando...' : 'Comenzar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
