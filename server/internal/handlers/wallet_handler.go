package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/server/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid" // <--- Import thêm
)

type WalletHandler struct {
	walletService *services.WalletService
}

func NewWalletHandler(walletService *services.WalletService) *WalletHandler {
	return &WalletHandler{walletService: walletService}
}

type CreateWalletRequest struct {
	Name    string  `json:"name" binding:"required"`
	Balance float64 `json:"balance"`
}

// CreateWallet godoc
// @Summary      Tạo ví mới
// @Description  Tạo một ví mới với tên và số dư ban đầu
// @Tags         Wallet
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body CreateWalletRequest true "Thông tin ví"
// @Success      201  {object}  map[string]interface{} "Tạo ví thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /wallets [post]
func (h *WalletHandler) CreateWallet(c *gin.Context) {
	// 1. Lấy UserID từ Token (Đã chuyển sang UUID)
	idVal, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Không xác định được người dùng"})
		return
	}

	// Ép kiểu sang chuỗi rồi Parse về UUID
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID không hợp lệ"})
		return
	}

	var req CreateWalletRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.walletService.CreateWallet(userID, req.Name, req.Balance)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Tạo ví thành công!"})
}

// GetList godoc
// @Summary      Lấy danh sách ví
// @Description  Lấy tất cả các ví của người dùng
// @Tags         Wallet
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Danh sách ví"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /wallets [get]
func (h *WalletHandler) GetList(c *gin.Context) {
	// 1. Lấy UserID (Logic giống hệt ở trên)
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID không hợp lệ"})
		return
	}

	wallets, err := h.walletService.GetMyWallets(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": wallets})
}

type UpdateWalletRequest struct {
	Name     string `json:"name"`
	Currency string `json:"currency"`
}

// UpdateWallet godoc
// @Summary      Cập nhật ví
// @Description  Cập nhật tên ví và loại tiền tệ
// @Tags         Wallet
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID ví"
// @Param        request body UpdateWalletRequest true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /wallets/{id} [put]
func (h *WalletHandler) UpdateWallet(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID không hợp lệ"})
		return
	}

	walletID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ví không hợp lệ"})
		return
	}

	var req UpdateWalletRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.walletService.UpdateWallet(walletID, userID, req.Name, req.Currency)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Cập nhật ví thành công!"})
}

// DeleteWallet godoc
// @Summary      Xóa ví
// @Description  Xóa một ví (chỉ khi số dư = 0)
// @Tags         Wallet
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID ví"
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      400  {object}  map[string]interface{} "Không thể xóa ví còn tiền"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /wallets/{id} [delete]
func (h *WalletHandler) DeleteWallet(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID không hợp lệ"})
		return
	}

	walletID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ví không hợp lệ"})
		return
	}

	err = h.walletService.DeleteWallet(walletID, userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Xóa ví thành công!"})
}

type TransferRequest struct {
	FromWalletID string  `json:"from_wallet_id" binding:"required"`
	ToWalletID   string  `json:"to_wallet_id" binding:"required"`
	Amount       float64 `json:"amount" binding:"required,gt=0"`
	Note         string  `json:"note"`
}

// TransferBetweenWallets godoc
// @Summary      Chuyển tiền giữa các ví
// @Description  Chuyển tiền từ ví này sang ví khác của cùng người dùng
// @Tags         Wallet
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body TransferRequest true "Thông tin chuyển tiền"
// @Success      200  {object}  map[string]interface{} "Chuyển tiền thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ hoặc số dư không đủ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /wallets/transfer [post]
func (h *WalletHandler) TransferBetweenWallets(c *gin.Context) {
	// 1. Lấy UserID từ token
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID không hợp lệ"})
		return
	}

	// 2. Parse request body
	var req TransferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 3. Parse UUID
	fromWalletID, err := uuid.Parse(req.FromWalletID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ví nguồn không hợp lệ"})
		return
	}

	toWalletID, err := uuid.Parse(req.ToWalletID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ví đích không hợp lệ"})
		return
	}

	// 4. Gọi service để chuyển tiền
	err = h.walletService.TransferBetweenWallets(userID, fromWalletID, toWalletID, req.Amount, req.Note)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Chuyển tiền thành công!"})
}
