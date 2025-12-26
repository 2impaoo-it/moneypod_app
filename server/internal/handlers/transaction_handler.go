package handlers

import (
	"net/http"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
)

type TransactionHandler struct {
	service *services.TransactionService
}

func NewTransactionHandler(service *services.TransactionService) *TransactionHandler {
	return &TransactionHandler{service: service}
}

type CreateTransactionRequest struct {
	WalletID uint    `json:"wallet_id" binding:"required"`
	Amount   float64 `json:"amount" binding:"required,gt=0"`               // Số tiền phải > 0
	Category string  `json:"category"`                                     // Thể loại giao dịch
	Type     string  `json:"type" binding:"required,oneof=income expense"` // Chỉ chấp nhận 2 từ này
	Note     string  `json:"note"`
}

func (h *TransactionHandler) Create(c *gin.Context) {
	// Lấy UserID từ Token
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	var reqBody CreateTransactionRequest
	if err := c.ShouldBindJSON(&reqBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Map từ Request sang Model
	newTrans := models.Transaction{
		WalletID: reqBody.WalletID,
		Amount:   reqBody.Amount,
		Category: reqBody.Category,
		Type:     reqBody.Type,
		Note:     reqBody.Note,
		Date:     time.Now(),
	}

	err := h.service.CreateTransaction(userID, newTrans)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Giao dịch thành công!"})
}

// Struct nhận dữ liệu chuyển khoản
type TransferRequest struct {
	FromWalletID uint    `json:"from_wallet_id" binding:"required"`
	ToWalletID   uint    `json:"to_wallet_id" binding:"required"` // ID ví người nhận
	Amount       float64 `json:"amount" binding:"required,gt=0"`
	Note         string  `json:"note"`
}

func (h *TransactionHandler) Transfer(c *gin.Context) {
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	var req TransferRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Gọi Service chuyển tiền
	err := h.service.TransferMoney(userID, req.FromWalletID, req.ToWalletID, req.Amount, req.Note)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Chuyển tiền thành công!"})
}

func (h *TransactionHandler) GetList(c *gin.Context) {
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	transactions, err := h.service.GetMyTransactions(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": transactions})
}
