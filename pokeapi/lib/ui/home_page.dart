import 'package:flutter/material.dart';
import 'poke_page.dart';
import 'teams_page.dart';

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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.catching_pokemon), label: 'Pokédex'),
            NavigationDestination(icon: Icon(Icons.groups), label: 'Equipos'),
          ],
        ),
      );
}
