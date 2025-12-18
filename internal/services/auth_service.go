package services

import (
	"errors"
	"time"

	"github.com/2impaoo-it/MoneyPod_Backend/internal/models"
	"github.com/2impaoo-it/MoneyPod_Backend/internal/repositories"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo *repositories.UserRepository
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

// Secret Key để ký tên vào Token (Sau này nên để trong biến môi trường)
var jwtSecretKey = []byte("moneypod_bi_mat_khong_the_bat_mi")

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

	// 3. Tạo JWT Token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": user.ID,                           // Subject: ID người dùng
		"exp": time.Now().Add(time.Hour * 72).Unix(), // Hết hạn sau 3 ngày
	})

	// 4. Ký tên (Sign) token
	tokenString, err := token.SignedString(jwtSecretKey)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}