import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/repositorio.dart';

class PokedexViewModel extends ChangeNotifier {
  PokedexViewModel(this._repo);

  final PokemonRepository _repo;
  static const pageSize = 20;

  List<PokemonSummary> _all = [];   // especies (id < 10000)
  List<PokemonSummary> _megas = []; // megaevoluciones y primigenias
  Map<String, int> _idByName = {};
  List<PokemonSummary> _filtered = [];
  final items = <PokemonCard>[];

  bool loading = false;
  bool ready = false; // índice cargado
  Object? error;
  int _epoch = 0;

  String query = '';
  String? type;
  int? generation;
  bool megaOnly = false;

  bool get hasMore => items.length < _filtered.length;
  bool get isEmpty => ready && !loading && error == null && _filtered.isEmpty;

  Future<void> init() async {
    error = null;
    notifyListeners();
    try {
      final index = await _repo.getIndex();
      _all = [for (final p in index) if (p.id < 10000) p];
      _megas = [for (final p in index) if (p.id >= 10000) p];
      _idByName = {for (final p in _all) p.name: p.id};
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
  void setMegaOnly(bool v) { megaOnly = v; _refilter(); }

  /// Número nacional; para una mega se deduce del nombre base.
  int? _speciesOf(PokemonSummary p) =>
      p.id < 10000 ? p.id : _idByName[baseName(p.name)];

  Future<void> _refilter() async {
    final epoch = ++_epoch;
    try {
      final typeIds = type == null ? null : await _repo.idsByType(type!);
      final genIds = generation == null ? null : await _repo.idsByGeneration(generation!);
      if (epoch != _epoch) return;
      final q = query.trim().toLowerCase();
      final source = megaOnly ? _megas : _all;
      _filtered = source.where((p) {
        final sid = _speciesOf(p);
        if (typeIds != null && !typeIds.contains(p.id)) return false;
        if (genIds != null && !genIds.contains(sid)) return false;
        return q.isEmpty || p.name.contains(q) || sid.toString() == q;
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
