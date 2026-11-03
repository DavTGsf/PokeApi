import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../viewmodels/poke_view.dart';
import 'detail.dart';

class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key});
  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels >= p.maxScrollExtent * 0.75) {
        context.read<PokedexViewModel>().loadMore(); // precarga al 75 %
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => context.read<PokedexViewModel>().setQuery(v));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PokedexViewModel>();

    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar por nombre o número',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: _onSearch,
          ),
        ),
        Row(children: [
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String?>(
              isExpanded: true,
              hint: const Text('Tipo'),
              value: vm.type,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los tipos')),
                for (final t in pokemonTypes) DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: vm.setType,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int?>(
              isExpanded: true,
              hint: const Text('Generación'),
              value: vm.generation,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (var g = 1; g <= 9; g++)
                  DropdownMenuItem(value: g, child: Text('Gen $g')),
              ],
              onChanged: vm.setGeneration,
            ),
          ),
          const SizedBox(width: 8),
        ]),
        Expanded(child: _body(vm)),
      ]),
    );
  }

  Widget _body(PokedexViewModel vm) {
    if (!vm.ready) {
      return vm.error != null
          ? Center(child: FilledButton(onPressed: vm.init, child: const Text('Reintentar')))
          : const Center(child: CircularProgressIndicator());
    }
    if (vm.isEmpty) return const Center(child: Text('Sin resultados'));

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.1,
            ),
            itemCount: vm.items.length, // virtualizado: solo construye lo visible
            itemBuilder: (_, i) => _PokemonTile(vm.items[i]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: vm.error != null
                  ? FilledButton(onPressed: vm.loadMore, child: const Text('Reintentar'))
                  : vm.loading
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PokemonTile extends StatelessWidget {
  const _PokemonTile(this.p);
  final PokemonCard p;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => DetailPage(id: p.id))),
          child: Column(children: [
            Expanded(
              child: Hero(
                tag: 'poke-${p.id}',
                child: CachedNetworkImage(
                  imageUrl: spriteUrl(p.id),
                  memCacheWidth: 200,
                  placeholder: (_, __) => const Center(child: Icon(Icons.catching_pokemon)),
                  errorWidget: (_, __, ___) => const Icon(Icons.error_outline),
                ),
              ),
            ),
            Text('#${p.id.toString().padLeft(4, '0')}  ${p.name}'),
            Text(p.types.join(' / '), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
          ]),
        ),
      );
}
