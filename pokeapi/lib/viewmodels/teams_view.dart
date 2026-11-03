import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';

class TeamsViewModel extends ChangeNotifier {
  TeamsViewModel(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'teams';
  List<Team> teams = [];

  void load() {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      teams = [for (final j in jsonDecode(raw)) Team.fromJson(j)];
      notifyListeners();
    }
  }

  Future<void> _save() async {
    await _prefs.setString(_key, jsonEncode([for (final t in teams) t.toJson()]));
    notifyListeners();
  }

  Future<void> create(String name) {
    teams.add(Team(id: DateTime.now().microsecondsSinceEpoch.toString(), name: name));
    return _save();
  }

  Future<void> rename(Team t, String name) { t.name = name; return _save(); }
  Future<void> delete(Team t) { teams.remove(t); return _save(); }

  /// false si el equipo está lleno.
  Future<bool> addPokemon(Team t, int pokemonId) async {
    if (t.isFull) return false;
    t.pokemonIds.add(pokemonId);
    await _save();
    return true;
  }

  Future<void> removeAt(Team t, int index) {
    t.pokemonIds.removeAt(index);
    return _save();
  }
}
