package services

import (
	"errors"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/config"
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo *repositories.UserRepository
}

func (s *AuthService) GetUserProfile(userID uuid.UUID) (*models.User, error) {
	return s.userRepo.FindByID(userID)
}

func NewAuthService(userRepo *repositories.UserRepository) *AuthService {
	return &AuthService{userRepo: userRepo}
}

func (s *AuthService) Register(email, password, fullName string) error {
	// 1. Kiểm tra email đã tồn tại chưa
	existingUser, _ := s.userRepo.FindByEmail(email)
	if existingUser != nil {
		return errors.New("email đã được sử dụng")
	}

	// 2. Mã hóa mật khẩu (Bcrypt)
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// 3. Tạo User Model
	newUser := &models.User{
		Email:    email,
		Password: string(hashedPassword), // Lưu mật khẩu đã mã hóa
		FullName: fullName,
	}

	// 4. Gọi Repo để lưu
	return s.userRepo.CreateUser(newUser)
}

// Login kiểm tra pass và trả về Token
func (s *AuthService) Login(email, password string) (string, error) {
	// 1. Tìm user theo email
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		return "", errors.New("email hoặc mật khẩu không đúng") // Đừng báo cụ thể sai email hay sai pass để tránh hacker dò
	}

	// 2. So sánh mật khẩu (Hash vs Plain)
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return "", errors.New("email hoặc mật khẩu không đúng")
	}

	// 3. Tạo JWT Token - Sử dụng secret key từ config
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": user.ID,                               // Subject: ID người dùng
		"exp": time.Now().Add(time.Hour * 72).Unix(), // Hết hạn sau 3 ngày
	})

	// 4. Ký tên (Sign) token
	tokenString, err := token.SignedString([]byte(config.AppConfig.JWTSecretKey))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func (s *AuthService) LinkPhoneNumber(userID uuid.UUID, phone string) error {
	// Kiểm tra xem số này đã có ai dùng chưa
	existingUser, _ := s.userRepo.FindByPhone(phone)
	if existingUser != nil && existingUser.ID != userID {
		return errors.New("số điện thoại này đã được liên kết với tài khoản khác")
	}
	return s.userRepo.UpdatePhone(userID, phone)
}

// Hàm cập nhật FCM Token (Thêm vào struct AuthService)
func (s *AuthService) UpdateFCMToken(userID uuid.UUID, token string) error {
	// Gọi xuống Repo để update vào database
	return s.userRepo.UpdateFCMToken(userID, token)
}

// Logic cập nhật tên hiển thị
func (s *AuthService) UpdateUserInfo(userID uuid.UUID, fullName string) error {
	// (Optional) Bạn có thể validate tên (ví dụ: không được để trống, không quá dài) ở đây
	if fullName == "" {
		return errors.New("tên hiển thị không được để trống")
	}
	return s.userRepo.UpdateFullName(userID, fullName)
}

// Logic cập nhật Avatar
func (s *AuthService) UpdateAvatar(userID uuid.UUID, avatarURL string) error {
	if avatarURL == "" {
		return errors.New("đường dẫn ảnh không được để trống")
	}
	return s.userRepo.UpdateAvatar(userID, avatarURL)
}
