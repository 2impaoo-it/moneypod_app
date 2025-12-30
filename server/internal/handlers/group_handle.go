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
	Name        string                       `json:"name" binding:"required"`
	Description string                       `json:"description"`
	Members     []services.CreateMemberInput `json:"members" binding:"required,min=1"`
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

	group, err := h.service.CreateGroup(userID, req.Name, req.Description, req.Members)
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
	GroupID     uuid.UUID `json:"group_id" binding:"required"`
	Amount      float64   `json:"amount" binding:"required,gt=0"`
	Description string    `json:"description"`
	ImageURL    string    `json:"image_url"`
	PayerID     uuid.UUID `json:"payer_id" binding:"required"`

	SplitDetails []services.SplitItem `json:"split_details"`
}

func (h *GroupHandler) AddExpense(c *gin.Context) {
	var req AddExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	expenseReq := services.CreateExpenseRequest{
		Amount:       req.Amount,
		Description:  req.Description,
		ImageURL:     req.ImageURL,
		PayerID:      req.PayerID,
		SplitDetails: req.SplitDetails,
	}

	err := h.service.CreateExpense(req.GroupID, expenseReq)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(201, gin.H{"message": "Đã thêm hóa đơn và tạo nợ thành công!"})
}

// API: Đánh dấu đã trả nợ
func (h *GroupHandler) MarkDebtPaid(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	debtID, err := uuid.Parse(c.Param("debt_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "debt_id không hợp lệ"})
		return
	}

	if err := h.service.MarkDebtAsPaid(debtID, userID); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã xác nhận thanh toán!"})
}

// API: Xem nợ của tôi
func (h *GroupHandler) GetMyDebts(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "group_id không hợp lệ"})
		return
	}

	debts, err := h.service.GetMyDebts(groupID, userID)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": debts})
}

// API: Xem ai nợ tôi
func (h *GroupHandler) GetDebtsToMe(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "group_id không hợp lệ"})
		return
	}

	debts, err := h.service.GetDebtsToMe(groupID, userID)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": debts})
}

// API: Xem lịch sử chi tiêu của nhóm
func (h *GroupHandler) GetGroupExpenses(c *gin.Context) {
	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "group_id không hợp lệ"})
		return
	}

	expenses, err := h.service.GetGroupExpenses(groupID)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": expenses})
}

// GET /api/v1/groups/:id
func (h *GroupHandler) GetDetail(c *gin.Context) {
	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID nhóm không hợp lệ"})
		return
	}

	group, err := h.service.GetGroupDetail(groupID)
	if err != nil {
		c.JSON(404, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": group})
}

// Struct input
type AddMemberReq struct {
	Phone string `json:"phone" binding:"required"`
}

// POST /api/v1/groups/:id/members
func (h *GroupHandler) AddMember(c *gin.Context) {
	// 1. Lấy ID người đang thao tác
	idVal, _ := c.Get("userID")
	requesterID, _ := uuid.Parse(idVal.(string))

	// 2. Lấy Group ID từ URL
	groupID, err := uuid.Parse(c.Param("id")) // Lưu ý: Đã đổi thành :id cho chuẩn
	if err != nil {
		c.JSON(400, gin.H{"error": "ID nhóm không hợp lệ"})
		return
	}

	// 3. Lấy SĐT từ Body
	var req AddMemberReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": "Vui lòng nhập số điện thoại (key: phone)"})
		return
	}

	// 4. Gọi Service
	err = h.service.AddMemberViaPhone(requesterID, groupID, req.Phone)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã thêm thành viên mới thành công!"})
}

// DELETE /api/v1/groups/:id
func (h *GroupHandler) DeleteGroup(c *gin.Context) {
	// 1. Lấy ID người dùng (Requester)
	idVal, _ := c.Get("userID")
	requesterID, _ := uuid.Parse(idVal.(string))

	// 2. Lấy Group ID từ URL
	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID nhóm không hợp lệ"})
		return
	}

	// 3. Gọi Service
	err = h.service.DeleteGroup(requesterID, groupID)
	if err != nil {
		// Trả về 403 Forbidden nếu không đủ quyền, hoặc 400 nếu lỗi khác
		if err.Error() == "chỉ Trưởng nhóm (Leader) mới có quyền xóa nhóm" {
			c.JSON(403, gin.H{"error": err.Error()})
		} else {
			c.JSON(400, gin.H{"error": err.Error()})
		}
		return
	}

	c.JSON(200, gin.H{"message": "Đã xóa nhóm thành công"})
}

// UpdateGroup: Cập nhật tên nhóm, mô tả (Chỉ Leader)
type UpdateGroupRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

func (h *GroupHandler) UpdateGroup(c *gin.Context) {
	idVal, _ := c.Get("userID")
	requesterID, _ := uuid.Parse(idVal.(string))

	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID nhóm không hợp lệ"})
		return
	}

	var req UpdateGroupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.UpdateGroup(requesterID, groupID, req.Name, req.Description)
	if err != nil {
		if err.Error() == "chỉ Trưởng nhóm (Leader) mới có quyền chỉnh sửa thông tin nhóm" {
			c.JSON(403, gin.H{"error": err.Error()})
		} else {
			c.JSON(400, gin.H{"error": err.Error()})
		}
		return
	}

	c.JSON(200, gin.H{"message": "Cập nhật nhóm thành công!"})
}

// KickMember: Leader xóa thành viên
func (h *GroupHandler) KickMember(c *gin.Context) {
	idVal, _ := c.Get("userID")
	requesterID, _ := uuid.Parse(idVal.(string))

	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID nhóm không hợp lệ"})
		return
	}

	memberUserID, err := uuid.Parse(c.Param("user_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID thành viên không hợp lệ"})
		return
	}

	err = h.service.KickMember(requesterID, groupID, memberUserID)
	if err != nil {
		if err.Error() == "chỉ Trưởng nhóm (Leader) mới có quyền xóa thành viên" {
			c.JSON(403, gin.H{"error": err.Error()})
		} else {
			c.JSON(400, gin.H{"error": err.Error()})
		}
		return
	}

	c.JSON(200, gin.H{"message": "Đã xóa thành viên khỏi nhóm!"})
}

// LeaveGroup: Thành viên tự rời nhóm
func (h *GroupHandler) LeaveGroup(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	groupID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID nhóm không hợp lệ"})
		return
	}

	err = h.service.LeaveGroup(userID, groupID)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Bạn đã rời nhóm thành công!"})
}
