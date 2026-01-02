package handlers

import (
	"net/http"
	"strconv"

	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/gin-gonic/gin"
)

type InsightHandler struct {
	service *services.InsightService
}

func NewInsightHandler(service *services.InsightService) *InsightHandler {
	return &InsightHandler{service: service}
}

// GetMonthlyInsight - API endpoint để lấy insight thông minh cho tháng
func (h *InsightHandler) GetMonthlyInsight(c *gin.Context) {
	// Kiểm tra service có khả dụng không
	if h.service == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{
			"error":   "Tính năng Insight tạm thời không khả dụng",
			"insight": "Tính năng này đang được cập nhật. Vui lòng thử lại sau.",
		})
		return
	}

	// Lấy UserID từ token
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	// Lấy month và year từ query params
	monthStr := c.Query("month")
	yearStr := c.Query("year")

	month, err := strconv.Atoi(monthStr)
	if err != nil || month < 1 || month > 12 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Tháng không hợp lệ"})
		return
	}

	year, err := strconv.Atoi(yearStr)
	if err != nil || year < 2000 || year > 2100 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Năm không hợp lệ"})
		return
	}

	// Gọi service để lấy insight
	insight, err := h.service.GetMonthlyInsight(userID.(string), month, year)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Không thể tạo insight: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"insight": insight,
		"month":   month,
		"year":    year,
	})
}
