import 'package:flutter_test/flutter_test.dart';
import 'package:pokeapi/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('La app arranca y muestra la navegación', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(PokeApi(prefs: prefs));

    expect(find.text('Pokédex'), findsOneWidget);
    expect(find.text('Equipos'), findsOneWidget);
  });
}
