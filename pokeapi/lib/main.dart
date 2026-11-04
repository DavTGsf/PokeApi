import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/repositorio.dart';
import 'ui/home_page.dart';
import 'viewmodels/poke_view.dart';
import 'viewmodels/teams_view.dart';
import 'ui/theme/app_theme.dart';

// ...


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(PokeApi(prefs: prefs));
}

class PokeApi extends StatelessWidget {
  const PokeApi({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final repo = PokemonRepository(prefs);
    return MultiProvider(
      providers: [
        Provider.value(value: repo),
        ChangeNotifierProvider(create: (_) => PokedexViewModel(repo)..init()),
        ChangeNotifierProvider(create: (_) => TeamsViewModel(prefs)..load()),
      ],
      child: MaterialApp(
        title: 'PokéDex',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(), // ← antes: ThemeData(colorSchemeSeed: ...)
        home: const HomePage(),
      ),
    );
  }
}