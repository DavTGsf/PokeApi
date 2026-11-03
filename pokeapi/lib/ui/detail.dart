import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/repositorio.dart';
import '../viewmodels/teams_view.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.id});
  final int id;
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<PokemonDetail> _future;
  final _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<PokemonRepository>().getDetail(widget.id);

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _addToTeam(PokemonDetail d) async {
    final vm = context.read<TeamsViewModel>();
    if (vm.teams.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Primero crea un equipo')));
      return;
    }
    final team = await showModalBottomSheet<Team>(
      context: context,
      builder: (_) => ListView(children: [
        for (final t in vm.teams)
          ListTile(
            title: Text(t.name),
            subtitle: Text('${t.pokemonIds.length}/${Team.maxSize}'),
            enabled: !t.isFull,
            onTap: () => Navigator.pop(context, t),
          ),
      ]),
    );
    if (team == null) return;
    final ok = await vm.addPokemon(team, d.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Agregado a ${team.name}' : 'Equipo lleno')));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<PokemonDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: FilledButton(
                    onPressed: () => setState(_load), child: const Text('Reintentar')),
              ),
            );
          }
          if (!snap.hasData) {
            return Scaffold(
                appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
          }
          final d = snap.data!;
          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text('#${d.id} ${d.name}'),
                bottom: const TabBar(tabs: [
                  Tab(text: 'Acerca de'),
                  Tab(text: 'Stats'),
                  Tab(text: 'Evolución'),
                ]),
              ),
              floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
                FloatingActionButton.small(
                  heroTag: 'sound',
                  onPressed: d.cryUrl == null
                      ? null
                      : () => _player.play(UrlSource(d.cryUrl!)),
                  child: const Icon(Icons.volume_up),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () => _addToTeam(d),
                  child: const Icon(Icons.group_add),
                ),
              ]),
              body: TabBarView(children: [
                _About(d),
                _Stats(d),
                _Evolution(d.id),
              ]),
            ),
          );
        },
      );
}

class _About extends StatelessWidget {
  const _About(this.d);
  final PokemonDetail d;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        Hero(
          tag: 'poke-${d.id}',
          child: CachedNetworkImage(
            imageUrl: artworkUrl(d.id),
            height: 240,
            placeholder: (_, __) => CachedNetworkImage(imageUrl: spriteUrl(d.id), height: 240),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CachedNetworkImage(imageUrl: spriteUrl(d.id), height: 64),
          CachedNetworkImage(imageUrl: shinyUrl(d.id), height: 64),
        ]),
        const SizedBox(height: 16),
        Text('Tipos: ${d.types.join(', ')}'),
        Text('Altura: ${d.heightM} m'),
        Text('Peso: ${d.weightKg} kg'),
        Text('Habilidades: ${d.abilities.join(', ')}'),
      ]);
}

class _Stats extends StatelessWidget {
  const _Stats(this.d);
  final PokemonDetail d;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
        for (final e in d.stats.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              SizedBox(width: 130, child: Text(e.key)),
              SizedBox(width: 40, child: Text('${e.value}')),
              Expanded(child: LinearProgressIndicator(value: (e.value / 255).clamp(0, 1))),
            ]),
          ),
      ]);
}

class _Evolution extends StatelessWidget {
  const _Evolution(this.id);
  final int id;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PokemonSummary>>(
        future: context.read<PokemonRepository>().getEvolution(id),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('No se pudo cargar'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final chain = snap.data!;
          if (chain.length == 1) return const Center(child: Text('Sin evoluciones'));
          return ListView(children: [
            for (final p in chain)
              ListTile(
                leading: CachedNetworkImage(imageUrl: spriteUrl(p.id), width: 56),
                title: Text(p.name),
                subtitle: Text('#${p.id}'),
                selected: p.id == id,
                onTap: p.id == id
                    ? null
                    : () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DetailPage(id: p.id))),
              ),
          ]);
        },
      );
}
