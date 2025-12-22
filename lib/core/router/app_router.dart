import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.main,

  routes: [
    GoRoute(
      path: RoutePaths.main,
      builder: (context, state) => const Placeholder(),
    ),
  ],
);
