package handlers

import (
	"net/http"
	"strconv"

	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	repo *repositories.NotificationRepository
}

func NewNotificationHandler(repo *repositories.NotificationRepository) *NotificationHandler {
	return &NotificationHandler{repo: repo}
}

// GET /api/v1/notifications
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

// GET /api/v1/notifications/unread-count
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

// PUT /api/v1/notifications/:id/read
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

// PUT /api/v1/notifications/read-all
func (h *NotificationHandler) MarkAllAsRead(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	if err := h.repo.MarkAllAsRead(userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi đánh dấu tất cả đã đọc"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Đã đánh dấu tất cả đã đọc"})
}

// DELETE /api/v1/notifications/:id
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

// DELETE /api/v1/notifications/all
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
