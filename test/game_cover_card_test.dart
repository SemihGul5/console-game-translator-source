import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gametranslate/models/game_catalog_entry.dart';
import 'package:gametranslate/widgets/game_cover_card.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('covers and titles keep equal card sizes at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scaler = TextScaler.linear(scale);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: scaler),
            child: Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(3, (index) {
                  return SizedBox(
                    width: 110,
                    child: GameCoverCard(
                      game: GameCatalogEntry(
                        id: '$index',
                        name: index == 0
                            ? 'Short'
                            : 'A very long game title with an extended edition',
                        sourceLanguage: 'en',
                        targetLanguage: 'tr',
                        file: 'test',
                        coverAspectRatio: [0.5, 1.0, 2.0][index],
                      ),
                      selected: index == 1,
                      downloaded: index != 2,
                      downloading: index == 2,
                      preparing: false,
                      onTap: () {},
                      loadCover: (_) async => Uint8List(0),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final sizes = tester.getSize(find.byType(GameCoverCard).first);
      for (final card in find.byType(GameCoverCard).evaluate()) {
        expect(tester.getSize(find.byWidget(card.widget)), sizes);
      }
      expect(sizes.width, 110);
      expect(sizes.height, closeTo(GameCoverCard.heightFor(110, scaler), 0.01));
      expect(tester.takeException(), isNull);
    });
  }
}
