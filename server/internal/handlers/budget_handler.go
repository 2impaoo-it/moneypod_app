package handlers

import (
	"net/http"
	"strconv"

	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
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

// Create handles POST /api/budgets
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

// GetList handles GET /api/budgets?month=X&year=Y
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

// GetByID handles GET /api/budgets/:id
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

// Update handles PUT /api/budgets/:id
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

// Delete handles DELETE /api/budgets/:id
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
