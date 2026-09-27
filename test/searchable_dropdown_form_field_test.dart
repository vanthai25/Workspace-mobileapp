import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobileapp_bvhv/features/nhan_vien_v2/screens/dialogs/widgets/searchable_dropdown_form_field.dart';

void main() {
  testWidgets('tìm không dấu và chọn được giá trị danh mục', (tester) async {
    int? selectedValue = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: SearchableDropdownFormField<int?>(
                initialValue: selectedValue,
                decoration: const InputDecoration(
                  labelText: 'Khoa / Phòng',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Chưa chọn')),
                  DropdownMenuItem(value: 1, child: Text('Nội tổng hợp')),
                  DropdownMenuItem(value: 2, child: Text('Ngoại trú')),
                ],
                onChanged: (value) => selectedValue = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Nội tổng hợp'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ngoai');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ListTile, 'Nội tổng hợp'), findsNothing);
    expect(find.widgetWithText(ListTile, 'Ngoại trú'), findsOneWidget);

    await tester.tap(find.text('Ngoại trú'));
    await tester.pumpAndSettle();

    expect(selectedValue, 2);
    expect(find.text('Ngoại trú'), findsOneWidget);
  });
}
