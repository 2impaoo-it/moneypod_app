# Hệ thống Notification - App Flutter

## 📦 Files đã tạo/chỉnh sửa

### Models

- ✅ `lib/models/notification.dart` - AppNotification & NotificationSettings models

### Repositories

- ✅ `lib/repositories/notification_repository.dart` - API calls cho notifications

### BLoC

- ✅ `lib/bloc/notification/notification_event.dart` - Events
- ✅ `lib/bloc/notification/notification_state.dart` - States
- ✅ `lib/bloc/notification/notification_bloc.dart` - Business logic

### Screens

- ✅ `lib/screens/notifications_screen.dart` - Danh sách thông báo
- ✅ `lib/screens/notification_settings_screen.dart` - Cài đặt thông báo

### Services

- ✅ `lib/services/fcm_service.dart` - Firebase Cloud Messaging service

### Widgets

- ✅ `lib/widgets/header_widget.dart` - Thêm navigation tới notifications

### Core Files

- ✅ `lib/main.dart` - Import FCM service, khởi tạo background handler, thêm route `/notifications`
- ✅ `lib/services/auth_service.dart` - Thêm fcmToken parameter vào login
- ✅ `lib/bloc/auth/auth_event.dart` - Thêm fcmToken vào AuthLoginRequested
- ✅ `lib/bloc/auth/auth_bloc.dart` - Pass fcmToken khi login
- ✅ `lib/screens/auth/login_screen.dart` - Lấy FCM token và gửi khi login

### Dependencies

- ✅ `pubspec.yaml` - Thêm `firebase_messaging: ^15.0.0` và `timeago: ^3.6.1`

---

## 🎯 Tính năng đã implement

### 1. Hiển thị danh sách thông báo

- List tất cả notifications với icon động theo type
- Hiển thị thời gian (timeago format tiếng Việt)
- Badge cho thông báo chưa đọc
- Pull to refresh
- Swipe to delete

### 2. Quản lý thông báo

- Đánh dấu 1 thông báo đã đọc (tap vào item)
- Đánh dấu tất cả đã đọc (menu)
- Xóa 1 thông báo (swipe)
- Xóa tất cả (menu với confirmation)

### 3. Cài đặt thông báo

13 loại thông báo có thể bật/tắt:

- **Nhóm (6)**: Lời mời, thành viên mới, chi tiêu mới, thanh toán, cập nhật, xóa
- **Tiết kiệm (3)**: Đạt mục tiêu, cột mốc, nhắc nhở
- **Ví (1)**: Cảnh báo số dư thấp
- **Hệ thống (3)**: Đăng nhập mới, bảo trì, nhắc nợ

### 4. Firebase Cloud Messaging (FCM)

- ✅ Initialize FCM khi app khởi động
- ✅ Request notification permissions (iOS)
- ✅ Lấy FCM token và lưu local
- ✅ Gửi FCM token lên server khi login
- ✅ Listen token refresh
- ✅ Handle foreground messages
- ✅ Handle background messages
- ✅ Handle notification tap (khi app đang chạy)
- ✅ Handle initial message (khi app terminated)

---

## 📱 API Endpoints đã tích hợp

```
GET    /notifications              - Lấy danh sách
GET    /notifications/unread-count - Số lượng chưa đọc
PUT    /notifications/:id/read     - Đánh dấu đã đọc
PUT    /notifications/read-all     - Đánh dấu tất cả
DELETE /notifications/:id          - Xóa 1 notification
DELETE /notifications              - Xóa tất cả
GET    /notifications/settings     - Lấy cài đặt
PUT    /notifications/settings     - Cập nhật cài đặt
```

---

## 🚀 Cách sử dụng

### 1. Navigate tới màn hình thông báo

```dart
// Từ bất kỳ đâu trong app
context.push('/notifications');

// Hoặc tap vào icon bell trong header
```

### 2. Load notifications trong widget

```dart
BlocProvider(
  create: (context) {
    final token = getToken(); // từ AuthBloc
    return NotificationBloc(repository: NotificationRepository())
      ..add(NotificationLoadRequested(token));
  },
  child: NotificationsScreen(),
)
```

### 3. Listen notification events

```dart
BlocConsumer<NotificationBloc, NotificationState>(
  listener: (context, state) {
    if (state is NotificationActionSuccess) {
      // Show success message
    }
  },
  builder: (context, state) {
    if (state is NotificationLoaded) {
      // Hiển thị list
    }
  },
)
```

---

## 🔧 Cấu hình Firebase (Cần làm thêm)

### Android (`android/app/google-services.json`)

File đã có sẵn ✅

### iOS

Cần thêm:

1. `ios/Runner/GoogleService-Info.plist`
2. Bật Push Notifications trong Xcode
3. Thêm APNs key vào Firebase Console

### Permissions

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

**Android** - Đã tự động khi dùng firebase_messaging plugin

---

## 📊 Icon mapping theo notification type

```dart
'group_invite' → '👥'
'group_join' → '✅'
'group_expense' → '💸'
'group_settle' → '💰'
'group_expense_update' → '✏️'
'group_expense_delete' → '🗑️'
'savings_goal_reached' → '🎯'
'savings_milestone' → '📈'
'low_balance_alert' → '⚠️'
'new_device_login' → '🔐'
'maintenance' → '🔧'
'debt_reminder' → '⏰'
'savings_reminder' → '🐷'
default → '🔔'
```

---

## 🎨 UI/UX Features

1. **Pull to Refresh** - Vuốt xuống để làm mới
2. **Swipe to Delete** - Vuốt trái để xóa (có confirmation)
3. **Visual Badge** - Chấm xanh cho thông báo chưa đọc
4. **Time Format** - "5 phút trước", "2 giờ trước" (tiếng Việt)
5. **Empty State** - Icon + text khi chưa có thông báo
6. **Error Handling** - Hiển thị lỗi + nút thử lại
7. **Settings Screen** - Toggle switches cho từng loại notification

---

## 🔄 Flow hoàn chỉnh

```
1. User mở app
   ↓
2. FCMService.initialize() được gọi trong main()
   ↓
3. FCM token được lấy và lưu local
   ↓
4. User đăng nhập
   ↓
5. FCM token được gửi kèm request login
   ↓
6. Server lưu FCM token vào database
   ↓
7. Server gửi push notification qua FCM
   ↓
8. App nhận notification:
   - Foreground: Hiển thị trong app
   - Background: Hiển thị system notification
   - Tap notification: Navigate tới màn hình tương ứng
   ↓
9. Notification được lưu vào database (server)
   ↓
10. User mở màn hình Notifications
    ↓
11. App fetch danh sách từ API
    ↓
12. User có thể đọc, xóa, hoặc thay đổi settings
```

---

## ⚡ TODO / Cải tiến tiếp theo

- [ ] Thêm local notifications khi nhận FCM (dùng `flutter_local_notifications`)
- [ ] Navigation logic dựa vào notification type và data
- [ ] Badge count trên app icon (iOS/Android)
- [ ] Sound và vibration tùy chỉnh
- [ ] Rich notifications (ảnh, actions)
- [ ] Notification history với filter
- [ ] Search trong notifications
- [ ] Group notifications theo ngày

---

## 🐛 Debug Tips

### Không nhận được FCM token?

```dart
// Check trong console
debugPrint('FCM Token: ${await FCMService().getCurrentToken()}');
```

### Không nhận push notification?

1. Check Firebase Console > Cloud Messaging > Send test message
2. Verify APNs key (iOS) hoặc Server key (Android)
3. Check permissions: `await FirebaseMessaging.instance.requestPermission()`

### Notification không hiển thị?

1. Check API response trong NotificationRepository
2. Verify token trong headers
3. Check BLoC state transitions

---

**✅ Notification system hoàn thiện và sẵn sàng sử dụng!**
