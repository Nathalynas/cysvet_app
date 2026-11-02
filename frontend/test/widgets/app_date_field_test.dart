import 'package:cysvet_app/core/widgets/app_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('data depois de hoje mostra aviso e não é aplicada', (tester) async {
    final recebidas = <DateTime?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDateField(
            label: 'Data da última IA',
            value: null,
            onChanged: recebidas.add,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '10052062');
    await tester.pump();

    expect(find.text('A data não pode ser depois de hoje'), findsOneWidget);
    expect(recebidas.whereType<DateTime>(), isEmpty);

    await tester.enterText(find.byType(EditableText), '10052024');
    await tester.pump();
    expect(find.text('A data não pode ser depois de hoje'), findsNothing);
    expect(recebidas.last, DateTime(2024, 5, 10));
  });
}
