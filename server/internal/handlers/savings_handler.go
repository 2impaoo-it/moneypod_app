package handlers

import (
	"time"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/2impaoo-it/moneypod_app/server/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SavingsHandler struct {
	service *services.SavingsService
}

func NewSavingsHandler(service *services.SavingsService) *SavingsHandler {
	return &SavingsHandler{service: service}
}

// Create godoc
// @Summary      Tạo mục tiêu tiết kiệm
// @Description  Tạo mục tiêu tiết kiệm mới với tên, số tiền mục tiêu, deadline...
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body models.SavingsGoal true "Thông tin mục tiêu"
// @Success      201  {object}  map[string]interface{} "Tạo thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /savings [post]
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

// GetList godoc
// @Summary      Lấy danh sách mục tiêu tiết kiệm
// @Description  Lấy tất cả mục tiêu tiết kiệm của người dùng
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Danh sách mục tiêu"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /savings [get]
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

// Deposit godoc
// @Summary      Nạp tiền vào mục tiêu
// @Description  Nạp tiền từ ví vào mục tiêu tiết kiệm
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID mục tiêu"
// @Param        request body SavingsActionReq true "ID ví và số tiền"
// @Success      200  {object}  map[string]interface{} "Nạp tiền thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Router       /savings/{id}/deposit [post]
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

// Withdraw godoc
// @Summary      Rút tiền từ mục tiêu
// @Description  Rút tiền từ mục tiêu tiết kiệm về ví
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID mục tiêu"
// @Param        request body SavingsActionReq true "ID ví và số tiền"
// @Success      200  {object}  map[string]interface{} "Rút tiền thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ hoặc số dư không đủ"
// @Router       /savings/{id}/withdraw [post]
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

// UpdateGoal godoc
// @Summary      Cập nhật mục tiêu tiết kiệm
// @Description  Cập nhật thông tin mục tiêu (tên, màu, icon, số tiền mục tiêu, deadline)
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID mục tiêu"
// @Param        request body UpdateGoalRequest true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Router       /savings/{id} [put]
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

// DeleteGoal godoc
// @Summary      Xóa mục tiêu tiết kiệm
// @Description  Xóa một mục tiêu tiết kiệm
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID mục tiêu"
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      400  {object}  map[string]interface{} "Lỗi xóa"
// @Router       /savings/{id} [delete]
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

// GetGoalTransactions godoc
// @Summary      Lấy lịch sử giao dịch của mục tiêu
// @Description  Lấy danh sách các giao dịch nạp/rút tiền của một mục tiêu tiết kiệm
// @Tags         Savings
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID mục tiêu"
// @Success      200  {object}  map[string]interface{} "Danh sách giao dịch"
// @Failure      400  {object}  map[string]interface{} "Lỗi truy vấn"
// @Router       /savings/{id}/transactions [get]
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
