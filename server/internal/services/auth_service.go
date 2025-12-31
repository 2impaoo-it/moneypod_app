package services

import (
	"errors"
	"fmt"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/config"
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	userRepo     *repositories.UserRepository
	emailService EmailService
	notifRepo    *repositories.NotificationRepository
}

func (s *AuthService) GetUserProfile(userID uuid.UUID) (*models.User, error) {
	return s.userRepo.FindByID(userID)
}

func NewAuthService(userRepo *repositories.UserRepository, emailService EmailService, notifRepo *repositories.NotificationRepository) *AuthService {
	return &AuthService{
		userRepo:     userRepo,
		emailService: emailService,
		notifRepo:    notifRepo,
	}
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
	if err := s.userRepo.CreateUser(newUser); err != nil {
		return err
	}

	// 5. Tạo notification settings mặc định cho user mới
	if s.notifRepo != nil {
		s.notifRepo.CreateDefaultSettings(newUser.ID)
	}

	return nil
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

// ChangePassword: Đổi mật khẩu
func (s *AuthService) ChangePassword(userID uuid.UUID, oldPassword, newPassword string) error {
	// 1. Lấy thông tin user
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return errors.New("không tìm thấy người dùng")
	}

	// 2. Kiểm tra mật khẩu cũ
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(oldPassword))
	if err != nil {
		return errors.New("mật khẩu cũ không đúng")
	}

	// 3. Validate mật khẩu mới
	if len(newPassword) < 6 {
		return errors.New("mật khẩu mới phải có ít nhất 6 ký tự")
	}

	// 4. Mã hóa mật khẩu mới
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// 5. Cập nhật vào database
	return s.userRepo.UpdatePassword(userID, string(hashedPassword))
}

// ForgotPassword: Gửi email reset password với mật khẩu tạm thời
// Production-ready version với email service integration
// Note: Trong production thực tế, bạn có thể cải thiện thêm:
// - Tạo reset token và lưu vào DB với thời gian hết hạn
// - Gửi email với link reset có token thay vì gửi trực tiếp mật khẩu
// - Tạo API verify token và reset password
func (s *AuthService) ForgotPassword(email string) error {
	// 1. Tìm user theo email
	user, err := s.userRepo.FindByEmail(email)
	if err != nil {
		// Không nên báo cụ thể email không tồn tại để tránh hacker dò
		// Vẫn trả về success để không lộ thông tin
		// Nhưng vẫn gửi email service để không lộ timing attack
		_ = s.emailService.SendPasswordResetEmail(email, "")
		return nil
	}

	// 2. Tạo password ngẫu nhiên an toàn
	temporaryPassword, err := generateRandomPassword(12)
	if err != nil {
		return errors.New("không thể tạo mật khẩu tạm thời")
	}

	// Thêm ký tự đặc biệt để đảm bảo độ mạnh
	temporaryPassword = "Temp" + temporaryPassword + "!@"

	// 3. Mã hóa password mới
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(temporaryPassword), bcrypt.DefaultCost)
	if err != nil {
		return errors.New("không thể mã hóa mật khẩu")
	}

	// 4. Cập nhật password
	err = s.userRepo.UpdatePassword(user.ID, string(hashedPassword))
	if err != nil {
		return err
	}

	// 5. Gửi email thông báo password mới
	err = s.emailService.SendPasswordResetEmail(email, temporaryPassword)
	if err != nil {
		// Log lỗi nhưng vẫn coi như thành công để không lộ thông tin
		fmt.Printf("⚠️  Lỗi khi gửi email đến %s: %v\n", email, err)
	}

	// Log để debug (trong production nên dùng proper logging service)
	fmt.Printf("✅ Đã reset mật khẩu cho email: %s\n", email)

	return nil
}
