import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:new_version_plus/model/version_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:washer/core/utils/app_logger.dart';

/// 스토어(App Store / Play Store)에 게시된 최신 버전과
/// 현재 설치된 앱 버전(pubspec.yaml 기준)을 비교한다.
class VersionCheckService {
  const VersionCheckService();

  /// 업데이트가 필요한 경우(스토어 버전 > 현재 버전)에만 스토어 정보를 반환한다.
  ///
  /// 최신 버전이거나, 네트워크 오류·스토어 미게시·버전 파싱 실패 등으로
  /// 판단할 수 없는 경우에는 사용자의 앱 진입을 막지 않도록 `null`을 반환한다.
  ///
  /// 스토어 링크가 비어 있으면 업데이트 버튼을 눌러도 아무 동작을 할 수 없어
  /// 사용자가 앱에 갇히므로, 이 경우에도 진입을 막지 않도록 `null`을 반환한다.
  Future<VersionStatus?> fetchUpdatableStatus() async {
    try {
      final newVersion = NewVersionPlus();
      final status = await newVersion.getVersionStatus();
      if (status == null || !status.canUpdate || status.appStoreLink.isEmpty) {
        return null;
      }
      return status;
    } catch (error, stackTrace) {
      AppLogger.error(
        '앱 버전 확인 중 오류가 발생했습니다.',
        name: 'VersionCheckService',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 전달받은 스토어 링크를 외부 앱(스토어)에서 연다.
  Future<void> openStore(String storeLink) async {
    if (storeLink.isEmpty) {
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
          name: 'VersionCheckService',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        '스토어 페이지를 여는 중 오류가 발생했습니다.',
        name: 'VersionCheckService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final versionCheckServiceProvider = Provider<VersionCheckService>(
  (_) => const VersionCheckService(),
);
