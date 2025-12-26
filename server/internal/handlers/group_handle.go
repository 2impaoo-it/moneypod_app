package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid" // <--- Import
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
	idVal, _ := c.Get("userID")
	userID, err := uuid.Parse(idVal.(string))
	if err != nil {
		c.JSON(401, gin.H{"error": "Invalid Token"})
		return
	}

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
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

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
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

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
	// SỬA: uint -> uuid.UUID
	GroupID   uuid.UUID   `json:"group_id" binding:"required"`
	Amount    float64     `json:"amount" binding:"required"`
	Note      string      `json:"note"`
	MemberIDs []uuid.UUID `json:"member_ids" binding:"required"` // Sửa mảng uint -> mảng UUID
}

func (h *GroupHandler) AddExpense(c *gin.Context) {
	idVal, _ := c.Get("userID")
	paidByID, _ := uuid.Parse(idVal.(string))

	var req AddExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err := h.service.AddExpense(req.GroupID, paidByID, req.Amount, req.Note, req.MemberIDs)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(201, gin.H{"message": "Đã thêm hóa đơn và chia tiền thành công!"})
}

// 1. Struct nhận dữ liệu Request
type RequestSettlementInput struct {
	GroupID  uuid.UUID `json:"group_id" binding:"required"`
	ToUserID uuid.UUID `json:"to_user_id" binding:"required"` // Trả cho ai
	WalletID uuid.UUID `json:"wallet_id" binding:"required"`  // Trả bằng ví nào
	Amount   float64   `json:"amount" binding:"required,gt=0"`
}

// API: Người nợ gửi yêu cầu
func (h *GroupHandler) SendSettlementRequest(c *gin.Context) {
	idVal, _ := c.Get("userID")
	debtorID, _ := uuid.Parse(idVal.(string))

	var req RequestSettlementInput
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	result, err := h.service.RequestSettlement(req.GroupID, debtorID, req.ToUserID, req.WalletID, req.Amount)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(201, gin.H{"message": "Đã gửi yêu cầu xác nhận!", "data": result})
}

// 2. Struct nhận dữ liệu Confirm
type ConfirmSettlementInput struct {
	SettlementID uuid.UUID `json:"settlement_id" binding:"required"`
	Action       string    `json:"action" binding:"required,oneof=confirm reject"` // Chỉ nhận 'confirm' hoặc 'reject'
}

// API: Chủ nợ xác nhận
func (h *GroupHandler) ConfirmSettlementRequest(c *gin.Context) {
	idVal, _ := c.Get("userID")
	creditorID, _ := uuid.Parse(idVal.(string))

	var req ConfirmSettlementInput
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	isConfirmed := (req.Action == "confirm")
	err := h.service.ConfirmSettlement(creditorID, req.SettlementID, isConfirmed)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	msg := "Đã xác nhận thanh toán! Số dư nhóm và ví đã được cập nhật."
	if !isConfirmed {
		msg = "Đã từ chối thanh toán."
	}
	c.JSON(200, gin.H{"message": msg})
}
