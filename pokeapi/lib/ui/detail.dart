import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../data/repositorio.dart';
import '../viewmodels/teams_view.dart';
import 'theme/app_theme.dart';
import 'widgets/poke_widgets.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key, required this.id});
  final int id; // id de /pokemon: especie (1-1025) o forma (>= 10000, p. ej. una mega)
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const _maxId = 1025;
  final _player = AudioPlayer();

  late int _id = widget.id; // número nacional (especie)
  PokemonDetail? _detail;   // forma mostrada (normal o mega)
  PokemonSpecies? _species;
  Object? _error;
  int _dir = 1; // dirección de la transición: 1 siguiente, -1 anterior
  bool _busy = false; // evita peticiones duplicadas al pulsar rápido

  @override
  void initState() {
    super.initState();
    _load(widget.id);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load(int target) async {
    if (_busy) return;
    _busy = true;
    try {
      final repo = context.read<PokemonRepository>();
      final d = await repo.getDetail(target);
      final s = await repo.getSpecies(d.speciesId);
      if (!mounted) return;
      setState(() {
        _dir = s.id >= _id ? 1 : -1;
        _id = s.id;
        _detail = d;
        _species = s;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (_detail == null) {
        setState(() => _error = e);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No se pudo cargar el Pokémon')));
      }
    } finally {
      _busy = false;
    }
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
      builder: (_) => ListView(shrinkWrap: true, children: [
        for (final t in vm.teams)
          ListTile(
            title: Text(t.name, style: AppText.title(size: 16)),
            subtitle: Text('${t.pokemonIds.length}/${Team.maxSize}', style: AppText.pixel()),
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
  Widget build(BuildContext context) {
    final d = _detail, s = _species;
    return Scaffold(
      backgroundColor: AppColors.red,
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          PokedexTopBar(
            title: 'POKÉDEX',
            leading: RoundIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
          ),
          Expanded(
            child: ScreenBezel(
              child: d == null || s == null ? _loadingOrError() : _animated(d, s),
            ),
          ),
          const BottomGrill(),
        ]),
      ),
    );
  }

  Widget _loadingOrError() => Center(
        child: _error != null
            ? FilledButton(
                onPressed: () {
                  setState(() => _error = null);
                  _load(_id);
                },
                child: const Text('REINTENTAR'),
              )
            : const CircularProgressIndicator(),
      );

  Widget _animated(PokemonDetail d, PokemonSpecies s) => AnimatedSwitcher(
        duration: kMedium,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, anim) {
          final incoming = (child.key as ValueKey<int>).value == _detail?.id;
          final dx = (incoming ? _dir : -_dir).toDouble() * 0.25;
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
              child: child,
            ),
          );
        },
        child: _DetailBody(
          key: ValueKey(d.id),
          d: d,
          s: s,
          isInitial: d.id == widget.id,
          onPrev: _id > 1 ? () => _load(_id - 1) : null,
          onNext: _id < _maxId ? () => _load(_id + 1) : null,
          onSound: d.cryUrl == null ? null : () => _player.play(UrlSource(d.cryUrl!)),
          onAdd: () => _addToTeam(d),
          onForm: (f) => _load(f.id),
        ),
      );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    super.key,
    required this.d,
    required this.s,
    required this.isInitial,
    required this.onPrev,
    required this.onNext,
    required this.onSound,
    required this.onAdd,
    required this.onForm,
  });
  final PokemonDetail d;
  final PokemonSpecies s;
  final bool isInitial;
  final VoidCallback? onPrev, onNext, onSound;
  final VoidCallback onAdd;
  final ValueChanged<PokemonForm> onForm;

  @override
  Widget build(BuildContext context) {
    final color = typeColor(d.types.first);
    return ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 20), children: [
      _ArtPanel(
        d: d,
        color: color,
        isInitial: isInitial,
        onPrev: onPrev,
        onNext: onNext,
        onSound: onSound,
        onAdd: onAdd,
      ),
      if (s.forms.length > 1) ...[
        const SizedBox(height: 12),
        _FormSelector(forms: s.forms, currentId: d.id, onSelect: onForm),
      ],
      const SizedBox(height: 12),
      _InfoCard(d: d, s: s),
      const SizedBox(height: 12),
      _Panel(child: _Stats(d, color)),
      const SizedBox(height: 12),
      _Panel(child: _Evolution(d.speciesId)),
    ]);
  }
}

class _ArtPanel extends StatelessWidget {
  const _ArtPanel({
    required this.d,
    required this.color,
    required this.isInitial,
    required this.onPrev,
    required this.onNext,
    required this.onSound,
    required this.onAdd,
  });
  final PokemonDetail d;
  final Color color;
  final bool isInitial;
  final VoidCallback? onPrev, onNext, onSound;
  final VoidCallback onAdd;

  Widget _art() {
    // Sprite pixelado ampliado sin suavizado (como la referencia);
    // si no existe (algunas formas nuevas), se usa el artwork oficial.
    final img = CachedNetworkImage(
      imageUrl: spriteUrl(d.id),
      filterQuality: FilterQuality.none,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const Center(child: PokeballIcon(size: 40)),
      errorWidget: (_, __, ___) => CachedNetworkImage(imageUrl: artworkUrl(d.id), fit: BoxFit.contain),
    );
    return isInitial ? Hero(tag: 'poke-${d.id}', child: img) : img;
  }

  @override
  Widget build(BuildContext context) {
    // Aparición: opacidad + escala leve (solo al abrir los detalles).
    final art = isInitial
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            builder: (_, t, child) =>
                Opacity(opacity: t, child: Transform.scale(scale: 0.92 + 0.08 * t, child: child)),
            child: _art(),
          )
        : _art();

    return Container(
      height: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: AppColors.ink, width: 3),
        gradient: typeGradient(color),
      ),
      child: Stack(children: [
        const Positioned.fill(child: PixelGrid()),
        Center(child: Icon(Icons.catching_pokemon, size: 240, color: Colors.white.withValues(alpha: 0.18))),
        Align(
          alignment: const Alignment(0, 0.8),
          child: Container(
            width: 170,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.all(Radius.elliptical(85, 12)),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(padding: const EdgeInsets.fromLTRB(44, 36, 44, 24), child: art),
        ),
        if (d.isMega)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: MegaBadge(label: formLabel(d.name).toUpperCase())),
          ),
        Positioned(left: 10, top: 10, child: RoundIconButton(icon: Icons.chevron_left, onTap: onPrev)),
        Positioned(right: 10, top: 10, child: RoundIconButton(icon: Icons.chevron_right, onTap: onNext)),
        Positioned(
          left: 10,
          bottom: 10,
          child: RoundIconButton(icon: Icons.group_add, onTap: onAdd, color: AppColors.red, iconColor: AppColors.white),
        ),
        Positioned(right: 10, bottom: 10, child: RoundIconButton(icon: Icons.volume_up, onTap: onSound)),
      ]),
    );
  }

  Gradient? typeGradient(Color color) {
    return null;
  }
}

/// Selector Normal / Mega / Mega X / Mega Y.
class _FormSelector extends StatelessWidget {
  const _FormSelector({required this.forms, required this.currentId, required this.onSelect});
  final List<PokemonForm> forms;
  final int currentId;
  final ValueChanged<PokemonForm> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(children: [
          for (final f in forms)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 3),
              child: _FormChip(form: f, selected: f.id == currentId, onTap: () => onSelect(f)),
            ),
        ]),
      );
}

class _FormChip extends StatelessWidget {
  const _FormChip({required this.form, required this.selected, required this.onTap});
  final PokemonForm form;
  final bool selected;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.ink;
    return Pressable(
      onTap: selected ? null : onTap,
      child: AnimatedContainer(
        duration: kMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: retroBox(radius: 12, color: selected && !form.isMega ? AppColors.red : AppColors.paper)
            .copyWith(gradient: selected && form.isMega ? kMegaGradient : null),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(form.isMega ? Icons.auto_awesome : Icons.catching_pokemon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(formLabel(form.name).toUpperCase(), style: AppText.pixel(size: 12, color: fg)),
        ]),
      ),
    );
  }

}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: retroBox(),
        child: child,
      );

}

Widget _rule() => Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.ink.withValues(alpha: 0.25),
    );

Widget _vrule() => VerticalDivider(width: 20, thickness: 2, color: AppColors.ink.withValues(alpha: 0.25));

/// Tarjeta principal: nombre, tipo, descripción, datos y género.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.d, required this.s});
  final PokemonDetail d;
  final PokemonSpecies s;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pokeName(d.name), style: AppText.title(size: 28)),
                Text(
                  d.isMega ? '${dex(s.id)} · ${formLabel(d.name).toUpperCase()}' : dex(s.id),
                  style: AppText.pixel(size: 16),
                ),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final t in d.types)
                Padding(padding: const EdgeInsets.only(bottom: 6), child: TypeChip(t)),
            ]),
          ]),
          _rule(),
          Text(
            s.description.isEmpty ? 'Sin descripción disponible.' : s.description,
            style: AppText.body(size: 13, weight: FontWeight.w400).copyWith(height: 1.45),
          ),
          _rule(),
          IntrinsicHeight(
            child: Row(children: [
              _Fact(Icons.fitness_center, 'PESO', '${d.weightKg} kg'),
              _vrule(),
              _Fact(Icons.height, 'ALTURA', '${d.heightM} m'),
              _vrule(),
              _Fact(Icons.auto_awesome, 'HABILIDAD', d.abilities.isEmpty ? '—' : cap(d.abilities.first)),
            ]),
          ),
          _rule(),
          GenderRatio(femalePct: s.femalePct),
        ]),
      );

}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.ink),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: AppText.pixel(size: 11, color: AppColors.grey))),
          ]),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 14)),
        ]),
      );
}

const _statLabels = {
  'hp': 'PS',
  'attack': 'Ataque',
  'defense': 'Defensa',
  'special-attack': 'Atq. esp.',
  'special-defense': 'Def. esp.',
  'speed': 'Velocidad',
};

class _Stats extends StatelessWidget {
  const _Stats(this.d, this.color);
  final PokemonDetail d;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final total = d.stats.values.fold(0, (a, b) => a + b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('ESTADÍSTICAS BASE', style: AppText.pixel(size: 13, color: AppColors.grey))),
        Text('TOTAL $total', style: AppText.pixel(size: 13)),
      ]),
      const SizedBox(height: 8),
      for (final e in d.stats.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(width: 92, child: Text(_statLabels[e.key] ?? e.key, style: AppText.body(size: 12, weight: FontWeight.w400))),
            SizedBox(width: 36, child: Text('${e.value}', style: AppText.body(size: 12))),
            Expanded(
              child: Container(
                height: 10,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.ink, width: 1.5),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (e.value / 255).clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
          ]),
        ),
    ]);
  }
}

class _Evolution extends StatefulWidget {
  const _Evolution(this.speciesId);
  final int speciesId;
  @override
  State<_Evolution> createState() => _EvolutionState();
}

class _EvolutionState extends State<_Evolution> {
  late final Future<List<PokemonSummary>> _future =
      context.read<PokemonRepository>().getEvolution(widget.speciesId);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('EVOLUCIONES', style: AppText.pixel(size: 13, color: AppColors.grey)),
        const SizedBox(height: 8),
        FutureBuilder<List<PokemonSummary>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return Text('No se pudo cargar', style: AppText.body(color: AppColors.grey));
            if (!snap.hasData) {
              return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final chain = snap.data!;
            if (chain.length == 1) return Text('Sin evoluciones', style: AppText.body(color: AppColors.grey));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < chain.length; i++) ...[
                  if (i > 0) const Icon(Icons.chevron_right, color: AppColors.ink),
                  _EvoItem(p: chain[i], current: chain[i].id == widget.speciesId),
                ],
              ]),
            );
          },
        ),
      ]);
}

class _EvoItem extends StatelessWidget {
  const _EvoItem({required this.p, required this.current});
  final PokemonSummary p;
  final bool current;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: current ? null : () => Navigator.push(context, fadeRoute(DetailPage(id: p.id))),
        child: Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: current
              ? retroBox(color: AppColors.cream, radius: 12, shadow: false)
              : BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            CachedNetworkImage(imageUrl: spriteUrl(p.id), width: 56, height: 56, filterQuality: FilterQuality.none),
            Text(cap(p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 11)),
            Text(dex(p.id), style: AppText.pixel(size: 10, color: AppColors.grey)),
          ]),
        ),
      );

}
