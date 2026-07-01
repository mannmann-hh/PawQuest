import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/screens/weather_location_screen.dart';
import 'package:pawquest/theme/app_palette.dart';

void main() {
  testWidgets('validates coordinates and submits a valid location',
      (tester) async {
    double? submittedLatitude;
    double? submittedLongitude;

    await tester.pumpWidget(
      MaterialApp(
        home: WeatherLocationScreen(
          palette: AppPalette.all.first,
          onCoordinatesSubmitted: (latitude, longitude) async {
            submittedLatitude = latitude;
            submittedLongitude = longitude;
          },
          onDeviceLocationRequested: () async {},
        ),
      ),
    );

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '100',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '12.4964',
    );
    await tester.tap(find.text('Use these coordinates'));
    await tester.pump();

    expect(find.text('Value must be between -90.0 and 90.0'), findsOneWidget);
    expect(submittedLatitude, isNull);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      '41.9028',
    );
    await tester.tap(find.text('Use these coordinates'));
    await tester.pumpAndSettle();

    expect(submittedLatitude, 41.9028);
    expect(submittedLongitude, 12.4964);
  });

  testWidgets('switches back to device location', (tester) async {
    var deviceLocationRequested = false;

    await tester.pumpWidget(
      MaterialApp(
        home: WeatherLocationScreen(
          palette: AppPalette.all.first,
          initialLatitude: 41.9028,
          initialLongitude: 12.4964,
          onCoordinatesSubmitted: (_, __) async {},
          onDeviceLocationRequested: () async {
            deviceLocationRequested = true;
          },
        ),
      ),
    );

    await tester.tap(find.text('Use device location'));
    await tester.pumpAndSettle();

    expect(deviceLocationRequested, isTrue);
  });

  testWidgets('keeps the page open and shows a submission error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherLocationScreen(
          palette: AppPalette.all.first,
          initialLatitude: 41.9028,
          initialLongitude: 12.4964,
          onCoordinatesSubmitted: (_, __) async {
            throw Exception('Weather service unavailable');
          },
          onDeviceLocationRequested: () async {},
        ),
      ),
    );

    await tester.tap(find.text('Use these coordinates'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Weather service unavailable'), findsOneWidget);
    expect(find.text('Weather location'), findsOneWidget);
  });

  testWidgets('accepts valid latitude and longitude boundary values',
      (tester) async {
    double? latitude;
    double? longitude;
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherLocationScreen(
          palette: AppPalette.all.first,
          onCoordinatesSubmitted: (lat, lon) async {
            latitude = lat;
            longitude = lon;
          },
          onDeviceLocationRequested: () async {},
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), '-90');
    await tester.enterText(find.byType(TextFormField).at(1), '180');
    await tester.tap(find.text('Use these coordinates'));
    await tester.pumpAndSettle();

    expect(latitude, -90);
    expect(longitude, 180);
  });
}
