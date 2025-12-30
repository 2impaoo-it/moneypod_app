package handlers

import (
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SavingsHandler struct {
	service *services.SavingsService
}

func NewSavingsHandler(service *services.SavingsService) *SavingsHandler {
	return &SavingsHandler{service: service}
}

// POST /api/v1/savings
func (h *SavingsHandler) Create(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	var req models.SavingsGoal
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	if err := h.service.CreateGoal(userID, req); err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(201, gin.H{"message": "Tạo mục tiêu thành công"})
}

// GET /api/v1/savings
func (h *SavingsHandler) GetList(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	goals, err := h.service.GetMyGoals(userID)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"data": goals})
}

type SavingsActionReq struct {
	WalletID uuid.UUID `json:"wallet_id" binding:"required"`
	Amount   float64   `json:"amount" binding:"required,gt=0"`
}

// POST /api/v1/savings/:id/deposit
func (h *SavingsHandler) Deposit(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))
	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID mục tiêu không hợp lệ"})
		return
	}

	var req SavingsActionReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.Deposit(userID, goalID, req.WalletID, req.Amount)

	// 🔥 Bắt tín hiệu hoàn thành
	if err != nil && err.Error() == "GOAL_COMPLETED" {
		c.JSON(200, gin.H{
			"message": "🎉 Chúc mừng! Bạn đã hoàn thành mục tiêu này!",
			"status":  "COMPLETED",
		})
		return
	}

	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Nạp tiền vào quỹ thành công!"})
}

// POST /api/v1/savings/:id/withdraw
func (h *SavingsHandler) Withdraw(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))
	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID mục tiêu không hợp lệ"})
		return
	}

	var req SavingsActionReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.Withdraw(userID, goalID, req.WalletID, req.Amount)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	c.JSON(200, gin.H{"message": "Rút tiền về ví thành công!"})
}

// UpdateGoal: PUT /api/v1/savings/:id
type UpdateGoalRequest struct {
	Name         string  `json:"name"`
	Color        string  `json:"color"`
	Icon         string  `json:"icon"`
	TargetAmount float64 `json:"target_amount"`
	Deadline     *string `json:"deadline"` // ISO format string
}

func (h *SavingsHandler) UpdateGoal(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID mục tiêu không hợp lệ"})
		return
	}

	var req UpdateGoalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Parse deadline nếu có
	var deadlinePtr *time.Time
	if req.Deadline != nil && *req.Deadline != "" {
		deadline, err := time.Parse(time.RFC3339, *req.Deadline)
		if err != nil {
			c.JSON(400, gin.H{"error": "Định dạng deadline không hợp lệ (dùng ISO 8601)"})
			return
		}
		deadlinePtr = &deadline
	}

	err = h.service.UpdateGoal(userID, goalID, req.Name, req.Color, req.Icon, req.TargetAmount, deadlinePtr)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Cập nhật mục tiêu thành công!"})
}

// DeleteGoal: DELETE /api/v1/savings/:id
func (h *SavingsHandler) DeleteGoal(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID mục tiêu không hợp lệ"})
		return
	}

	err = h.service.DeleteGoal(userID, goalID)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Xóa mục tiêu thành công!"})
}

// GetGoalTransactions: GET /api/v1/savings/:id/transactions
func (h *SavingsHandler) GetGoalTransactions(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	goalID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID mục tiêu không hợp lệ"})
		return
	}

	transactions, err := h.service.GetGoalTransactions(userID, goalID)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": transactions})
}
