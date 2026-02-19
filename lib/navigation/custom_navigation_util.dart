import 'package:flutter/material.dart';

enum PageTransitionType { slide, fade, none }

class CustomNavigationUtil {
  static Future<T?> to<T extends Object?>(
    BuildContext context,
    Widget page, {
    RouteSettings? settings,
    bool enableSwipeBack = false,
    PageTransitionType transitionType = PageTransitionType.slide,
  }) {
    if (transitionType == PageTransitionType.none) {
      return Navigator.push<T>(
        context,
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          settings: settings,
        ),
      );
    }

    if (transitionType == PageTransitionType.fade) {
      return Navigator.push<T>(
        context,
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          settings: settings,
        ),
      );
    }

    if (enableSwipeBack) {
      return Navigator.push<T>(
        context,
        MaterialPageRoute<T>(builder: (context) => page, settings: settings),
      );
    }

    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        settings: settings,
      ),
    );
  }

  static T? arguments<T extends Object?>(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as T?;
  }
}
