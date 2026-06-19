import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:washer/core/utils/app_logger.dart';
import 'package:washer/features/app_version/data/data_sources/remote/app_version_remote_data_source.dart';
import 'package:washer/features/app_version/data/models/app_version_status_model.dart';

/// 앱 시작 시점에 현재 플랫폼/버전을 서버에 보내
/// 강제·권장 업데이트 여부를 조회한다.
class AppVersionCheckService {
  const AppVersionCheckService(this._remoteDataSource);

  final AppVersionRemoteDataSource _remoteDataSource;

  /// 업데이트 판단 결과를 반환한다.
  ///
  /// 네트워크 오류·플랫폼 미지원·파싱 실패 등으로 판단할 수 없는 경우에는
  /// 사용자의 앱 진입을 막지 않도록 `null`을 반환한다.
  Future<AppVersionStatusModel?> fetchStatus() async {
    try {
      final platform = _resolvePlatform();
      if (platform == null) {
        return null;
      }

      final info = await PackageInfo.fromPlatform();
      final versionCode = int.tryParse(info.buildNumber);
      if (versionCode == null) {
        return null;
      }

      return await _remoteDataSource.getStatus(
        platform: platform,
        versionCode: versionCode,
        versionName: info.version,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '앱 버전 상태 조회 중 오류가 발생했습니다.',
        name: 'AppVersionCheckService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 전달받은 스토어 링크를 외부 앱(스토어)에서 연다.
  Future<void> openStore(String? storeLink) async {
    if (storeLink == null || storeLink.isEmpty) {
      return;
    }

    final uri = Uri.tryParse(storeLink);
    if (uri == null) {
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        AppLogger.error(
          '스토어 페이지를 여는 데 실패했습니다. (launchUrl returned false)',
          name: 'AppVersionCheckService',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        '스토어 페이지를 여는 중 오류가 발생했습니다.',
        name: 'AppVersionCheckService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String? _resolvePlatform() {
    if (Platform.isAndroid) {
      return 'ANDROID';
    }
    if (Platform.isIOS) {
      return 'IOS';
    }
    return null;
  }
}

final appVersionCheckServiceProvider = Provider<AppVersionCheckService>((ref) {
  return AppVersionCheckService(ref.watch(appVersionRemoteDataSourceProvider));
});
