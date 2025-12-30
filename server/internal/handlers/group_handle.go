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

// GetExpenseDetail: Xem chi tiết một hóa đơn
func (h *GroupHandler) GetExpenseDetail(c *gin.Context) {
	expenseID, err := uuid.Parse(c.Param("expense_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID hóa đơn không hợp lệ"})
		return
	}

	expense, err := h.service.GetExpenseDetail(expenseID)
	if err != nil {
		c.JSON(404, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": expense})
}

// DeleteExpense: Xóa hóa đơn
func (h *GroupHandler) DeleteExpense(c *gin.Context) {
	idVal, _ := c.Get("userID")
	requesterID, _ := uuid.Parse(idVal.(string))

	expenseID, err := uuid.Parse(c.Param("expense_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID hóa đơn không hợp lệ"})
		return
	}

	err = h.service.DeleteExpense(requesterID, expenseID)
	if err != nil {
		if err.Error() == "chỉ người trả tiền hoặc Trưởng nhóm mới được xóa hóa đơn này" {
			c.JSON(403, gin.H{"error": err.Error()})
		} else {
			c.JSON(400, gin.H{"error": err.Error()})
		}
		return
	}

	c.JSON(200, gin.H{"message": "Đã xóa hóa đơn thành công!"})
}

// UpdateExpense: Sửa hóa đơn
type UpdateExpenseRequest struct {
	Amount       float64              `json:"amount"`
	Description  string               `json:"description"`
	ImageURL     string               `json:"image_url"`
	SplitDetails []services.SplitItem `json:"split_details"`
}

func (h *GroupHandler) UpdateExpense(c *gin.Context) {
	idVal, _ := c.Get("userID")
	requesterID, _ := uuid.Parse(idVal.(string))

	expenseID, err := uuid.Parse(c.Param("expense_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID hóa đơn không hợp lệ"})
		return
	}

	var req UpdateExpenseRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.UpdateExpense(requesterID, expenseID, req.Amount, req.Description, req.ImageURL, req.SplitDetails)
	if err != nil {
		if err.Error() == "chỉ người trả tiền hoặc Trưởng nhóm mới được sửa hóa đơn này" {
			c.JSON(403, gin.H{"error": err.Error()})
		} else {
			c.JSON(400, gin.H{"error": err.Error()})
		}
		return
	}

	c.JSON(200, gin.H{"message": "Cập nhật hóa đơn thành công!"})
}

// RequestDebtPayment: Người nợ gửi request đã trả nợ
type RequestDebtPaymentRequest struct {
	PaymentWalletID uuid.UUID `json:"payment_wallet_id" binding:"required"`
	Note            string    `json:"note"`
}

func (h *GroupHandler) RequestDebtPayment(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	debtID, err := uuid.Parse(c.Param("debt_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID khoản nợ không hợp lệ"})
		return
	}

	var req RequestDebtPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.RequestDebtPayment(debtID, userID, req.PaymentWalletID, req.Note)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã gửi yêu cầu xác nhận thanh toán!"})
}

// GetPendingPaymentRequests: Lấy danh sách request trả nợ chờ xác nhận
func (h *GroupHandler) GetPendingPaymentRequests(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	requests, err := h.service.GetPendingPaymentRequests(userID)
	if err != nil {
		c.JSON(500, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"data": requests})
}

// ConfirmDebtPayment: Chủ nợ xác nhận đã nhận tiền
type ConfirmDebtPaymentRequest struct {
	ReceiveWalletID uuid.UUID `json:"receive_wallet_id" binding:"required"`
}

func (h *GroupHandler) ConfirmDebtPayment(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID request không hợp lệ"})
		return
	}

	var req ConfirmDebtPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.ConfirmDebtPayment(requestID, userID, req.ReceiveWalletID)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã xác nhận thanh toán thành công!"})
}

// RejectDebtPayment: Chủ nợ từ chối request trả nợ
type RejectDebtPaymentRequest struct {
	Reason string `json:"reason"`
}

func (h *GroupHandler) RejectDebtPayment(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "ID request không hợp lệ"})
		return
	}

	var req RejectDebtPaymentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	err = h.service.RejectDebtPayment(requestID, userID, req.Reason)
	if err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã từ chối yêu cầu thanh toán!"})
}
