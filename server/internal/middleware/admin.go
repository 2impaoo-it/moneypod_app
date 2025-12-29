package middleware

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/backend/internal/config"
	"github.com/gin-gonic/gin"
)

// AdminMiddleware: Chỉ cho phép request có Header "x-admin-secret" trùng khớp đi qua
func AdminMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Lấy secret key từ Header
		clientKey := c.GetHeader("x-admin-secret")

		// 2. So sánh với Key trong file .env
		if clientKey != config.AppConfig.AdminSecretKey {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{
				"error":   "ACCESS_DENIED",
				"message": "Bạn không có quyền thực hiện hành động này!",
			})
			return
		}

		// 3. Nếu đúng thì cho qua
		c.Next()
	}
}
