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

/// Cabecera compacta tipo carcasa de Pokédex.
class PokedexHeader extends StatelessWidget {
  const PokedexHeader({super.key, required this.title, this.leading});
  final String title;
  final Widget? leading;

  Widget _led(Color c) => Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(left: 5),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.ink, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.red,
          border: const Border(bottom: BorderSide(color: AppColors.redDark, width: 4)),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          leading ?? const PokeballIcon(size: 36),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: AppText.pixel(size: 20, color: AppColors.white))),
          _led(const Color(0xFFFFD84A)),
          _led(const Color(0xFF6BD36B)),
          _led(AppColors.white),
        ]),
      );
}

/// Botón circular crema (anterior/siguiente, volver, sonido...).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = AppColors.cream,
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
      );
}

class TypeChip extends StatelessWidget {
  const TypeChip(this.type, {super.key, this.small = false});
  final String type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = typeColor(type);
    final fg = c.computeLuminance() > 0.5 ? AppColors.ink : AppColors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Text(typeLabel(type).toUpperCase(), style: AppText.pixel(size: small ? 10 : 12, color: fg)),
    );
  }
}
