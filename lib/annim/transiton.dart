import 'package:flutter/material.dart';

class FadePageRouteBuilder<T> extends PageRouteBuilder<T> {
  final Widget widget;

  FadePageRouteBuilder({required this.widget})
      : super(
    transitionDuration: Duration(milliseconds: 500),
    pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        ) =>
    widget,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) =>
        FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        ),
  );
}
