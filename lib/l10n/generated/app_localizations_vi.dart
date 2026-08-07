// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get amitabha => 'A Di Đà Phật';

  @override
  String get chant => 'Niệm Phật';

  @override
  String get records => 'Nhật ký';

  @override
  String get settings => 'Cài đặt';

  @override
  String get start => 'Bắt đầu';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get save => 'Lưu';

  @override
  String get total => 'Tổng';

  @override
  String get days => 'Ngày';

  @override
  String get times => 'lần';

  @override
  String get noRecords => 'Chưa có bản ghi nào';

  @override
  String get logIn => 'Đăng nhập';

  @override
  String get logOut => 'Đăng xuất';

  @override
  String get enableCloudSync => 'Bật đồng bộ đám mây';

  @override
  String get account => 'Tài khoản';

  @override
  String get accountStatus => 'Trạng thái đăng nhập';

  @override
  String get statusSignedIn => 'Đã đăng nhập';

  @override
  String get statusSignedOut => 'Chưa đăng nhập';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String currentLanguage(String lang) {
    return 'Ngôn ngữ hiện tại: $lang';
  }

  @override
  String get langZhHant => '繁體中文';

  @override
  String get langEn => 'English';

  @override
  String get langJa => '日本語';

  @override
  String get langKo => '한국어';

  @override
  String get langVi => 'Tiếng Việt';

  @override
  String get langDe => 'Deutsch';

  @override
  String get langFr => 'Français';

  @override
  String get feedback => 'Phản hồi';

  @override
  String get deleteAccount => 'Xóa tài khoản';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get cancel => 'Hủy';

  @override
  String get done => 'Xong';

  @override
  String get confirmDeleteAccount =>
      'Bạn có chắc muốn xóa tài khoản và dữ liệu? Hành động này không thể hoàn tác.';

  @override
  String get pleaseWait => 'Vui lòng đợi';

  @override
  String get downloading => 'Đang tải xuống';

  @override
  String get unzipping => 'Đang cài đặt';

  @override
  String get completed => 'Hoàn tất';

  @override
  String get preparing => 'Đang chuẩn bị';

  @override
  String get preparingPleaseWait => 'Đang chuẩn bị, vui lòng đợi…';

  @override
  String doNotOperateDuring(String phase) {
    return 'Trong khi \"$phase\", vui lòng giữ nguyên màn hình này.\nKhông chuyển ứng dụng hoặc tắt màn hình.';
  }

  @override
  String get ok => 'OK';

  @override
  String get downloadRequiredTitle => 'Cần tải xuống';

  @override
  String downloadRequiredBody(String modelName) {
    return 'Mô hình nhận dạng giọng nói ($modelName) chưa có trên thiết bị.\nBạn có muốn tải xuống ngay không?';
  }

  @override
  String get download => 'Tải xuống';

  @override
  String get downloadFailedTitle => 'Tải xuống thất bại';

  @override
  String downloadFailedBody(String error) {
    return 'Tải mô hình thất bại: $error';
  }

  @override
  String get successTitle => 'Thành công';

  @override
  String get successBody => 'Mô hình đã được cài đặt thành công.';

  @override
  String get unzipFailedTitle => 'Giải nén thất bại';

  @override
  String get unzipFailedLowSpaceBody =>
      'Giải nén thất bại do không đủ dung lượng lưu trữ. Vui lòng giải phóng dung lượng rồi nhấn \"Giải nén lại\". Tệp đã tải xuống vẫn được giữ nguyên nên không cần tải lại.';

  @override
  String get close => 'Đóng';

  @override
  String get retryUnzip => 'Thử giải nén lại';

  @override
  String get downloadFailedShort =>
      'Tải mô hình thất bại. Vui lòng thử lại sau.';

  @override
  String get modelPrepareFailed =>
      'Cài đặt mô hình nhận dạng giọng nói thất bại. Vui lòng đảm bảo thiết bị còn đủ dung lượng lưu trữ rồi thử lại.';

  @override
  String get retry => 'Thử lại';

  @override
  String get feedbackOpenMailAppFailed => 'Không thể mở ứng dụng email';

  @override
  String get appName => 'Chuyên Tâm Niệm Phật';

  @override
  String feedbackEmailSubject(String app) {
    return '[$app] Phản hồi';
  }

  @override
  String get feedbackEmailBody =>
      'Vấn đề/Góp ý:\n\n(Bạn có thể đính kèm ảnh chụp màn hình)';

  @override
  String get micPermissionTitle => 'Cần quyền micrô';

  @override
  String get micPermissionRationale =>
      'Để đếm số lần niệm Phật, vui lòng bật Micrô trong Cài đặt hệ thống > Niệm Phật.';

  @override
  String get openSettings => 'Mở Cài đặt';

  @override
  String get microphonePermissionDenied => 'Chưa được cấp quyền micrô.';

  @override
  String get bgScreenTitle => 'Hình nền niệm Phật';

  @override
  String get bgUse => 'Dùng';

  @override
  String get bgUpdate => 'Cập nhật';

  @override
  String get bgDelete => 'Xóa';

  @override
  String get bgInUse => 'Đang dùng';

  @override
  String get bgDefault => 'Mặc định';

  @override
  String get bgTypeVideo => 'Video';

  @override
  String get bgTypeImage => 'Hình ảnh';

  @override
  String get bgDeleteTitle => 'Xóa hình nền';

  @override
  String bgDeleteConfirm(String name) {
    return 'Xóa \"$name\"? Bạn có thể tải lại bất cứ lúc nào.';
  }

  @override
  String bgClearedTitle(String name) {
    return 'Hình nền \"$name\" đã bị hệ thống xóa';
  }

  @override
  String get bgClearedBody =>
      'Khi dung lượng lưu trữ thấp hoặc bạn xóa bộ nhớ đệm của ứng dụng, hệ thống có thể xóa các hình nền đã tải để giải phóng dung lượng. Hiện đã chuyển về mặc định — bạn có thể tải lại bất cứ lúc nào.';

  @override
  String get bgOfflineTitle => 'Bạn đang ngoại tuyến';

  @override
  String get bgOfflineBody => 'Kết nối internet để tải hình nền.';

  @override
  String get bgDownloadErrorNetwork =>
      'Không có kết nối internet. Không thể tải hình nền.';

  @override
  String get bgDownloadErrorGeneric =>
      'Tải xuống thất bại. Vui lòng thử lại sau.';

  @override
  String get bgDownloadErrorNotAvailable =>
      'Hiện không thể tải hình nền này. Có thể đã bị gỡ hoặc thay thế.';

  @override
  String get bgSettingSubtitle => 'Tùy chỉnh hình nền niệm Phật';

  @override
  String get langFollowSystem => 'Theo hệ thống';

  @override
  String langFollowSystemWith(String name) {
    return 'Theo hệ thống ($name)';
  }

  @override
  String get cancelling => 'Đang hủy…';

  @override
  String get networkErrorBody =>
      'Kết nối mạng gặp sự cố. Vui lòng kiểm tra kết nối rồi thử lại.';

  @override
  String get timeoutErrorBody =>
      'Hết thời gian kết nối. Mạng có thể không ổn định hoặc máy chủ tạm thời không phản hồi. Vui lòng thử lại sau.';

  @override
  String get serverErrorBody =>
      'Máy chủ phản hồi bất thường. Vui lòng thử lại sau.';

  @override
  String get downloadFailedLowSpaceTitle => 'Không đủ dung lượng lưu trữ';

  @override
  String get downloadFailedLowSpaceBody =>
      'Thiết bị không đủ dung lượng lưu trữ để hoàn tất cài đặt. Vui lòng giải phóng dung lượng rồi nhấn \"Thử lại\".';

  @override
  String get retryAfterFreeSpace => 'Đã giải phóng dung lượng, thử lại';

  @override
  String get retryUnzipAfterFreeSpace =>
      'Đã giải phóng dung lượng, giải nén lại';

  @override
  String get retryUnzipNote =>
      'Đang thử giải nén lại do thiếu dung lượng lưu trữ';

  @override
  String get dedicationTitle => 'Kệ Hồi Hướng';

  @override
  String get dedicationButton => 'Hồi hướng';

  @override
  String get dedicationEdit => 'Chỉnh sửa kệ hồi hướng';

  @override
  String get announcementsTitle => 'Thông báo';

  @override
  String get announcementsSubtitle => 'Xem tin mới nhất';

  @override
  String get announcementsEmpty => 'Chưa có thông báo nào';

  @override
  String get announcementsLinkCopied => 'Đã sao chép liên kết';

  @override
  String get rateTitle => 'Đánh giá & động viên';

  @override
  String get rateSubtitle => 'Để lại đánh giá trên cửa hàng';

  @override
  String get shareTitle => 'Chia sẻ ứng dụng';

  @override
  String get shareSubtitle => 'Giới thiệu cho người thân & bạn bè';

  @override
  String get shareSubject =>
      'Chuyên Tâm Niệm Phật — Ứng dụng đếm niệm Phật miễn phí';

  @override
  String get shareMessage =>
      '\"Chuyên Tâm Niệm Phật\" là ứng dụng đếm niệm Phật miễn phí.\nỨng dụng lắng nghe tiếng niệm Phật của bạn và tự động đếm số câu.\nChỉ cần chuyên tâm niệm Phật — việc đếm cứ để ứng dụng lo!';

  @override
  String get storeActionFailed =>
      'Không thể mở cửa hàng, vui lòng thử lại sau.';
}
