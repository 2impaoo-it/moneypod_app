package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// Secret Key (Phải GIỐNG HỆT bên file auth_service.go)
// Mẹo: Sau này nên chuyển cái này vào file config chung để không phải copy 2 nơi.
var jwtSecretKey = []byte("moneypod_bi_mat_khong_the_bat_mi")

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

		// 2. Parse và kiểm tra Token
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return jwtSecretKey, nil
		})

		if err != nil || !token.Valid {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token không hợp lệ hoặc đã hết hạn"})
			return
		}

		// 3. Lấy UserID từ trong Token ra
		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			userID := claims["sub"] // "sub" là cái ID mình đã lưu lúc Login
			
			// Gắn UserID vào context để các hàm sau dùng
			c.Set("userID", userID)
			
			c.Next() // Cho phép đi tiếp vào trong
		} else {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Token lỗi"})
		}
	}
}