package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/server/internal/services"
	"github.com/2impaoo-it/moneypod_app/server/internal/utils"
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

// Register godoc
// @Summary      Đăng ký tài khoản mới
// @Description  Tạo tài khoản người dùng mới với email, mật khẩu và tên đầy đủ
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        request body RegisterRequest true "Thông tin đăng ký"
// @Success      201  {object}  map[string]interface{} "Đăng ký thành công"
// @Failure      400  {object}  map[string]interface{} "Lỗi dữ liệu đầu vào hoặc email đã tồn tại"
// @Router       /register [post]
func (h *AuthHandler) Register(c *gin.Context) {
	var req RegisterRequest

	// 1. Validate dữ liệu đầu vào (phải có email, pass > 6 ký tự...)
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 🔒 SECURITY: Validate email format
	if err := utils.ValidateEmail(req.Email); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 🔒 SECURITY: Validate password strength
	if err := utils.ValidatePassword(req.Password); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 🔒 SECURITY: Sanitize full name
	req.FullName = utils.SanitizeInput(req.FullName)

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

// Login godoc
// @Summary      Đăng nhập hệ thống
// @Description  Xác thực email/password và trả về JWT Token
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        request body LoginRequest true "Thông tin đăng nhập"
// @Success      200  {object}  map[string]interface{} "Đăng nhập thành công, trả về Token"
// @Failure      400  {object}  map[string]interface{} "Lỗi dữ liệu đầu vào"
// @Failure      401  {object}  map[string]interface{} "Sai mật khẩu hoặc email"
// @Router       /login [post]
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

// GetProfile godoc
// @Summary      Lấy thông tin profile người dùng
// @Description  Trả về thông tin chi tiết của người dùng hiện tại
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Thông tin người dùng"
// @Failure      401  {object}  map[string]interface{} "Không có quyền truy cập"
// @Failure      404  {object}  map[string]interface{} "Người dùng không tồn tại"
// @Router       /profile [get]
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

// LinkPhone godoc
// @Summary      Liên kết số điện thoại
// @Description  Liên kết số điện thoại với tài khoản người dùng
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body LinkPhoneReq true "Số điện thoại cần liên kết"
// @Success      200  {object}  map[string]interface{} "Liên kết thành công"
// @Failure      400  {object}  map[string]interface{} "Lỗi dữ liệu đầu vào hoặc số điện thoại đã tồn tại"
// @Router       /link-phone [post]
func (h *AuthHandler) LinkPhone(c *gin.Context) {
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

// UpdateProfile godoc
// @Summary      Cập nhật thông tin profile
// @Description  Cập nhật tên đầy đủ của người dùng
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body UpdateProfileReq true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /profile [put]
func (h *AuthHandler) UpdateProfile(c *gin.Context) {
	// 1. Lấy ID user từ Token
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

	// 2. Parse dữ liệu
	var req UpdateProfileReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service
	err = h.authService.UpdateUserInfo(userID, req.FullName)
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

// UpdateAvatar godoc
// @Summary      Cập nhật ảnh đại diện
// @Description  Cập nhật URL ảnh đại diện của người dùng
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body UpdateAvatarReq true "URL ảnh đại diện"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /profile/avatar [put]
func (h *AuthHandler) UpdateAvatar(c *gin.Context) {
	// 1. Lấy ID user
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

	// 2. Parse dữ liệu
	var req UpdateAvatarReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service
	err = h.authService.UpdateAvatar(userID, req.AvatarURL)
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

// ChangePassword godoc
// @Summary      Đổi mật khẩu
// @Description  Thay đổi mật khẩu của người dùng (yêu cầu mật khẩu cũ)
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body ChangePasswordRequest true "Mật khẩu cũ và mật khẩu mới"
// @Success      200  {object}  map[string]interface{} "Đổi mật khẩu thành công"
// @Failure      400  {object}  map[string]interface{} "Mật khẩu cũ sai hoặc dữ liệu không hợp lệ"
// @Router       /change-password [put]
func (h *AuthHandler) ChangePassword(c *gin.Context) {
	// 1. Lấy ID user
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

	// 2. Parse dữ liệu
	var req ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// 3. Gọi Service
	err = h.authService.ChangePassword(userID, req.OldPassword, req.NewPassword)
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

// ForgotPassword godoc
// @Summary      Quên mật khẩu
// @Description  Gửi mật khẩu tạm thời qua email khi quên mật khẩu
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Param        request body ForgotPasswordRequest true "Email đăng ký"
// @Success      200  {object}  map[string]interface{} "Gửi mật khẩu tạm thời thành công"
// @Failure      400  {object}  map[string]interface{} "Email không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi hệ thống"
// @Router       /forgot-password [post]
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

// UpdateFCMToken godoc
// @Summary      Cập nhật FCM Token
// @Description  Cập nhật Firebase Cloud Messaging token cho người dùng để nhận thông báo push
// @Tags         Auth
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body UpdateFCMTokenRequest true "FCM Token từ Firebase"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /fcm-token [put]
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
