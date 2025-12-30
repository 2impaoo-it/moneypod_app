package repositories

import (
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

// CreateUser lưu user mới vào database
func (r *UserRepository) CreateUser(user *models.User) error {
	return r.db.Create(user).Error
}

// FindByEmail kiểm tra xem email đã tồn tại chưa
func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// UpdateFCMToken cập nhật token FCM cho user
func (r *UserRepository) UpdateFCMToken(userID uuid.UUID, token string) error {
	return r.db.Model(&models.User{}).Where("id = ?", userID).Update("fcm_token", token).Error
}

// FindByID tìm user theo ID
func (r *UserRepository) FindByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	err := r.db.Where("id = ?", id).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

// GetByUserID lấy thông tin user theo user ID
func (r *UserRepository) GetByUserID(userID uuid.UUID) (*models.User, error) {
	var user models.User
	err := r.db.Where("id = ?", userID).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}
