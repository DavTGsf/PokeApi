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
}

class PokemonDetail {
  final int id;
  final String name;
  final double heightM;
  final double weightKg;
  final List<String> types;
  final List<String> abilities;
  final Map<String, int> stats;
  final String? cryUrl;

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.heightM,
    required this.weightKg,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.cryUrl,
  });

  factory PokemonDetail.fromJson(Map<String, dynamic> j) => PokemonDetail(
        id: j['id'],
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
