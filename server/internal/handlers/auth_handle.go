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
