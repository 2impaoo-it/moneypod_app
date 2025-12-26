package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type DashboardHandler struct {
	service *services.DashboardService
}

func NewDashboardHandler(service *services.DashboardService) *DashboardHandler {
	return &DashboardHandler{service: service}
}

func (h *DashboardHandler) GetOverview(c *gin.Context) {
	// Lấy UserID từ Token
	idVal, _ := c.Get("userID")
	userID, _ := uuid.Parse(idVal.(string))

	// Gọi Service lấy tất cả dữ liệu
	data, err := h.service.GetDashboardData(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi lấy dữ liệu trang chủ: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": data})
}
