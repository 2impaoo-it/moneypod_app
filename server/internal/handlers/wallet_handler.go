package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
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

// UpdateWallet cập nhật tên ví, loại tiền tệ
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

// DeleteWallet xóa ví (chỉ khi số dư = 0)
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

// TransferBetweenWallets - Handler chuyển tiền giữa các ví
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
