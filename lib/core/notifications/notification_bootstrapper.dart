import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/notifications/notification_service.dart';

/// 앱 시작 시 알림(FCM) 초기화를 한 번 트리거하고 [child]를 그대로 렌더링하는 래퍼.
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
