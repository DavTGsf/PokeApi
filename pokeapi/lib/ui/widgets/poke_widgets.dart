import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Transición de pantalla: fundido de 250 ms (compatible con Hero).
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: kMedium,
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );

/// Respuesta táctil: escala y opacidad muy leves (120 ms).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: kFast,
        child: AnimatedOpacity(
          opacity: _down ? 0.85 : 1,
          duration: kFast,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Poké Ball dibujada (sin assets).
class PokeballIcon extends StatelessWidget {
  const PokeballIcon({super.key, this.size = 24});
  final double size;
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _PokeballPainter()));
}

class _PokeballPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final sw = size.width * 0.09;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, math.pi, math.pi, true, Paint()..color = AppColors.red);
    canvas.drawArc(rect, 0, math.pi, true, Paint()..color = AppColors.white);
    final line = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    canvas.drawCircle(c, r - sw / 2, line);
    canvas.drawLine(Offset(c.dx - r + sw / 2, c.dy), Offset(c.dx + r - sw / 2, c.dy), line);
    canvas.drawCircle(c, r * 0.3, Paint()..color = AppColors.white);
    canvas.drawCircle(c, r * 0.3, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Barra superior de la carcasa: Poké Ball, título y batería.
class PokedexTopBar extends StatelessWidget {
  const PokedexTopBar({super.key, required this.title, this.leading});
  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          leading ?? const PokeballIcon(size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: AppText.title(size: 24, color: AppColors.white).copyWith(
                shadows: const [Shadow(color: AppColors.redDark, offset: Offset(2, 2))],
              ),
            ),
          ),
          const _Battery(),
        ]),
      );
}

class _Battery extends StatelessWidget {
  const _Battery();

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(2)),
          ),
        ),
        Container(
          width: 42,
          height: 22,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 2.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(width: 14, color: AppColors.redDark),
          ]),
        ),
      ]);
}

/// Marco oscuro de la pantalla de la Pokédex.
class ScreenBezel extends StatelessWidget {
  const ScreenBezel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.redDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink, width: 3),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink, width: 3),
          ),
          child: child,
        ),
      );
}

/// Rejillas de altavoz y Poké Ball central (parte inferior de la carcasa).
class BottomGrill extends StatelessWidget {
  const BottomGrill({super.key});

  Widget _slots() => Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Container(
            width: 64,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: AppColors.redDark, borderRadius: BorderRadius.circular(2)),
          ),
      ]);

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(28, 6, 28, 8 + MediaQuery.paddingOf(context).bottom),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _slots(),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.redDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const PokeballIcon(size: 34),
          ),
          _slots(),
        ]),
      );
}

/// Título dentro de la pantalla, estilo LCD.
class PokedexHeader extends StatelessWidget {
  const PokedexHeader({super.key, required this.title, this.leading});
  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: AppColors.ink,
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Text('▶ $title', style: AppText.pixel(size: 15, color: AppColors.paper)),
        ]),
      );
}

/// Botón cuadrado retro (anterior/siguiente, volver, sonido...).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.paper,
    this.iconColor = AppColors.ink,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Pressable(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: retroBox(color: color, radius: 10),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ),
      );

  Decoration? retroBox({required Color color, required int radius}) {
    return null;
  }
}

/// Chip de tipo con icono, como en la referencia.
class TypeChip extends StatelessWidget {
  const TypeChip(this.type, {super.key, this.small = false});
  final String type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = typeColor(type);
    final fg = c.computeLuminance() > 0.5 ? AppColors.ink : AppColors.white;
    final dot = small ? 16.0 : 24.0;
    return Container(
      padding: EdgeInsets.fromLTRB(3, 3, small ? 8 : 12, 3),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: small ? null : const [BoxShadow(color: AppColors.ink, offset: Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: dot,
          height: dot,
          decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
          child: Icon(typeIcon(type), size: dot * 0.68, color: c),
        ),
        SizedBox(width: small ? 4 : 6),
        Text(typeLabel(type).toUpperCase(), style: AppText.pixel(size: small ? 10 : 13, color: fg)),
      ]),
    );
  }

  IconData? typeIcon(String type) {
    return null;
  }
}

/// Insignia de megaevolución.
class MegaBadge extends StatelessWidget {
  const MegaBadge({super.key, this.label = 'MEGA', this.small = false});
  final String label;
  final bool small;

  Gradient? get kMegaGradient => null;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
        decoration: BoxDecoration(
          gradient: kMegaGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink, width: 2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome, size: small ? 11 : 14, color: AppColors.white),
          SizedBox(width: small ? 3 : 5),
          Text(label, style: AppText.pixel(size: small ? 10 : 12, color: AppColors.white)),
        ]),
      );
}

/// Proporción de género con barra azul/rosa.
class GenderRatio extends StatelessWidget {
  const GenderRatio({super.key, required this.femalePct});
  final double? femalePct; // null = sin género

  @override
  Widget build(BuildContext context) {
    final f = femalePct;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const PokeballIcon(size: 14),
        const SizedBox(width: 6),
        Text('PROPORCIÓN DE GÉNERO', style: AppText.pixel(size: 12, color: AppColors.grey)),
      ]),
      const SizedBox(height: 6),
      if (f == null)
        Text('Sin género', style: AppText.body(size: 13))
      else ...[
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('♂ ${(100 - f).toStringAsFixed(1)}%', style: AppText.body(size: 14, color: AppColors.male)),
          const SizedBox(width: 18),
          Text('♀ ${f.toStringAsFixed(1)}%', style: AppText.body(size: 14, color: AppColors.female)),
        ]),
        const SizedBox(height: 8),
        Container(
          height: 10,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.ink, width: 1.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (f < 100) Expanded(flex: ((100 - f) * 10).round(), child: ColoredBox(color: AppColors.male)),
            if (f > 0) Expanded(flex: (f * 10).round(), child: ColoredBox(color: AppColors.female)),
          ]),
        ),
      ],
    ]);
  }
}

/// Rejilla de píxeles sutil para fondos retro.
class PixelGrid extends StatelessWidget {
  const PixelGrid({super.key});
  @override
  Widget build(BuildContext context) =>
      IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _GridPainter())));
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
