package repositories

import (
	"github.com/2impaoo-it/MoneyPod_Backend/internal/models"
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