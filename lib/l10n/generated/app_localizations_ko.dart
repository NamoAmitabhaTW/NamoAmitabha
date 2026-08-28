// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get amitabha => '아미타불';

  @override
  String get chant => '염불';

  @override
  String get records => '기록';

  @override
  String get settings => '설정';

  @override
  String get start => '시작';

  @override
  String get pause => '일시정지';

  @override
  String get save => '저장';

  @override
  String get total => '총계';

  @override
  String get days => '일';

  @override
  String get times => '회';

  @override
  String get noRecords => '아직 기록이 없습니다';

  @override
  String get language => '언어';

  @override
  String get cancel => '취소';

  @override
  String get pleaseWait => '잠시 기다려 주세요';

  @override
  String get downloading => '다운로드 중';

  @override
  String get unzipping => '설치 중';

  @override
  String get completed => '완료됨';

  @override
  String get preparing => '준비 중';

  @override
  String get preparingPleaseWait => '준비 중입니다. 잠시만 기다려 주세요…';

  @override
  String doNotOperateDuring(String phase) {
    return '\"$phase\" 중에는 이 화면을 유지해 주세요.\n앱 전환이나 화면 끄기 등의 조작을 하지 마세요.';
  }

  @override
  String get ok => '확인';

  @override
  String get downloadRequiredTitle => '다운로드 필요';

  @override
  String downloadRequiredBody(String modelName) {
    return '음성 인식 모델($modelName)이 기기에 없습니다.\n지금 다운로드하시겠습니까?';
  }

  @override
  String get download => '다운로드';

  @override
  String get downloadFailedTitle => '다운로드 실패';

  @override
  String get successTitle => '성공';

  @override
  String get successBody => '모델이 성공적으로 설치되었습니다.';

  @override
  String get unzipFailedTitle => '압축 해제 실패';

  @override
  String get unzipFailedLowSpaceBody =>
      '저장 공간이 부족하여 압축 해제에 실패했습니다. 공간을 확보한 후 \"다시 압축 해제\"를 눌러 주세요. 다운로드한 파일은 유지되므로 다시 다운로드할 필요가 없습니다.';

  @override
  String get close => '닫기';

  @override
  String get downloadFailedShort => '모델 다운로드에 실패했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get modelPrepareFailed =>
      '음성 인식 모델 설치에 실패했습니다. 기기에 저장 공간이 충분한지 확인한 후 다시 시도해 주세요.';

  @override
  String get retry => '다시 시도';

  @override
  String get micPermissionTitle => '마이크 권한 필요';

  @override
  String get micPermissionRationale =>
      '염불 횟수를 세려면 시스템 설정 > 염불 > 마이크에서 권한을 켜 주세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get bgScreenTitle => '염불 배경';

  @override
  String get bgUse => '사용';

  @override
  String get bgUpdate => '업데이트';

  @override
  String get bgDelete => '삭제';

  @override
  String get bgInUse => '사용 중';

  @override
  String get bgDefault => '기본';

  @override
  String get bgTypeVideo => '동영상';

  @override
  String get bgTypeImage => '이미지';

  @override
  String get bgDeleteTitle => '배경 삭제';

  @override
  String bgDeleteConfirm(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?\n삭제 후 언제든지 다시 다운로드할 수 있습니다.';
  }

  @override
  String bgClearedTitle(String name) {
    return '배경 \"$name\"이(가) 시스템에 의해 삭제되었습니다';
  }

  @override
  String get bgClearedBody =>
      '저장 공간이 부족하거나 앱 캐시를 지우면, 시스템이 공간 확보를 위해 다운로드한 배경을 삭제할 수 있습니다. 현재는 기본 배경으로 되돌렸으며, 필요할 때 다시 다운로드할 수 있습니다.';

  @override
  String get bgOfflineTitle => '오프라인 상태입니다';

  @override
  String get bgOfflineBody => '인터넷에 연결하면 배경을 다운로드할 수 있습니다.';

  @override
  String get bgDownloadErrorNetwork => '인터넷에 연결되어 있지 않아 배경을 다운로드할 수 없습니다.';

  @override
  String get bgDownloadErrorGeneric => '다운로드에 실패했습니다. 나중에 다시 시도해 주세요.';

  @override
  String get bgDownloadErrorNotAvailable =>
      '이 배경은 현재 다운로드할 수 없습니다. 제공이 중단되었거나 교체되었을 수 있습니다.';

  @override
  String get langFollowSystem => '시스템 설정 따르기';

  @override
  String get cancelling => '취소하는 중…';

  @override
  String get networkErrorBody => '네트워크 연결에 문제가 있습니다. 연결 상태를 확인한 후 다시 시도해 주세요.';

  @override
  String get timeoutErrorBody =>
      '연결 시간이 초과되었습니다. 네트워크가 불안정하거나 서버가 일시적으로 응답하지 않을 수 있습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get serverErrorBody => '서버 응답에 문제가 있습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get downloadFailedLowSpaceTitle => '저장 공간 부족';

  @override
  String get downloadFailedLowSpaceBody =>
      '기기의 저장 공간이 부족하여 설치를 완료할 수 없습니다. 공간을 확보한 후 \"다시 시도\"를 눌러 주세요.';

  @override
  String get retryAfterFreeSpace => '공간 확보 후 다시 시도';

  @override
  String get retryUnzipAfterFreeSpace => '공간 확보 후 다시 압축 해제';

  @override
  String get retryUnzipNote => '저장 공간 부족으로 압축 해제를 다시 시도하는 중';

  @override
  String get dedicationTitle => '회향게';

  @override
  String get dedicationButton => '회향';

  @override
  String get dedicationEdit => '회향게 편집';

  @override
  String get announcementsTitle => '공지사항';

  @override
  String get announcementsEmpty => '아직 공지사항이 없습니다';

  @override
  String get announcementsLinkCopied => '링크가 복사되었습니다';

  @override
  String get rateTitle => '리뷰로\n응원하기';

  @override
  String get shareTitle => '앱 공유';

  @override
  String get shareSubject => '하루 염불 — 무료 염불 카운터 앱';

  @override
  String get shareMessage =>
      '\'하루 염불\'은 무료 염불 카운터 앱입니다.\n염불 소리를 듣고 횟수를 자동으로 세어 줍니다.\n염불에만 집중하세요. 세는 일은 \'하루 염불\'에 맡기세요!';

  @override
  String get storeActionFailed => '스토어를 열 수 없습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get appDisplayName => '하루 염불';

  @override
  String get updateTitle => '새로운 버전이 출시되었습니다';

  @override
  String get updateBody => '앱을 업데이트하여 \'하루 염불\'을\n함께 더 좋게 만들어 주세요.';

  @override
  String get updateButton => '업데이트하기';

  @override
  String get updateLater => '나중에';
}
