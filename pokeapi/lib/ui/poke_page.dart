import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../viewmodels/poke_view.dart';
import 'detail.dart';
import 'theme/app_theme.dart';
import 'widgets/poke_widgets.dart';

class PokedexPage extends StatefulWidget {
  const PokedexPage({super.key});
  @override
  State<PokedexPage> createState() => _PokedexPageState();
}

class _PokedexPageState extends State<PokedexPage> {
  final _scroll = ScrollController();
  final _ctrl = TextEditingController();
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
    _ctrl.dispose();
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

    return Column(children: [
      const PokedexHeader(title: 'POKÉDEX'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _ctrl,
          onChanged: _onSearch,
          style: AppText.body(),
          decoration: InputDecoration(
            hintText: 'Buscar por nombre o número',
            hintStyle: AppText.body(color: AppColors.grey),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(Icons.search, color: AppColors.grey),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _ctrl,
              builder: (_, v, __) => Row(mainAxisSize: MainAxisSize.min, children: [
                if (vm.loading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                if (v.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.grey),
                    onPressed: () {
                      _ctrl.clear();
                      _onSearch('');
                    },
                  ),
              ]),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.red, width: 2),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: _FilterDropdown<String>(
              hint: 'Tipo',
              value: vm.type,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos los tipos')),
                for (final t in pokemonTypes)
                  DropdownMenuItem(value: t, child: Text(typeLabel(t))),
              ],
              onChanged: vm.setType,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterDropdown<int>(
              hint: 'Generación',
              value: vm.generation,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                for (var g = 1; g <= 9; g++)
                  DropdownMenuItem(value: g, child: Text('Gen $g')),
              ],
              onChanged: vm.setGeneration,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(child: _body(vm)),
    ]);
  }

  Widget _body(PokedexViewModel vm) {
    if (!vm.ready) {
      return vm.error != null
          ? Center(child: FilledButton(onPressed: vm.init, child: const Text('REINTENTAR')))
          : const Center(child: CircularProgressIndicator());
    }
    if (vm.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Opacity(opacity: 0.5, child: PokeballIcon(size: 64)),
          const SizedBox(height: 12),
          Text('SIN RESULTADOS', style: AppText.pixel(size: 14, color: AppColors.grey)),
        ]),
      );
    }
    if (vm.items.isEmpty && vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: vm.items.length, // virtualizado: solo construye lo visible
            itemBuilder: (_, i) => _PokemonTile(vm.items[i]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: vm.error != null
                  ? FilledButton(onPressed: vm.loadMore, child: const Text('REINTENTAR'))
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

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({required this.hint, required this.value, required this.items, required this.onChanged});
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            isExpanded: true,
            hint: Text(hint, style: AppText.body(color: AppColors.grey)),
            value: value,
            items: items,
            onChanged: onChanged,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: AppColors.white,
            style: AppText.body(),
            icon: const Icon(Icons.expand_more, color: AppColors.grey),
          ),
        ),
      );
}

class _PokemonTile extends StatelessWidget {
  const _PokemonTile(this.p);
  final PokemonCard p;

  @override
  Widget build(BuildContext context) {
    final color = typeColor(p.types.isEmpty ? '' : p.types.first);
    return Pressable(
      onTap: () => Navigator.push(context, fadeRoute(DetailPage(id: p.id))),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.08)],
                ),
              ),
              child: Stack(children: [
                Positioned(
                  right: -16,
                  bottom: -16,
                  child: Icon(Icons.catching_pokemon, size: 96, color: Colors.white.withValues(alpha: 0.5)),
                ),
                Positioned(left: 10, top: 8, child: Text(dex(p.id), style: AppText.pixel(size: 11, color: AppColors.grey))),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Hero(
                      tag: 'poke-${p.id}',
                      child: CachedNetworkImage(
                        imageUrl: spriteUrl(p.id),
                        memCacheWidth: 200,
                        filterQuality: FilterQuality.none, // sprites nítidos, estilo pixel
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(child: Icon(Icons.catching_pokemon, color: AppColors.grey)),
                        errorWidget: (_, __, ___) => const Icon(Icons.error_outline, color: AppColors.grey),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(children: [
              Text(cap(p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title(size: 16)),
              const SizedBox(height: 6),
              Wrap(spacing: 4, runSpacing: 4, alignment: WrapAlignment.center, children: [
                for (final t in p.types) TypeChip(t, small: true),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
