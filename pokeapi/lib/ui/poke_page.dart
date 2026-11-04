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
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.ink, width: 2),
    );

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: TextField(
          controller: _ctrl,
          onChanged: _onSearch,
          style: AppText.body(),
          decoration: InputDecoration(
            hintText: vm.megaOnly ? 'Buscar megaevolución' : 'Buscar por nombre o número',
            hintStyle: AppText.body(color: AppColors.grey, weight: FontWeight.w400),
            filled: true,
            fillColor: AppColors.paper,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixIcon: const Icon(Icons.search, color: AppColors.ink),
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
                    icon: const Icon(Icons.close, color: AppColors.ink),
                    onPressed: () {
                      _ctrl.clear();
                      _onSearch('');
                    },
                  ),
              ]),
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.red, width: 2.5)),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Expanded(
            child: _FilterDropdown<String>(
              hint: 'Tipo',
              value: vm.type,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                for (final t in pokemonTypes)
                  DropdownMenuItem(value: t, child: Text(typeLabel(t))),
              ],
              onChanged: vm.setType,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FilterDropdown<int>(
              hint: 'Gen.',
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
          _MegaToggle(value: vm.megaOnly, onChanged: vm.setMegaOnly),
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
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.76,
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
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: retroBox(radius: 12, shadow: false),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T?>(
            isExpanded: true,
            hint: Text(hint, style: AppText.body(color: AppColors.grey, weight: FontWeight.w400)),
            value: value,
            items: items,
            onChanged: onChanged,
            borderRadius: BorderRadius.circular(12),
            dropdownColor: AppColors.paper,
            style: AppText.body(size: 13),
            icon: const Icon(Icons.expand_more, color: AppColors.ink),
          ),
        ),
      );

}

class _MegaToggle extends StatelessWidget {
  const _MegaToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;


  @override
  Widget build(BuildContext context) {
    final fg = value ? AppColors.white : AppColors.ink;
    return Pressable(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: kMedium,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: retroBox(radius: 12, shadow: false)
            .copyWith(gradient: value ? kMegaGradient : null),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, size: 18, color: fg),
          const SizedBox(width: 4),
          Text('MEGA', style: AppText.pixel(size: 13, color: fg)),
        ]),
      ),
    );
  }

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
        decoration: retroBox(),
        child: Column(children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(6),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ink, width: 2),
                gradient: typeGradient(color),
              ),
              child: Stack(children: [
                const Positioned.fill(child: PixelGrid()),
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: Icon(Icons.catching_pokemon, size: 80, color: Colors.white.withValues(alpha: 0.25)),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Hero(
                      tag: 'poke-${p.id}',
                      child: CachedNetworkImage(
                        imageUrl: spriteUrl(p.id),
                        memCacheWidth: 200,
                        filterQuality: FilterQuality.none, // sprites nítidos, estilo pixel
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (_, __) => const Center(child: Icon(Icons.catching_pokemon, color: AppColors.white)),
                        errorWidget: (_, __, ___) => const Icon(Icons.error_outline, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: p.isMega
                      ? const MegaBadge(small: true)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(dex(p.id), style: AppText.pixel(size: 10, color: AppColors.paper)),
                        ),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Column(children: [
              Text(pokeName(p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title(size: 15)),
              const SizedBox(height: 5),
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
