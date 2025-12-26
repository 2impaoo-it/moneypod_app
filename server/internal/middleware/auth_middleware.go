package middleware

import (
	"net/http"
	"strings"

	"github.com/2impaoo-it/moneypod_app/backend/internal/config"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. Lấy token từ Header "Authorization"
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Bạn cần đăng nhập để làm việc này"})
			return
		}

		// Header thường có dạng: "Bearer <token_o_day>" -> Cần bỏ chữ "Bearer " đi
		tokenString := strings.Replace(authHeader, "Bearer ", "", 1)

		// 2. Parse và kiểm tra Token - Sử dụng secret key từ config
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(config.AppConfig.JWTSecretKey), nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token không hợp lệ hoặc đã hết hạn"})
			return
		}

		// 3. Lấy UserID từ trong Token ra
		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			// ⚠️ SỬA ĐỔI QUAN TRỌNG TẠI ĐÂY:

			// A. Kiểm tra Key: Hãy chắc chắn bên AuthService bạn lưu là "sub" hay "userID"?
			// JWT chuẩn thường dùng key "sub" (Subject) để lưu ID.

			// B. Ép kiểu sang String (VÌ UUID LÀ STRING)
			// Nếu không ép kiểu ở đây, Handler dùng . (string) sẽ bị Panic (Crash App)
			userIDStr, ok := claims["sub"].(string)
			if !ok {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token lỗi: ID người dùng không hợp lệ"})
				return
			}

			// Gắn UserID (dạng string) vào context
			c.Set("userID", userIDStr)

			c.Next() // Cho phép đi tiếp
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token lỗi"})
		}
	}
}
