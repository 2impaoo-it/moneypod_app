package handlers

import (
	"net/http"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid" // <--- Import
)

type TransactionHandler struct {
	service *services.TransactionService
}

func NewTransactionHandler(service *services.TransactionService) *TransactionHandler {
	return &TransactionHandler{service: service}
}

type CreateTransactionRequest struct {
	// SỬA: uint -> uuid.UUID
	WalletID uuid.UUID `json:"wallet_id" binding:"required"`
	Amount   float64   `json:"amount" binding:"required,gt=0"`
	Category string    `json:"category"`
	Type     string    `json:"type" binding:"required,oneof=income expense"`
	Note     string    `json:"note"`
}

func (h *TransactionHandler) Create(c *gin.Context) {
	// 1. Lấy UserID UUID
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(401, gin.H{"error": "Token ID invalid"})
		return
	}

	var reqBody CreateTransactionRequest
	if err := c.ShouldBindJSON(&reqBody); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	newTrans := models.Transaction{
		WalletID: reqBody.WalletID, // Giờ cùng kiểu uuid.UUID nên gán được
		Amount:   reqBody.Amount,
		Category: reqBody.Category,
		Type:     reqBody.Type,
		Note:     reqBody.Note,
		Date:     time.Now(),
	}

	err = h.service.CreateTransaction(userID, newTrans)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Giao dịch thành công!"})
}

func (h *TransactionHandler) GetList(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(401, gin.H{"error": "Token ID invalid"})
		return
	}

	transactions, err := h.service.GetMyTransactions(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": transactions})
}
