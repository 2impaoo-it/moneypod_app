package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// Struct để hứng dữ liệu JSON gửi lên
type RegisterRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=6"`
	FullName string `json:"full_name" binding:"required"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest

	// 1. Validate dữ liệu đầu vào (phải có email, pass > 6 ký tự...)
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 2. Gọi Service xử lý
	err := h.authService.Register(req.Email, req.Password, req.FullName)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Đăng ký thành công!"})
}

// Struct để hứng JSON đăng nhập
type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req LoginRequest

	// 1. Validate input
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu không hợp lệ"})
		return
	}

	// 2. Gọi Service
	token, err := h.authService.Login(req.Email, req.Password)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()}) // 401 Unauthorized
		return
	}

	// 3. Trả về Token
	c.JSON(http.StatusOK, gin.H{
		"message": "Đăng nhập thành công",
		"token":   token,
	})
}

func (h *AuthHandler) GetProfile(c *gin.Context) {
	// 1. Lấy UserID từ context (được Middleware Auth gán vào dưới dạng string)
	idVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Không xác thực được người dùng"})
		return
	}

	// 2. Parse từ String sang UUID
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID người dùng lỗi format"})
		return
	}

	// 3. Gọi Service lấy thông tin
	user, err := h.authService.GetUserProfile(userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Người dùng không tồn tại"})
		return
	}

	// 4. Trả về Client
	c.JSON(http.StatusOK, gin.H{"data": user})
}

type LinkPhoneReq struct {
	Phone string `json:"phone" binding:"required"`
}

func (h *AuthHandler) LinkPhone(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	var req LinkPhoneReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	if err := h.authService.LinkPhoneNumber(userID, req.Phone); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã liên kết số điện thoại thành công"})
}

// Struct nhận dữ liệu
type UpdateProfileReq struct {
	FullName string `json:"full_name" binding:"required"`
}

// PUT /api/v1/profile
func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	// 1. Lấy ID user từ Token
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	// 2. Parse dữ liệu
	var req UpdateProfileReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service
	err := h.authService.UpdateUserInfo(userID, req.FullName)
	if err != nil {
		c.JSON(500, gin.H{"error": "Lỗi cập nhật: " + err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Cập nhật thông tin thành công", "full_name": req.FullName})
}

// Struct nhận dữ liệu
type UpdateAvatarReq struct {
	AvatarURL string `json:"avatar_url" binding:"required"`
}

// PUT /api/v1/profile/avatar
func (h *AuthHandler) UpdateAvatar(c *gin.Context) {
	// 1. Lấy ID user
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	// 2. Parse dữ liệu
	var req UpdateAvatarReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service
	err := h.authService.UpdateAvatar(userID, req.AvatarURL)
	if err != nil {
		c.JSON(500, gin.H{"error": "Lỗi cập nhật: " + err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Cập nhật ảnh đại diện thành công", "avatar_url": req.AvatarURL})
}

// ChangePassword: PUT /api/v1/change-password
type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=6"`
}

func (h *AuthHandler) ChangePassword(c *gin.Context) {
	// 1. Lấy ID user
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	// 2. Parse dữ liệu
	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service
	err := h.authService.ChangePassword(userID, req.OldPassword, req.NewPassword)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đổi mật khẩu thành công!"})
}

// ForgotPassword: POST /api/v1/forgot-password
type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

func (h *AuthHandler) ForgotPassword(c *gin.Context) {
	// 1. Parse dữ liệu
	var req ForgotPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 2. Gọi Service
	result, err := h.authService.ForgotPassword(req.Email)
	if err != nil {
		c.JSON(500, gin.H{"error": "Lỗi hệ thống: " + err.Error()})
		return
	}

	// Trả về kết quả bao gồm temporary password nếu có
	c.JSON(200, result)
}

// UpdateFCMTokenRequest request body cho cập nhật FCM token
type UpdateFCMTokenRequest struct {
	FCMToken string `json:"fcm_token" binding:"required"`
}

// UpdateFCMToken cập nhật FCM token cho user
func (h *AuthHandler) UpdateFCMToken(c *gin.Context) {
	// 1. Lấy UserID từ context
	idVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Không xác thực được người dùng"})
		return
	}

	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID người dùng lỗi format"})
		return
	}

	// 2. Parse request body
	var req UpdateFCMTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service cập nhật
	err = h.authService.UpdateFCMToken(userID, req.FCMToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi cập nhật FCM token: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Cập nhật FCM token thành công",
	})
}
