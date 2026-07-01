import 'package:flutter_test/flutter_test.dart';
import 'package:pawquest/utils/step_math.dart';

void main() {
  group('StepMath.sensorDelta', () {
    test('returns the increase between cumulative sensor readings', () {
      expect(
        StepMath.sensorDelta(previousReading: 1000, currentReading: 1125),
        125,
      );
    });

    test('returns zero when the reading is unchanged', () {
      expect(
        StepMath.sensorDelta(previousReading: 1000, currentReading: 1000),
        0,
      );
    });

    test('does not subtract steps when the sensor resets', () {
      expect(
        StepMath.sensorDelta(previousReading: 1000, currentReading: 20),
        0,
      );
    });
  });

  test('nonNegative prevents invalid negative daily totals', () {
    expect(StepMath.nonNegative(-10), 0);
    expect(StepMath.nonNegative(250), 250);
  });
}
