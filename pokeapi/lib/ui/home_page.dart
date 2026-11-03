import 'package:flutter/material.dart';
import 'poke_page.dart';
import 'teams_page.dart';
import 'theme/app_theme.dart';
import 'widgets/poke_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  static const _pages = [PokedexPage(), TeamsPage()];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _index, children: _pages), // conserva scroll
        bottomNavigationBar: _NavBar(
          index: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
      );
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.catching_pokemon, 'POKÉDEX'),
    (Icons.groups, 'EQUIPOS'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.red,
          border: Border(top: BorderSide(color: AppColors.redDark, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: SafeArea(
          top: false,
          child: Row(children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _NavItem(
                    icon: _items[i].$1,
                    label: _items[i].$2,
                    selected: i == index,
                    onTap: () => onChanged(i),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: kMedium,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : AppColors.redDark.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 26, color: selected ? AppColors.red : AppColors.cream),
            const SizedBox(height: 2),
            Text(label, style: AppText.pixel(size: 11, color: selected ? AppColors.ink : AppColors.cream)),
          ]),
        ),
      );
}
