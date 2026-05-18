import 'package:flutter/foundation.dart';

/// Dùng để các màn hình tự refresh khi có dữ liệu mới.
/// Ví dụ: AddMeal lưu thành công -> AppEvents.notifyDataChanged();
/// Home/Report đang lắng nghe sẽ tự gọi API lại.
class AppEvents {
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  static void notifyDataChanged() {
    dataVersion.value++;
  }
}
