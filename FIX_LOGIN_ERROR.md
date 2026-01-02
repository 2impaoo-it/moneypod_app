# 🔧 Fix: Lỗi Kết Nối Khi Đăng Nhập

## ⚠️ Vấn Đề

Sau khi thêm tính năng **Insight thông minh**, app báo lỗi "Không thể kết nối tới server" khi đăng nhập, mặc dù server vẫn chạy bình thường.

## 🔍 Nguyên Nhân

1. **Backend Insight Service khởi tạo lỗi** nếu không có `GEMINI_API_KEY`
2. **Insight API trả về lỗi 500** → DioClient tự động hiển thị dialog lỗi
3. **Dialog lỗi block toàn bộ app**, người dùng không thể sử dụng

## ✅ Giải Pháp Đã Áp Dụng

### 1. Backend: Optional Insight Service

**File**: `server/cmd/server/main.go`

```go
// ✅ Insight Service (sử dụng Gemini) - BÂY GIỜ LÀ OPTIONAL
var insightService *services.InsightService
if config.AppConfig.GeminiAPIKey != "" {
    insightService, err = services.NewInsightService(db.DB, config.AppConfig.GeminiAPIKey)
    if err != nil {
        log.Println("⚠️ Cảnh báo: Không thể khởi tạo Insight Service:", err)
        log.Println("   Tính năng Insight sẽ không khả dụng.")
        insightService = nil
    } else {
        log.Println("✅ Đã khởi tạo Insight Service!")
    }
} else {
    log.Println("⚠️ Cảnh báo: Không có GEMINI_API_KEY - Tính năng Insight sẽ không khả dụng.")
}
```

**Thay đổi**:

- ❌ Trước: `log.Fatal()` → Server crash nếu không có API key
- ✅ Sau: `log.Println()` → Server vẫn chạy, insight không khả dụng

---

### 2. Backend: Handler Kiểm Tra Service

**File**: `server/internal/handlers/insight_handler.go`

```go
func (h *InsightHandler) GetMonthlyInsight(c *gin.Context) {
    // Kiểm tra service có khả dụng không
    if h.service == nil {
        c.JSON(http.StatusServiceUnavailable, gin.H{
            "error":   "Tính năng Insight tạm thời không khả dụng",
            "insight": "Tính năng này đang được cập nhật. Vui lòng thử lại sau.",
        })
        return
    }
    // ... rest of code
}
```

**Thay đổi**:

- Trả về status `503 Service Unavailable` thay vì `500 Internal Server Error`
- Có message thân thiện cho user

---

### 3. Flutter: Không Hiển Thị Dialog Lỗi Cho Insight

**File**: `app/lib/utils/dio_client.dart`

```dart
// Handle server error (500+)
if (error.response?.statusCode != null &&
    error.response!.statusCode! >= 500) {
  // Không hiển thị dialog lỗi cho insights API
  final uri = error.requestOptions.uri.toString();
  final isInsightApi = uri.contains('/insights/');

  if (!isInsightApi && navContext != null && navContext.mounted) {
    _showServerErrorDialog(navContext);
  }
}
```

**Thay đổi**:

- ❌ Trước: Mọi lỗi 500+ đều hiển thị dialog
- ✅ Sau: **KHÔNG** hiển thị dialog cho `/insights/` API

---

### 4. Flutter: Better Error Handling

**File**: `app/lib/services/insight_service.dart`

```dart
} on DioException catch (e) {
  print('❌ [InsightService] DioException: ${e.response?.statusCode} - ${e.message}');

  // Xử lý các loại lỗi khác nhau
  if (e.response?.statusCode == 404) {
    return 'Tính năng insight đang được cập nhật.';
  } else if (e.response?.statusCode == 500) {
    return 'Insight tạm thời không khả dụng.';
  } else if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return 'Insight đang được tạo, vui lòng chờ...';
  }

  return 'Không thể tải insight lúc này.';
}
```

**Thay đổi**:

- Xử lý chi tiết từng loại lỗi
- Trả về message thân thiện thay vì throw exception
- Thêm timeout riêng: `receiveTimeout: 10s`, `sendTimeout: 5s`

---

### 5. Flutter: Xử Lý Response 503

**File**: `app/lib/services/insight_service.dart`

```dart
if (response.statusCode == 200) {
  final insight = response.data['insight'] as String? ??
      'Chưa có đủ dữ liệu để phân tích.';
  await _cacheInsight(cacheKey, insight);
  return insight;
} else if (response.statusCode == 503) {
  // Service unavailable
  return response.data['insight'] as String? ??
      'Tính năng Insight đang được cập nhật.';
}
```

---

## 🎯 Kết Quả

### Trước Khi Fix:

❌ Login → Load dashboard → Insight gọi API lỗi 500 → Dialog lỗi xuất hiện → User bị block

### Sau Khi Fix:

✅ Login → Load dashboard → Insight gọi API (có thể lỗi) → Hiển thị message thân thiện → User vẫn dùng app bình thường

### Các Tình Huống:

| Tình Huống                | Trước                   | Sau                                           |
| ------------------------- | ----------------------- | --------------------------------------------- |
| Không có `GEMINI_API_KEY` | 💥 Server crash         | ✅ Server chạy, insight không khả dụng        |
| Insight API lỗi 500       | ❌ Dialog lỗi xuất hiện | ✅ Hiển thị "Insight tạm thời không khả dụng" |
| Insight API timeout       | ❌ Dialog lỗi xuất hiện | ✅ Hiển thị "Insight đang được tạo..."        |
| Dashboard API lỗi 500     | ❌ Dialog lỗi xuất hiện | ❌ Vẫn hiển thị dialog (đúng behavior)        |

---

## 🚀 Cách Test

### 1. Test Không Có Gemini API Key

```bash
# Trong file server/.env
# Comment hoặc xóa dòng GEMINI_API_KEY
# GEMINI_API_KEY=

# Chạy server
cd server
go run cmd/server/main.go
```

**Expected**:

```
⚠️ Cảnh báo: Không có GEMINI_API_KEY - Tính năng Insight sẽ không khả dụng.
🚀 Server is running on port 8080
```

**Trong App**:

- Login thành công ✅
- Dashboard load bình thường ✅
- Insight hiển thị: "Tính năng này đang được cập nhật. Vui lòng thử lại sau." ✅

---

### 2. Test Có Gemini API Key Hợp Lệ

```bash
# Trong file server/.env
GEMINI_API_KEY=your_valid_api_key_here

# Chạy server
cd server
go run cmd/server/main.go
```

**Expected**:

```
✅ Đã khởi tạo Insight Service!
🚀 Server is running on port 8080
```

**Trong App**:

- Login thành công ✅
- Dashboard load bình thường ✅
- Insight gọi Gemini API và hiển thị insight thực ✅
- Lần sau load từ cache ✅

---

### 3. Test Dashboard API Lỗi (Đảm Bảo Vẫn Hiển thị Dialog)

Stop server → Login app

**Expected**:

- ❌ Dialog "Lỗi kết nối" xuất hiện (đúng vì dashboard là critical API)

---

## 📝 Best Practice

### Khi Nào Hiển Thị Dialog Lỗi?

✅ **NÊN hiển thị**:

- Dashboard API lỗi (critical data)
- Auth API lỗi (login/register)
- Wallet/Transaction API lỗi (core features)

❌ **KHÔNG NÊN hiển thị**:

- Insight API lỗi (optional feature)
- Notification API lỗi (không quan trọng)
- Analytics API lỗi (background)

### Error Handling Pattern

```dart
// 1. Catch lỗi
} on DioException catch (e) {
  // 2. Log chi tiết
  print('❌ Error: ${e.response?.statusCode}');

  // 3. Xử lý theo loại lỗi
  if (e.response?.statusCode == 404) {
    return 'Feature not available';
  }

  // 4. Trả về message thân thiện
  return 'Unable to load data';
}
```

---

## ✅ Checklist

- [x] Backend: Insight service không bắt buộc
- [x] Backend: Handler kiểm tra service null
- [x] Backend: Trả về status 503 thay vì 500
- [x] Flutter: Không hiển thị dialog lỗi cho insight API
- [x] Flutter: Better error handling với timeout
- [x] Flutter: Xử lý response 503
- [x] Test: Server chạy không có API key
- [x] Test: Login thành công với/không có insight
- [x] Test: Dashboard API lỗi vẫn hiển thị dialog

---

## 🎉 Kết Luận

Lỗi đã được fix hoàn toàn! App bây giờ:

- ✅ **Robust**: Không crash khi insight không khả dụng
- ✅ **User-friendly**: Hiển thị message thân thiện thay vì dialog lỗi
- ✅ **Flexible**: Backend chạy được với hoặc không có Gemini API key

Insight là **optional feature**, không nên làm block core functionality của app! 🚀
