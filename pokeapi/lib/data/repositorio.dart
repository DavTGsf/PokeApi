import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

int _idFromUrl(String url) {
  final parts = url.split('/');
  return int.parse(parts[parts.length - 2]);
}

// Top-level para poder correr en un isolate con compute().
List<PokemonSummary> parseIndex(String body) {
  final results = jsonDecode(body)['results'] as List;
  return [
    for (final e in results)
      if (_idFromUrl(e['url']) < 10000) // excluye formas alternativas
        PokemonSummary(_idFromUrl(e['url']), e['name'])
  ];
}

class PokemonRepository {
  PokemonRepository(this._prefs);

  static const _base = 'https://pokeapi.co/api/v2';
  final SharedPreferences _prefs;

  final _json = <String, dynamic>{}; // cache en memoria por path
  final _typeIds = <String, Set<int>>{};
  final _genIds = <int, Set<int>>{};

  Future<dynamic> _get(String path) async {
    if (_json.containsKey(path)) return _json[path];
    final res = await http
        .get(Uri.parse('$_base$path'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return _json[path] = jsonDecode(res.body);
  }

  /// Índice completo (id + nombre). Red solo la primera vez.
  Future<List<PokemonSummary>> getIndex() async {
    final cached = _prefs.getStringList('index');
    if (cached != null) {
      return [
        for (final s in cached)
          PokemonSummary(int.parse(s.split(',')[0]), s.split(',')[1])
      ];
    }
    final res = await http
        .get(Uri.parse('$_base/pokemon?limit=100000'))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final list = await compute(parseIndex, res.body);
    await _prefs.setStringList('index', [for (final p in list) '${p.id},${p.name}']);
    return list;
  }

  Future<PokemonCard> getCard(int id) async {
    final j = await _get('/pokemon/$id');
    return PokemonCard(id, j['name'],
        [for (final t in j['types']) t['type']['name'] as String]);
  }

  Future<PokemonDetail> getDetail(int id) async =>
      PokemonDetail.fromJson(await _get('/pokemon/$id'));

  Future<Set<int>> idsByType(String type) async {
    if (_typeIds.containsKey(type)) return _typeIds[type]!;
    final j = await _get('/type/$type');
    return _typeIds[type] = {
      for (final p in j['pokemon']) _idFromUrl(p['pokemon']['url'])
    };
  }

  Future<Set<int>> idsByGeneration(int gen) async {
    if (_genIds.containsKey(gen)) return _genIds[gen]!;
    final j = await _get('/generation/$gen');
    return _genIds[gen] = {
      for (final s in j['pokemon_species']) _idFromUrl(s['url'])
    };
  }

  /// Cadena evolutiva aplanada (en orden). Pierde la forma de ramas.
  Future<List<PokemonSummary>> getEvolution(int id) async {
    final species = await _get('/pokemon-species/$id');
    final chainUrl = species['evolution_chain']['url'] as String;
    final chain = await _get(chainUrl.replaceFirst(_base, ''));
    final out = <PokemonSummary>[];
    void walk(Map<String, dynamic> node) {
      final s = node['species'];
      out.add(PokemonSummary(_idFromUrl(s['url']), s['name']));
      for (final next in node['evolves_to']) {
        walk(next);
      }
    }
    walk(chain['chain']);
    return out;
  }
}
