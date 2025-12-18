package main

import (
	"github.com/2impaoo-it/MoneyPod_Backend/internal/handlers"
	"github.com/2impaoo-it/MoneyPod_Backend/internal/middleware"
	"github.com/2impaoo-it/MoneyPod_Backend/internal/repositories"
	"github.com/2impaoo-it/MoneyPod_Backend/internal/services"
	"github.com/2impaoo-it/MoneyPod_Backend/pkg/db"
	"github.com/gin-gonic/gin"
)

func main() {
	db.ConnectDatabase()

	// --- KHỞI TẠO CÁC LỚP (Dependency Injection) ---
	userRepo := repositories.NewUserRepository(db.DB)
	walletRepo := repositories.NewWalletRepository(db.DB) // Mới

	authService := services.NewAuthService(userRepo)
	walletService := services.NewWalletService(walletRepo) // Mới

	authHandler := handlers.NewAuthHandler(authService)
	walletHandler := handlers.NewWalletHandler(walletService) // Mới

	transService := services.NewTransactionService(db.DB)
	transHandler := handlers.NewTransactionHandler(transService)

	// --- SETUP ROUTER ---
	r := gin.Default()

	// NHÓM 1: CÔNG KHAI (Ai cũng vào được)
	public := r.Group("/api/v1")
	{
		public.POST("/register", authHandler.Register)
		public.POST("/login", authHandler.Login)
	}

	// NHÓM 2: RIÊNG TƯ (Phải có Token mới vào được)
	// Áp dụng middleware ở đây!
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		// Thử tạo một API test đơn giản
		protected.GET("/profile", func(c *gin.Context) {
			// Lấy ID người dùng từ middleware đã gắn vào
			userID, _ := c.Get("userID")
			c.JSON(200, gin.H{
				"message": "Đây là thông tin mật!",
				"user_id": userID,
			})
		})

		protected.POST("/wallets", walletHandler.CreateWallet) // Tạo ví
		protected.GET("/wallets", walletHandler.GetList)       // Xem danh sách ví
		protected.POST("/transactions", transHandler.Create)
		protected.POST("/transfer", transHandler.Transfer)
	}

	r.Run(":8080")
}
