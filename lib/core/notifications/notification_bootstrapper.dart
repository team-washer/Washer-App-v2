import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/notifications/notification_service.dart';

class NotificationBootstrapper extends ConsumerStatefulWidget {
  const NotificationBootstrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<NotificationBootstrapper> createState() =>
      _NotificationBootstrapperState();
}

class _NotificationBootstrapperState
    extends ConsumerState<NotificationBootstrapper> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      unawaited(ref.read(notificationInitializationProvider.future));
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}