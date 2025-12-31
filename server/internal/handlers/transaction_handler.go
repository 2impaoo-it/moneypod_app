package handlers

import (
	"fmt"
	"net/http"
	"strconv"
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

	// Kiểm tra có filter không
	category := c.Query("category")
	transactionType := c.Query("type")
	walletID := c.Query("wallet_id") // <-- Thêm
	month := c.Query("month")
	year := c.Query("year")
	page := c.DefaultQuery("page", "1")
	pageSize := c.DefaultQuery("page_size", "20")

	// Nếu có filter thì dùng GetTransactionsWithFilters
	if category != "" || transactionType != "" || month != "" || year != "" || walletID != "" { // <-- Check walletID
		var monthInt, yearInt int
		if month != "" {
			fmt.Sscanf(month, "%d", &monthInt)
		}
		if year != "" {
			fmt.Sscanf(year, "%d", &yearInt)
		}

		pageInt, _ := strconv.Atoi(page)
		pageSizeInt, _ := strconv.Atoi(pageSize)

		// Thêm walletID vào hàm service
		transactions, total, err := h.service.GetTransactionsWithFilters(userID, walletID, category, transactionType, monthInt, yearInt, pageInt, pageSizeInt)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"data":      transactions,
			"total":     total,
			"page":      pageInt,
			"page_size": pageSizeInt,
		})
		return
	}

	// Không có filter thì lấy hết
	transactions, err := h.service.GetMyTransactions(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": transactions})
}

type UpdateTransactionRequest struct {
	Amount   float64 `json:"amount"`
	Category string  `json:"category"`
	Type     string  `json:"type"`
	Note     string  `json:"note"`
}

// UpdateTransaction sửa giao dịch
func (h *TransactionHandler) UpdateTransaction(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(401, gin.H{"error": "Token ID invalid"})
		return
	}

	transactionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID giao dịch không hợp lệ"})
		return
	}

	var req UpdateTransactionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.service.UpdateTransaction(transactionID, userID, req.Amount, req.Category, req.Type, req.Note)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Cập nhật giao dịch thành công!"})
}

// DeleteTransaction xóa giao dịch
func (h *TransactionHandler) DeleteTransaction(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(401, gin.H{"error": "Token ID invalid"})
		return
	}

	transactionID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID giao dịch không hợp lệ"})
		return
	}

	err = h.service.DeleteTransaction(transactionID, userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Xóa giao dịch thành công!"})
}
