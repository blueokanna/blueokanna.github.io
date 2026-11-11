import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// Fade out the departing content before revealing the next page.
/// Both route animations are necessary: the shell's background is shared and
/// the pages themselves are transparent. A primary-only fade exposes old text.
class BlogPageTransition extends StatelessWidget {
  const BlogPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final transitioning =
        !animation.isCompleted || !secondaryAnimation.isDismissed;
    return FadeThroughTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      fillColor: Colors.transparent,
      child: IgnorePointer(
        ignoring: transitioning,
        child: ExcludeFocus(
          excluding: transitioning,
          child: ExcludeSemantics(excluding: transitioning, child: child),
        ),
      ),
    );
  }
}
