import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../viewmodels/teams_view.dart';
import 'widgets/poke_widgets.dart';

Future<String?> _askName(BuildContext context, [String initial = '']) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Nombre del equipo'),
      content: TextField(controller: c, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Guardar')),
      ],
    ),
  );
}

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TeamsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Equipos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _askName(context);
          if (name != null && name.isNotEmpty) vm.create(name);
        },
        child: const Icon(Icons.add),
      ),
      body: vm.teams.isEmpty
          ? const Center(child: Text('Aún no tienes equipos'))
          : ListView(children: [
              for (final t in vm.teams)
                ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.pokemonIds.length}/${Team.maxSize}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final id in t.pokemonIds.take(6))
                      CachedNetworkImage(imageUrl: spriteUrl(id), width: 28),
                  ]),
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => TeamDetailPage(team: t))),
                ),
            ]),
    );
  }
}

class TeamDetailPage extends StatelessWidget {
  const TeamDetailPage({super.key, required this.team});
  final Team team;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TeamsViewModel>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _askName(context);
          if (name != null && name.isNotEmpty) vm.create(name);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        const PokedexHeader(title: 'EQUIPOS'),
        Expanded(
          child: vm.teams.isEmpty
              ? const Center(child: Text('Aún no tienes equipos'))
              : ListView(children: [ /* ...tu lista actual, sin cambios... */ ]),
        ),
      ]),
    );
  }
}
