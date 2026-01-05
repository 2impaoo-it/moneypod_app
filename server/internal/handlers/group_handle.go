package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/server/internal/services"
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

// Create godoc
// @Summary      Tạo nhóm mới
// @Description  Tạo nhóm chia tiền với danh sách thành viên ban đầu
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body CreateGroupRequest true "Thông tin nhóm và danh sách thành viên"
// @Success      201  {object}  map[string]interface{} "Tạo nhóm thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      401  {object}  map[string]interface{} "Chưa xác thực"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups [post]
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

// GetList godoc
// @Summary      Lấy danh sách nhóm
// @Description  Lấy tất cả các nhóm mà người dùng tham gia
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Danh sách nhóm"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups [get]
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

// Join godoc
// @Summary      Tham gia nhóm bằng mã mời
// @Description  Tham gia vào một nhóm sử dụng mã mời nhận được
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body JoinGroupRequest true "Mã mời nhóm"
// @Success      200  {object}  map[string]interface{} "Tham gia nhóm thành công"
// @Failure      400  {object}  map[string]interface{} "Mã không hợp lệ hoặc đã tham gia"
// @Router       /groups/join [post]
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

// AddExpense godoc
// @Summary      Thêm hóa đơn chia tiền
// @Description  Thêm một khoản chi tiêu và tự động chia nợ cho các thành viên
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body AddExpenseRequest true "Thông tin hóa đơn và cách chia"
// @Success      201  {object}  map[string]interface{} "Thêm hóa đơn thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups/expenses [post]
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

	// Parse request body để lấy wallet_id, proof_image_url, và note
	var requestBody struct {
		WalletID      *string `json:"wallet_id"`
		ProofImageURL string  `json:"proof_image_url"`
		Note          string  `json:"note"`
	}
	if err := c.ShouldBindJSON(&requestBody); err != nil {
		c.JSON(400, gin.H{"error": "Dữ liệu không hợp lệ: " + err.Error()})
		return
	}

	// Convert wallet_id string to UUID
	var walletID *uuid.UUID
	if requestBody.WalletID != nil && *requestBody.WalletID != "" {
		parsed, err := uuid.Parse(*requestBody.WalletID)
		if err != nil {
			c.JSON(400, gin.H{"error": "wallet_id không hợp lệ: " + err.Error()})
			return
		}
		walletID = &parsed
	}

	if err := h.service.MarkDebtAsPaid(debtID, userID, walletID, requestBody.ProofImageURL, requestBody.Note); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã gửi yêu cầu thanh toán. Chờ chủ nợ xác nhận."})
}

// API: Xác nhận đã nhận tiền (chủ nợ)
func (h *GroupHandler) ConfirmReceivePayment(c *gin.Context) {
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	debtID, err := uuid.Parse(c.Param("debt_id"))
	if err != nil {
		c.JSON(400, gin.H{"error": "debt_id không hợp lệ"})
		return
	}

	// Parse request body để lấy wallet_id (ví nhận tiền)
	var requestBody struct {
		WalletID string `json:"wallet_id"`
	}
	if err := c.BindJSON(&requestBody); err != nil || requestBody.WalletID == "" {
		c.JSON(400, gin.H{"error": "wallet_id là bắt buộc"})
		return
	}

	receiverWalletID, err := uuid.Parse(requestBody.WalletID)
	if err != nil {
		c.JSON(400, gin.H{"error": "wallet_id không hợp lệ"})
		return
	}

	if err := h.service.ConfirmReceivePayment(debtID, userID, receiverWalletID); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}

	c.JSON(200, gin.H{"message": "Đã xác nhận nhận tiền thành công!"})
}

// GetMyDebts godoc
// @Summary      Xem các khoản nợ của tôi
// @Description  Lấy danh sách các khoản nợ mà tôi đang nợ người khác trong nhóm
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Success      200  {object}  map[string]interface{} "Danh sách nợ"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups/{id}/debts/my-debts [get]
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

// GetDebtsToMe godoc
// @Summary      Xem ai nợ tôi
// @Description  Lấy danh sách các khoản nợ mà người khác nợ tôi trong nhóm
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Success      200  {object}  map[string]interface{} "Danh sách nợ"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups/{id}/debts/debts-to-me [get]
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

// GetGroupExpenses godoc
// @Summary      Xem lịch sử chi tiêu nhóm
// @Description  Lấy danh sách tất cả các hóa đơn chi tiêu của nhóm
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Success      200  {object}  map[string]interface{} "Danh sách hóa đơn"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups/{id}/expenses [get]
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

// GetDetail godoc
// @Summary      Lấy chi tiết nhóm
// @Description  Lấy thông tin chi tiết của một nhóm
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Success      200  {object}  map[string]interface{} "Thông tin nhóm"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      404  {object}  map[string]interface{} "Không tìm thấy nhóm"
// @Router       /groups/{id} [get]
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

// AddMember godoc
// @Summary      Thêm thành viên mới
// @Description  Thêm thành viên mới vào nhóm bằng số điện thoại (chỉ Leader)
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Param        request body AddMemberReq true "Số điện thoại thành viên"
// @Success      200  {object}  map[string]interface{} "Thêm thành viên thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ hoặc số điện thoại chưa đăng ký"
// @Router       /groups/{id}/members [post]
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

// DeleteGroup godoc
// @Summary      Xóa nhóm
// @Description  Xóa nhóm (chỉ Trưởng nhóm mới có quyền)
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Success      200  {object}  map[string]interface{} "Xóa nhóm thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      403  {object}  map[string]interface{} "Không đủ quyền"
// @Router       /groups/{id} [delete]
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

// UpdateGroup godoc
// @Summary      Cập nhật thông tin nhóm
// @Description  Cập nhật tên và mô tả nhóm (chỉ Trưởng nhóm)
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Param        request body UpdateGroupRequest true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      403  {object}  map[string]interface{} "Không đủ quyền"
// @Router       /groups/{id} [put]
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

// KickMember godoc
// @Summary      Xóa thành viên khỏi nhóm
// @Description  Leader xóa một thành viên ra khỏi nhóm
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id      path  string  true  "ID nhóm"
// @Param        user_id path  string  true  "ID thành viên cần xóa"
// @Success      200  {object}  map[string]interface{} "Xóa thành viên thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      403  {object}  map[string]interface{} "Không đủ quyền"
// @Router       /groups/{id}/members/{user_id} [delete]
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

// LeaveGroup godoc
// @Summary      Rời nhóm
// @Description  Thành viên tự rời khỏi nhóm
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        id  path  string  true  "ID nhóm"
// @Success      200  {object}  map[string]interface{} "Rời nhóm thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ hoặc lỗi khác"
// @Router       /groups/{id}/leave [post]
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

// GetExpenseDetail godoc
// @Summary      Xem chi tiết hóa đơn
// @Description  Lấy thông tin chi tiết của một hóa đơn
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        expense_id  path  string  true  "ID hóa đơn"
// @Success      200  {object}  map[string]interface{} "Chi tiết hóa đơn"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      404  {object}  map[string]interface{} "Không tìm thấy hóa đơn"
// @Router       /groups/expenses/{expense_id} [get]
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

// DeleteExpense godoc
// @Summary      Xóa hóa đơn
// @Description  Xóa hóa đơn (chỉ người trả tiền hoặc Leader)
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        expense_id  path  string  true  "ID hóa đơn"
// @Success      200  {object}  map[string]interface{} "Xóa thành công"
// @Failure      400  {object}  map[string]interface{} "ID không hợp lệ"
// @Failure      403  {object}  map[string]interface{} "Không đủ quyền"
// @Router       /groups/expenses/{expense_id} [delete]
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

// UpdateExpense godoc
// @Summary      Cập nhật hóa đơn
// @Description  Cập nhật thông tin hóa đơn (chỉ người trả tiền hoặc Leader)
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        expense_id  path  string  true  "ID hóa đơn"
// @Param        request body UpdateExpenseRequest true "Thông tin cần cập nhật"
// @Success      200  {object}  map[string]interface{} "Cập nhật thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Failure      403  {object}  map[string]interface{} "Không đủ quyền"
// @Router       /groups/expenses/{expense_id} [put]
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

// RequestDebtPayment godoc
// @Summary      Gửi yêu cầu thanh toán nợ
// @Description  Người nợ gửi yêu cầu đã trả nợ cho chủ nợ
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        debt_id  path  string  true  "ID khoản nợ"
// @Param        request body RequestDebtPaymentRequest true "Thông tin thanh toán"
// @Success      200  {object}  map[string]interface{} "Gửi yêu cầu thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Router       /groups/debts/{debt_id}/request-payment [post]
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

// GetPendingPaymentRequests godoc
// @Summary      Lấy danh sách yêu cầu trả nợ chờ xác nhận
// @Description  Chủ nợ xem các yêu cầu trả nợ đang chờ xác nhận
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Success      200  {object}  map[string]interface{} "Danh sách yêu cầu chờ xác nhận"
// @Failure      500  {object}  map[string]interface{} "Lỗi server"
// @Router       /groups/debts/pending-requests [get]
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

// ConfirmDebtPayment godoc
// @Summary      Xác nhận đã nhận tiền trả nợ
// @Description  Chủ nợ xác nhận đã nhận tiền từ người nợ
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request_id  path  string  true  "ID yêu cầu thanh toán"
// @Param        request body ConfirmDebtPaymentRequest true "Ví nhận tiền"
// @Success      200  {object}  map[string]interface{} "Xác nhận thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Router       /groups/debts/requests/{request_id}/confirm [post]
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

// RejectDebtPayment godoc
// @Summary      Từ chối yêu cầu trả nợ
// @Description  Chủ nợ từ chối yêu cầu thanh toán nợ
// @Tags         Group
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request_id  path  string  true  "ID yêu cầu thanh toán"
// @Param        request body RejectDebtPaymentRequest true "Lý do từ chối"
// @Success      200  {object}  map[string]interface{} "Từ chối thành công"
// @Failure      400  {object}  map[string]interface{} "Dữ liệu không hợp lệ"
// @Router       /groups/debts/requests/{request_id}/reject [post]
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
