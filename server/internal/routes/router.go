package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// SetupRouter định nghĩa toàn bộ đường dẫn của App
func SetupRouter() *gin.Engine {
	r := gin.Default()

	// Nhóm các API v1 (để sau này có v2 thì dễ nâng cấp)
	v1 := r.Group("/api/v1")
	{
		v1.GET("/ping", func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{"message": "Welcome to MoneyPod API!"})
		})
		
		// Sau này sẽ thêm:
		// v1.POST("/login", authHandler.Login)
		// v1.GET("/transactions", transactionHandler.GetList)
	}

	return r
}