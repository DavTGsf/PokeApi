const _sprites =
    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon';

String spriteUrl(int id) => '$_sprites/$id.png';
String shinyUrl(int id) => '$_sprites/shiny/$id.png';
String artworkUrl(int id) => '$_sprites/other/official-artwork/$id.png';

const pokemonTypes = [
  'normal', 'fire', 'water', 'electric', 'grass', 'ice', 'fighting', 'poison',
  'ground', 'flying', 'psychic', 'bug', 'rock', 'ghost', 'dragon', 'dark',
  'steel', 'fairy',
];

int idFromUrl(String url) {
  final parts = url.split('/');
  return int.parse(parts[parts.length - 2]);
}

// Megas: "venusaur-mega", "charizard-mega-x". Primigenias: "kyogre-primal".
final _megaRe = RegExp(r'-(mega(-\w+)?|primal)$');

bool isMegaName(String name) => _megaRe.hasMatch(name);
String baseName(String name) => name.replaceFirst(_megaRe, '');

/// "Normal", "Mega", "Mega X", "Mega Y", "Primigenia".
String formLabel(String name) {
  final m = _megaRe.firstMatch(name);
  if (m == null) return 'Normal';
  if (m.group(1) == 'primal') return 'Primigenia';
  final suffix = m.group(2); // "-x"
  return suffix == null ? 'Mega' : 'Mega ${suffix.substring(1).toUpperCase()}';
}

class PokemonSummary {
  final int id;
  final String name;
  const PokemonSummary(this.id, this.name);
}

class PokemonCard {
  final int id;
  final String name;
  final List<String> types;
  const PokemonCard(this.id, this.name, this.types);

  bool get isMega => isMegaName(name);
}

class PokemonDetail {
  final int id;
  final int speciesId; // número nacional (distinto de id en las megas)
  final String name;
  final double heightM;
  final double weightKg;
  final List<String> types;
  final List<String> abilities;
  final Map<String, int> stats;
  final String? cryUrl;

  const PokemonDetail({
    required this.id,
    required this.speciesId,
    required this.name,
    required this.heightM,
    required this.weightKg,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.cryUrl,
  });

  bool get isMega => isMegaName(name);

  factory PokemonDetail.fromJson(Map<String, dynamic> j) => PokemonDetail(
        id: j['id'],
        speciesId: idFromUrl(j['species']['url']),
        name: j['name'],
        heightM: (j['height'] as int) / 10,
        weightKg: (j['weight'] as int) / 10,
        types: [for (final t in j['types']) t['type']['name'] as String],
        abilities: [for (final a in j['abilities']) a['ability']['name'] as String],
        stats: {
          for (final s in j['stats']) s['stat']['name'] as String: s['base_stat'] as int
        },
        cryUrl: (j['cries'] as Map?)?['latest'] as String?,
      );
}

/// Forma seleccionable de una especie (la normal o una mega).
class PokemonForm {
  final int id; // id de /pokemon
  final String name;
  const PokemonForm(this.id, this.name);

  bool get isMega => isMegaName(name);
}

class PokemonSpecies {
  final int id;
  final String description;
  final int genderRate; // -1 sin género; si no, octavos de probabilidad hembra
  final List<PokemonForm> forms; // [normal, ...megas]

  const PokemonSpecies({
    required this.id,
    required this.description,
    required this.genderRate,
    required this.forms,
  });

  double? get femalePct => genderRate < 0 ? null : genderRate / 8 * 100;
  bool get hasMega => forms.any((f) => f.isMega);

  factory PokemonSpecies.fromJson(Map<String, dynamic> j) {
    final entries = j['flavor_text_entries'] as List;
    String pick(String lang) {
      final list = entries.where((e) => e['language']['name'] == lang).toList();
      return list.isEmpty ? '' : list.last['flavor_text'] as String;
    }

    final text = pick('es').isNotEmpty ? pick('es') : pick('en');
    return PokemonSpecies(
      id: j['id'],
      description: text.replaceAll('\u00AD', '').replaceAll(RegExp(r'\s+'), ' ').trim(),
      genderRate: j['gender_rate'],
      forms: [
        for (final v in j['varieties'])
          if (v['is_default'] == true || isMegaName(v['pokemon']['name']))
            PokemonForm(idFromUrl(v['pokemon']['url']), v['pokemon']['name']),
      ],
    );
  }
}

class Team {
  final String id;
  String name;
  final List<int> pokemonIds; // máx. 6

  Team({required this.id, required this.name, List<int>? pokemonIds})
      : pokemonIds = pokemonIds ?? [];

  static const maxSize = 6;
  bool get isFull => pokemonIds.length >= maxSize;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ids': pokemonIds};
  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: j['id'],
        name: j['name'],
        pokemonIds: List<int>.from(j['ids']),
      );
}
