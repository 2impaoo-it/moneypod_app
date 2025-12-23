package handlers

import (
	"net/http"

	"github.com/2impaoo-it/MoneyPod_Backend/internal/services"
	"github.com/gin-gonic/gin"
)

type WalletHandler struct {
	walletService *services.WalletService
}

func NewWalletHandler(walletService *services.WalletService) *WalletHandler {
	return &WalletHandler{walletService: walletService}
}

// Struct hứng dữ liệu JSON
type CreateWalletRequest struct {
	Name    string  `json:"name" binding:"required"`
	Balance float64 `json:"balance"` // Có thể không nhập, mặc định là 0
}

func (h *WalletHandler) CreateWallet(c *gin.Context) {
	// 1. Lấy UserID từ Token (Do Middleware gắn vào)
	// Vì c.Get trả về interface{}, cần ép kiểu về float64 rồi về uint (do JWT lưu số dạng float)
	userIDFloat, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Không xác định được người dùng"})
		return
	}
	userID := uint(userIDFloat.(float64)) // Ép kiểu

	// 2. Parse JSON
	var req CreateWalletRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 3. Gọi Service
	err := h.walletService.CreateWallet(userID, req.Name, req.Balance)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Tạo ví thành công!"})
}

func (h *WalletHandler) GetList(c *gin.Context) {
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	wallets, err := h.walletService.GetMyWallets(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": wallets})
}
