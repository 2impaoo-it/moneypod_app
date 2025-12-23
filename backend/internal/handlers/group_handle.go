package handlers

import (
	"net/http"

	"github.com/2impaoo-it/MoneyPod_Backend/internal/services"
	"github.com/gin-gonic/gin"
)

type GroupHandler struct {
	service *services.GroupService
}

func NewGroupHandler(service *services.GroupService) *GroupHandler {
	return &GroupHandler{service: service}
}

type CreateGroupRequest struct {
	Name string `json:"name" binding:"required"`
}

func (h *GroupHandler) Create(c *gin.Context) {
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	var req CreateGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	group, err := h.service.CreateGroup(userID, req.Name)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "Tạo nhóm thành công", "data": group})
}

func (h *GroupHandler) GetList(c *gin.Context) {
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	groups, err := h.service.GetMyGroups(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": groups})
}

type JoinGroupRequest struct {
	Code string `json:"code" binding:"required"`
}

func (h *GroupHandler) Join(c *gin.Context) {
	userIDFloat, _ := c.Get("userID")
	userID := uint(userIDFloat.(float64))

	var req JoinGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err := h.service.JoinGroup(userID, req.Code)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Tham gia nhóm thành công!"})
}

type AddExpenseRequest struct {
	GroupID   uint    `json:"group_id" binding:"required"`
	Amount    float64 `json:"amount" binding:"required"`
	Note      string  `json:"note"`
	MemberIDs []uint  `json:"member_ids" binding:"required"` // Danh sách ID những người tham gia
}

func (h *GroupHandler) AddExpense(c *gin.Context) {
	// Lấy ID người đang thao tác (Người trả tiền)
	userIDFloat, _ := c.Get("userID")
	paidByID := uint(userIDFloat.(float64))

	var req AddExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	// Gọi Service
	err := h.service.AddExpense(req.GroupID, paidByID, req.Amount, req.Note, req.MemberIDs)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(201, gin.H{"message": "Đã thêm hóa đơn và chia tiền thành công!"})
}
