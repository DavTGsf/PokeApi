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
  final int id;
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  static const _maxId = 1025;
  final _player = AudioPlayer();

  late int _id = widget.id;
  PokemonDetail? _detail;
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
      final d = await context.read<PokemonRepository>().getDetail(target);
      if (!mounted) return;
      setState(() {
        _dir = target >= _id ? 1 : -1;
        _id = target;
        _detail = d;
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
    final d = _detail;
    return Scaffold(
      body: Column(children: [
        PokedexHeader(
          title: dex(_id),
          leading: RoundIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
        ),
        Expanded(child: d == null ? _loadingOrError() : _animated(d)),
      ]),
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

  Widget _animated(PokemonDetail d) => AnimatedSwitcher(
        duration: kMedium,
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, anim) {
          final incoming = (child.key as ValueKey<int>).value == _id;
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
          isInitial: d.id == widget.id,
          onPrev: d.id > 1 ? () => _load(d.id - 1) : null,
          onNext: d.id < _maxId ? () => _load(d.id + 1) : null,
          onSound: d.cryUrl == null ? null : () => _player.play(UrlSource(d.cryUrl!)),
          onAdd: () => _addToTeam(d),
        ),
      );
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    super.key,
    required this.d,
    required this.isInitial,
    required this.onPrev,
    required this.onNext,
    required this.onSound,
    required this.onAdd,
  });
  final PokemonDetail d;
  final bool isInitial;
  final VoidCallback? onPrev, onNext, onSound;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final color = typeColor(d.types.first);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
      _ArtPanel(
        d: d,
        color: color,
        isInitial: isInitial,
        onPrev: onPrev,
        onNext: onNext,
        onSound: onSound,
        onAdd: onAdd,
      ),
      const SizedBox(height: 16),
      _Panel(child: _Info(d)),
      const SizedBox(height: 12),
      _Panel(child: _Stats(d, color)),
      const SizedBox(height: 12),
      _Panel(child: _Evolution(d.id)),
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
    final img = CachedNetworkImage(
      imageUrl: artworkUrl(d.id),
      fit: BoxFit.contain,
      placeholder: (_, __) => CachedNetworkImage(
        imageUrl: spriteUrl(d.id),
        filterQuality: FilterQuality.none,
        fit: BoxFit.contain,
      ),
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
      height: 290,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.6), color.withValues(alpha: 0.22)],
        ),
      ),
      child: Stack(children: [
        Center(child: Icon(Icons.catching_pokemon, size: 230, color: Colors.white.withValues(alpha: 0.28))),
        Center(child: Padding(padding: const EdgeInsets.all(28), child: art)),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: RoundIconButton(icon: Icons.chevron_left, onTap: onPrev),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: RoundIconButton(icon: Icons.chevron_right, onTap: onNext),
          ),
        ),
        Positioned(left: 8, bottom: 8, child: RoundIconButton(icon: Icons.group_add, onTap: onAdd, color: AppColors.red, iconColor: AppColors.white)),
        Positioned(right: 8, bottom: 8, child: RoundIconButton(icon: Icons.volume_up, onTap: onSound)),
      ]),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: child,
      );
}

class _Info extends StatelessWidget {
  const _Info(this.d);
  final PokemonDetail d;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cap(d.name), style: AppText.title(size: 30)),
              Text(dex(d.id), style: AppText.pixel(size: 14, color: AppColors.grey)),
            ]),
          ),
          Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.end, children: [
            for (final t in d.types) TypeChip(t),
          ]),
        ]),
        Divider(height: 28, thickness: 1.5, color: AppColors.ink.withValues(alpha: 0.12)),
        IntrinsicHeight(
          child: Row(children: [
            _Fact(Icons.monitor_weight_outlined, 'PESO', '${d.weightKg} kg'),
            VerticalDivider(width: 24, thickness: 1.5, color: AppColors.ink.withValues(alpha: 0.12)),
            _Fact(Icons.height, 'ALTURA', '${d.heightM} m'),
          ]),
        ),
        Divider(height: 28, thickness: 1.5, color: AppColors.ink.withValues(alpha: 0.12)),
        Row(children: [_Fact(Icons.auto_awesome, 'HABILIDADES', d.abilities.map(cap).join(', '))]),
      ]);
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 16, color: AppColors.grey),
            const SizedBox(width: 4),
            Text(label, style: AppText.pixel(size: 11, color: AppColors.grey)),
          ]),
          const SizedBox(height: 4),
          Text(value, style: AppText.body(size: 16, weight: FontWeight.w800)),
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
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ESTADÍSTICAS BASE', style: AppText.pixel(size: 13, color: AppColors.grey)),
        const SizedBox(height: 8),
        for (final e in d.stats.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              SizedBox(width: 84, child: Text(_statLabels[e.key] ?? e.key, style: AppText.body(size: 13))),
              SizedBox(width: 36, child: Text('${e.value}', style: AppText.body(size: 13, weight: FontWeight.w800))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: [
                    Container(height: 8, color: color.withValues(alpha: 0.18)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (e.value / 255).clamp(0.0, 1.0),
                      child: Container(height: 8, color: color),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
      ]);
}

class _Evolution extends StatefulWidget {
  const _Evolution(this.id);
  final int id;
  @override
  State<_Evolution> createState() => _EvolutionState();
}

class _EvolutionState extends State<_Evolution> {
  late final Future<List<PokemonSummary>> _future =
      context.read<PokemonRepository>().getEvolution(widget.id);

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
                  if (i > 0) const Icon(Icons.chevron_right, color: AppColors.grey),
                  _EvoItem(p: chain[i], current: chain[i].id == widget.id),
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
          decoration: BoxDecoration(
            color: current ? AppColors.cream : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: current ? AppColors.ink.withValues(alpha: 0.4) : Colors.transparent, width: 1.5),
          ),
          child: Column(children: [
            CachedNetworkImage(imageUrl: spriteUrl(p.id), width: 56, height: 56, filterQuality: FilterQuality.none),
            Text(cap(p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(size: 12)),
            Text(dex(p.id), style: AppText.pixel(size: 10, color: AppColors.grey)),
          ]),
        ),
      );
}
