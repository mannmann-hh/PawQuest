/// Pure rules used when converting cumulative pedometer readings into steps.
class StepMath {
  const StepMath._();

  /// Pedometer readings are cumulative. A reset or lower reading must never
  /// remove steps from the user's totals.
  static int sensorDelta({
    required int previousReading,
    required int currentReading,
  }) {
    final delta = currentReading - previousReading;
    return delta > 0 ? delta : 0;
  }

  static int nonNegative(int steps) => steps < 0 ? 0 : steps;
}
