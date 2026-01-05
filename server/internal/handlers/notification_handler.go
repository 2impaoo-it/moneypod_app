package handlers

import (
	"net/http"
	"strconv"

	"github.com/2impaoo-it/moneypod_app/server/internal/repositories"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	repo *repositories.NotificationRepository
}

func NewNotificationHandler(repo *repositories.NotificationRepository) *NotificationHandler {
	return &NotificationHandler{repo: repo}
}

// GetList godoc
// @Summary      Lấy danh sách thông báo
// @Description  Lấy danh sách thông báo của người dùng với phân trang
// @Tags         Notification
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        limit   query  int  false  "Số lượng (mặc định: 20)"
// @Param        offset  query  int  false  "Vị trí bắt đầu (mặc định: 0)"
// @Success      200  {object}  map[string]interface{} "Danh sách thông báo"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /notifications [get]
func (h *NotificationHandler) GetList(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	// Lấy query params cho phân trang
	limitStr := c.DefaultQuery("limit", "20")
	offsetStr := c.DefaultQuery("offset", "0")

	limit, _ := strconv.Atoi(limitStr)
	offset, _ := strconv.Atoi(offsetStr)

	notifications, err := h.repo.GetByUserID(userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi lấy danh sách thông báo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":   notifications,
		"limit":  limit,
		"offset": offset,
	})
}

// GetUnreadCount godoc
// @Summary      Đếm số thông báo chưa đọc
// @Description  Trả về số lượng thông báo chưa đọc của người dùng
// @Tags         Notification
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Số lượng thông báo chưa đọc"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /notifications/unread-count [get]
func (h *NotificationHandler) GetUnreadCount(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	count, err := h.repo.GetUnreadCount(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi đếm thông báo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"unread_count": count})
}

// MarkAsRead godoc
// @Summary      Đánh dấu đã đọc
// @Description  Đánh dấu một thông báo là đã đọc
// @Tags         Notification
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID thông báo"
// @Success      200  {object}  map[string]interface{} "Đánh dấu thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /notifications/{id}/read [put]
func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	notifID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID không hợp lệ"})
		return
	}

	if err := h.repo.MarkAsRead(notifID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi đánh dấu đã đọc"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Đã đánh dấu đã đọc"})
}

// MarkAllAsRead godoc
// @Summary      Đánh dấu tất cả đã đọc
// @Description  Đánh dấu tất cả thông báo là đã đọc
// @Tags         Notification
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Đánh dấu thành công"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /notifications/read-all [put]
func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	if err := h.repo.MarkAllAsRead(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi đánh dấu tất cả đã đọc"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Đã đánh dấu tất cả đã đọc"})
}

// Delete godoc
// @Summary      Xóa thông báo
// @Description  Xóa một thông báo theo ID
// @Tags         Notification
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID thông báo"
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /notifications/{id} [delete]
func (h *NotificationHandler) Delete(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	notifID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID không hợp lệ"})
		return
	}

	if err := h.repo.Delete(notifID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi xóa thông báo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Đã xóa thông báo"})
}

// DeleteAll godoc
// @Summary      Xóa tất cả thông báo
// @Description  Xóa tất cả thông báo của người dùng
// @Tags         Notification
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /notifications/all [delete]
func (h *NotificationHandler) DeleteAll(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	if err := h.repo.DeleteAll(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi xóa tất cả thông báo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Đã xóa tất cả thông báo"})
}

// GET /api/v1/notifications/settings
func (h *NotificationHandler) GetSettings(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	settings, err := h.repo.GetSettings(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi lấy cài đặt thông báo"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": settings})
}

// PUT /api/v1/notifications/settings
func (h *NotificationHandler) UpdateSettings(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	// Lấy settings hiện tại
	settings, err := h.repo.GetSettings(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi lấy cài đặt thông báo"})
		return
	}

	// Bind JSON vào settings
	if err := c.ShouldBindJSON(&settings); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Đảm bảo UserID không bị thay đổi
	settings.UserID = userID

	// Cập nhật
	if err := h.repo.UpdateSettings(settings); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi cập nhật cài đặt"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Cập nhật cài đặt thành công", "data": settings})
}
