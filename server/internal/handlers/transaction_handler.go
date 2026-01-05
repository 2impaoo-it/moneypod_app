package handlers

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/2impaoo-it/moneypod_app/server/internal/services"
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

// Create godoc
// @Summary      Tạo giao dịch mới
// @Description  Thêm giao dịch thu/chi vào ví
// @Tags         Transaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body CreateTransactionRequest true "Thông tin giao dịch"
// @Success      201  {object}  map[string]interface{} "Tạo giao dịch thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /transactions [post]
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

// GetList godoc
// @Summary      Lấy danh sách giao dịch
// @Description  Lấy danh sách giao dịch với filter theo category, type, wallet_id, month, year và phân trang
// @Tags         Transaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        category   query  string  false  "Danh mục"
// @Param        type       query  string  false  "Loại giao dịch (income/expense)"
// @Param        wallet_id  query  string  false  "ID ví"
// @Param        month      query  int     false  "Tháng"
// @Param        year       query  int     false  "Năm"
// @Param        page       query  int     false  "Trang (mặc định: 1)"
// @Param        page_size  query  int     false  "Số bản ghi/trang (mặc định: 20)"
// @Success      200  {object}  map[string]interface{} "Danh sách giao dịch"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /transactions [get]
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
	walletID := c.Query("wallet_id")
	month := c.Query("month")
	year := c.Query("year")
	page := c.DefaultQuery("page", "1")
	pageSize := c.DefaultQuery("page_size", "20")

	// Debug log
	fmt.Printf("📥 Handler received: walletID='%s', category='%s', type='%s'\n", walletID, category, transactionType)

	// Nếu có filter thì dùng GetTransactionsWithFilters
	if category != "" || transactionType != "" || month != "" || year != "" || walletID != "" {
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

// UpdateTransaction godoc
// @Summary      Cập nhật giao dịch
// @Description  Cập nhật thông tin giao dịch (số tiền, danh mục, loại, ghi chú)
// @Tags         Transaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID giao dịch"
// @Param        request body UpdateTransactionRequest true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /transactions/{id} [put]
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

// DeleteTransaction godoc
// @Summary      Xóa giao dịch
// @Description  Xóa một giao dịch theo ID
// @Tags         Transaction
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID giao dịch"
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /transactions/{id} [delete]
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
