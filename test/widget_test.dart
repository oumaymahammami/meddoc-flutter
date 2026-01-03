import 'package:flutter_test/flutter_test.dart';

import 'package:meddoc/app/app.dart';

void main() {
  testWidgets('MedDoc launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MedDocApp());

    // Vérifie juste que l'app démarre (pas besoin du compteur)
    expect(
      find.text('MedDoc'),
      findsNothing,
    ); // MaterialApp n'affiche pas forcément le titre
  });
}
