package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Biến cờ hiệu (Flag) để bật/tắt bảo trì
// Trong thực tế, bạn nên lưu cái này trong Redis hoặc Database để đồng bộ
var IsMaintenanceMode = false

func MaintenanceMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Nếu đang bảo trì VÀ request không phải là của Admin (để Admin còn test được)
		if IsMaintenanceMode && !isAdminRoute(c.Request.URL.Path) {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
				"error":   "MAINTENANCE_MODE",
				"message": "Hệ thống đang bảo trì để nâng cấp. Vui lòng quay lại sau!",
			})
			return
		}
		c.Next()
	}
}

// Hàm phụ trợ: Cho phép một số đường dẫn chạy kể cả khi bảo trì
func isAdminRoute(path string) bool {
	// Ví dụ: Cho phép route togggle bảo trì chạy
	return path == "/api/admin/maintenance"
}

// Hàm để bật tắt chế độ này (Sẽ gọi từ Controller)
func SetMaintenanceMode(active bool) {
	IsMaintenanceMode = active
}
