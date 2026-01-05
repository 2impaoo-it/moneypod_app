package repositories

import (
	"time"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationRepository struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

// Create: Tạo thông báo mới
func (r *NotificationRepository) Create(notification *models.Notification) error {
	return r.db.Create(notification).Error
}

// GetByUserID: Lấy danh sách thông báo của user (phân trang)
func (r *NotificationRepository) GetByUserID(userID uuid.UUID, limit, offset int) ([]models.Notification, error) {
	var notifications []models.Notification
	err := r.db.Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&notifications).Error
	return notifications, err
}

// GetUnreadCount: Đếm số thông báo chưa đọc
func (r *NotificationRepository) GetUnreadCount(userID uuid.UUID) (int64, error) {
	var count int64
	err := r.db.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Count(&count).Error
	return count, err
}

// MarkAsRead: Đánh dấu một thông báo đã đọc
func (r *NotificationRepository) MarkAsRead(notificationID uuid.UUID, userID uuid.UUID) error {
	now := time.Now()
	return r.db.Model(&models.Notification{}).
		Where("id = ? AND user_id = ?", notificationID, userID).
		Updates(map[string]interface{}{
			"is_read": true,
			"read_at": now,
		}).Error
}

// MarkAllAsRead: Đánh dấu tất cả thông báo đã đọc
func (r *NotificationRepository) MarkAllAsRead(userID uuid.UUID) error {
	now := time.Now()
	return r.db.Model(&models.Notification{}).
		Where("user_id = ? AND is_read = ?", userID, false).
		Updates(map[string]interface{}{
			"is_read": true,
			"read_at": now,
		}).Error
}

// Delete: Xóa thông báo
func (r *NotificationRepository) Delete(notificationID uuid.UUID, userID uuid.UUID) error {
	return r.db.Where("id = ? AND user_id = ?", notificationID, userID).
		Delete(&models.Notification{}).Error
}

// DeleteAll: Xóa tất cả thông báo của user
func (r *NotificationRepository) DeleteAll(userID uuid.UUID) error {
	return r.db.Where("user_id = ?", userID).Delete(&models.Notification{}).Error
}

// === NOTIFICATION SETTINGS ===

// GetSettings: Lấy cài đặt thông báo của user
func (r *NotificationRepository) GetSettings(userID uuid.UUID) (*models.NotificationSetting, error) {
	var settings models.NotificationSetting
	err := r.db.Where("user_id = ?", userID).First(&settings).Error
	if err == gorm.ErrRecordNotFound {
		// Nếu chưa có settings, tạo mặc định
		settings = models.NotificationSetting{
			UserID:             userID,
			GroupExpense:       true,
			GroupMemberAdded:   true,
			GroupMemberRemoved: true,
			GroupDeleted:       true,
			ExpenseUpdated:     true,
			ExpenseDeleted:     true,
			TransactionCreated: true,
			LowBalance:         true,
			BudgetExceeded:     true,
			DailySummary:       false,
			SavingsGoalReached: true,
			SavingsReminder:    true,
			SavingsProgress:    true,
			SystemAnnouncement: true,
			SecurityAlert:      true,
			AppUpdate:          true,
			Maintenance:        true,
		}
		r.db.Create(&settings)
		return &settings, nil
	}
	return &settings, err
}

// UpdateSettings: Cập nhật cài đặt thông báo
func (r *NotificationRepository) UpdateSettings(settings *models.NotificationSetting) error {
	return r.db.Save(settings).Error
}

// CreateDefaultSettings: Tạo settings mặc định khi user đăng ký
func (r *NotificationRepository) CreateDefaultSettings(userID uuid.UUID) error {
	settings := models.NotificationSetting{
		UserID:             userID,
		GroupExpense:       true,
		GroupMemberAdded:   true,
		GroupMemberRemoved: true,
		GroupDeleted:       true,
		ExpenseUpdated:     true,
		ExpenseDeleted:     true,
		TransactionCreated: true,
		LowBalance:         true,
		BudgetExceeded:     true,
		DailySummary:       false,
		SavingsGoalReached: true,
		SavingsReminder:    true,
		SavingsProgress:    true,
		SystemAnnouncement: true,
		SecurityAlert:      true,
		AppUpdate:          true,
		Maintenance:        true,
	}
	return r.db.Create(&settings).Error
}
