import 'package:flutter/foundation.dart';

import '../models/modelos_ficha/ficha.dart';
import '../services/ficha_service.dart';

/// Provider que expone el listado de fichas y maneja su estado de carga.
class FichaProvider extends ChangeNotifier {
  FichaProvider({FichaService? service})
    : _service = service ?? const FichaService();

  final FichaService _service;

  final List<Ficha> _fichas = <Ficha>[];
  bool _loading = false;
  String? _error;

  List<Ficha> get fichas => List.unmodifiable(_fichas);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadFichas() async {
    if (_loading) return;
    _setLoading(true);
    try {
      final results = await _service.fetchFichas();
      _fichas
        ..clear()
        ..addAll(results);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _fichas.clear();
    await loadFichas();
  }

  Ficha? findById(int id) {
    try {
      return _fichas.firstWhere((ficha) => ficha.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
