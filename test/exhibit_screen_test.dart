import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:museum_guide/data/exhibits.dart';
import 'package:museum_guide/screens/exhibit_screen.dart';

void main() {
  testWidgets('ExhibitScreen displays Entrance Gate and hides audio and video when null', (WidgetTester tester) async {
    final exhibit = allExhibits[0]; // Entrance Gate: NO audio & NO video

    await tester.pumpWidget(
      MaterialApp(
        home: ExhibitScreen(exhibit: exhibit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrance Gate'), findsOneWidget);
    expect(find.text('Heritage & History'), findsOneWidget);
    expect(find.text('Audio Narration Guide'), findsNothing);
    expect(find.text('Archival Video Footage'), findsNothing);
  });

  testWidgets('ExhibitScreen displays Durbar Hall with audio and hides video', (WidgetTester tester) async {
    final exhibit = allExhibits[1]; // Durbar Hall: audio only

    await tester.pumpWidget(
      MaterialApp(
        home: ExhibitScreen(exhibit: exhibit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Durbar Hall'), findsOneWidget);
    expect(find.text('Audio Narration Guide'), findsOneWidget);
    expect(find.text('Archival Video Footage'), findsNothing);
  });

  testWidgets('ExhibitScreen displays Royal Gallery with video and hides audio', (WidgetTester tester) async {
    final exhibit = allExhibits[2]; // Royal Gallery: video only

    await tester.pumpWidget(
      MaterialApp(
        home: ExhibitScreen(exhibit: exhibit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Royal Gallery'), findsOneWidget);
    expect(find.text('Audio Narration Guide'), findsNothing);
    expect(find.text('Archival Video Footage'), findsOneWidget);
  });
}
