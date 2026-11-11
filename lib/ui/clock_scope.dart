import 'package:flutter/material.dart';

class MotionClock extends InheritedWidget {
  const MotionClock({super.key, required this.clock, required super.child});
  final Animation<double> clock;
  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MotionClock>()!.clock;
  @override
  bool updateShouldNotify(MotionClock oldWidget) => clock != oldWidget.clock;
}
