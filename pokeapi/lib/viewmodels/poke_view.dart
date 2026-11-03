import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/repositorio.dart';

class PokedexViewModel extends ChangeNotifier {
  PokedexViewModel(this._repo);

  final PokemonRepository _repo;
  static const pageSize = 20;

  List<PokemonSummary> _all = [];
  List<PokemonSummary> _filtered = [];
  final items = <PokemonCard>[];

  bool loading = false;
  bool ready = false; // índice cargado
  Object? error;
  int _epoch = 0;

  String query = '';
  String? type;
  int? generation;

  bool get hasMore => items.length < _filtered.length;
  bool get isEmpty => ready && !loading && error == null && _filtered.isEmpty;

  Future<void> init() async {
    error = null;
    notifyListeners();
    try {
      _all = await _repo.getIndex();
      ready = true;
      await _refilter();
    } catch (e) {
      error = e;
      notifyListeners();
    }
  }

  void setQuery(String v) { query = v; _refilter(); }
  void setType(String? v) { type = v; _refilter(); }
  void setGeneration(int? v) { generation = v; _refilter(); }

  Future<void> _refilter() async {
    final epoch = ++_epoch;
    try {
      final typeIds = type == null ? null : await _repo.idsByType(type!);
      final genIds = generation == null ? null : await _repo.idsByGeneration(generation!);
      if (epoch != _epoch) return;
      final q = query.trim().toLowerCase();
      _filtered = _all.where((p) {
        if (typeIds != null && !typeIds.contains(p.id)) return false;
        if (genIds != null && !genIds.contains(p.id)) return false;
        return q.isEmpty || p.name.contains(q) || p.id.toString() == q;
      }).toList();
      items.clear();
      error = null;
      notifyListeners();
      loadMore();
    } catch (e) {
      if (epoch == _epoch) {
        error = e;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    loading = true;
    error = null;
    notifyListeners();
    final epoch = _epoch;
    try {
      final batch = _filtered.skip(items.length).take(pageSize);
      final cards = await Future.wait(batch.map((p) => _repo.getCard(p.id)));
      if (epoch == _epoch) items.addAll(cards);
    } catch (e) {
      if (epoch == _epoch) error = e; // lo ya cargado se conserva
    }
    loading = false;
    notifyListeners();
    if (epoch != _epoch) loadMore(); // cambiaron los filtros durante la carga
  }
}
