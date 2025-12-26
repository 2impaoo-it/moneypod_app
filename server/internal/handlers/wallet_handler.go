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
