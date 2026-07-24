import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';
import 'package:frontend/screens/home/home_page.dart';

void main() {
  testWidgets('shows LensLink home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomePage(loadRecentSearches: false)),
    );

    expect(find.text('LensLink'), findsOneWidget);
    expect(find.text('최근 검색'), findsOneWidget);
  });
}
