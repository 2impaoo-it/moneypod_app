package handlers

import (
	"net/http"
	"strconv"

	"github.com/2impaoo-it/moneypod_app/server/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// BudgetHandler handles all budget-related HTTP requests
type BudgetHandler struct {
	service *services.BudgetService
}

// NewBudgetHandler creates a new BudgetHandler
func NewBudgetHandler(service *services.BudgetService) *BudgetHandler {
	return &BudgetHandler{service: service}
}

// CreateBudgetRequest represents the request body for creating a budget
type CreateBudgetRequest struct {
	Category string  `json:"category" binding:"required"`
	Amount   float64 `json:"amount" binding:"required,gt=0"`
	Month    int     `json:"month" binding:"required,min=1,max=12"`
	Year     int     `json:"year" binding:"required,min=2020"`
}

// Create godoc
// @Summary      Tạo ngân sách mới
// @Description  Tạo ngân sách cho một danh mục trong tháng/năm cụ thể
// @Tags         Budget
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body CreateBudgetRequest true "Thông tin ngân sách"
// @Success      201  {object}  map[string]interface{} "Tạo ngân sách thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /budgets [post]
func (h *BudgetHandler) Create(c *gin.Context) {
	// Get user ID from token
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID invalid"})
		return
	}

	var req CreateBudgetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	budget, err := h.service.CreateBudget(userID, req.Category, req.Amount, req.Month, req.Year)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Tạo ngân sách thành công!",
		"data":    budget,
	})
}

// GetList godoc
// @Summary      Lấy danh sách ngân sách
// @Description  Lấy danh sách ngân sách theo tháng và năm (query params)
// @Tags         Budget
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        month  query  int  false  "Tháng (1-12)"
// @Param        year   query  int  false  "Năm"
// @Success      200  {object}  map[string]interface{} "Danh sách ngân sách"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /budgets [get]
func (h *BudgetHandler) GetList(c *gin.Context) {
	// Get user ID from token
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID invalid"})
		return
	}

	// Parse query params
	month, _ := strconv.Atoi(c.Query("month"))
	year, _ := strconv.Atoi(c.Query("year"))

	budgets, err := h.service.GetBudgets(userID, month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": budgets})
}

// GetByID godoc
// @Summary      Lấy chi tiết ngân sách
// @Description  Lấy thông tin chi tiết của một ngân sách theo ID
// @Tags         Budget
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID ngân sách"
// @Success      200  {object}  map[string]interface{} "Chi tiết ngân sách"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      404  {object}  map[string]interface{} "Không tìm thấy ngân sách"
// @Router       /budgets/{id} [get]
func (h *BudgetHandler) GetByID(c *gin.Context) {
	// Get user ID from token
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID invalid"})
		return
	}

	budgetID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ngân sách không hợp lệ"})
		return
	}

	budget, err := h.service.GetBudgetByID(budgetID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": budget})
}

// UpdateBudgetRequest represents the request body for updating a budget
type UpdateBudgetRequest struct {
	Amount   float64 `json:"amount"`
	Category string  `json:"category"`
}

// Update godoc
// @Summary      Cập nhật ngân sách
// @Description  Cập nhật thông tin ngân sách (số tiền và danh mục)
// @Tags         Budget
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID ngân sách"
// @Param        request body UpdateBudgetRequest true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /budgets/{id} [put]
func (h *BudgetHandler) Update(c *gin.Context) {
	// Get user ID from token
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID invalid"})
		return
	}

	budgetID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ngân sách không hợp lệ"})
		return
	}

	var req UpdateBudgetRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.service.UpdateBudget(budgetID, userID, req.Amount, req.Category)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Cập nhật ngân sách thành công!"})
}

// Delete godoc
// @Summary      Xóa ngân sách
// @Description  Xóa một ngân sách theo ID
// @Tags         Budget
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID ngân sách"
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ hoặc lỗi xóa"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Router       /budgets/{id} [delete]
func (h *BudgetHandler) Delete(c *gin.Context) {
	// Get user ID from token
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Token ID invalid"})
		return
	}

	budgetID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID ngân sách không hợp lệ"})
		return
	}

	err = h.service.DeleteBudget(budgetID, userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Xóa ngân sách thành công!"})
}
