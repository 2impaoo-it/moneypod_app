package main

import (
	"log"

	"github.com/2impaoo-it/moneypod_app/backend/internal/handlers"
	"github.com/2impaoo-it/moneypod_app/backend/internal/middleware"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/2impaoo-it/moneypod_app/backend/pkg/db"
	"github.com/gin-gonic/gin"
)

func main() {
	db.ConnectDatabase()

	receiptService, err := services.NewReceiptService("AIzaSyAa4ZfbVUypMKeuYlZtZ6b72PhAqba8TN0")
	if err != nil {
		log.Fatal("Lỗi khởi tạo Gemini:", err)
	}
	receiptHandler := handlers.NewReceiptHandler(receiptService)

	// --- KHỞI TẠO CÁC LỚP (Dependency Injection) ---
	userRepo := repositories.NewUserRepository(db.DB)
	walletRepo := repositories.NewWalletRepository(db.DB) // Mới

	authService := services.NewAuthService(userRepo)
	walletService := services.NewWalletService(walletRepo) // Mới

	authHandler := handlers.NewAuthHandler(authService)
	walletHandler := handlers.NewWalletHandler(walletService) // Mới

	transService := services.NewTransactionService(db.DB)
	transHandler := handlers.NewTransactionHandler(transService)

	groupService := services.NewGroupService(db.DB)
	groupHandler := handlers.NewGroupHandler(groupService)

	// --- SETUP ROUTER ---
	r := gin.Default()

	// NHÓM 1: CÔNG KHAI (Ai cũng vào được)
	public := r.Group("/api/v1")
	{
		public.GET("/ping", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "Welcome to MoneyPod API!"})
		})
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
		protected.POST("/transactions", transHandler.Create)   // Tạo giao dịch
		protected.GET("/transactions", transHandler.GetList)   // Lấy danh sách giao dịch
		protected.POST("/transfer", transHandler.Transfer)
		protected.POST("/groups", groupHandler.Create)    // Tạo nhóm
		protected.GET("/groups", groupHandler.GetList)    // Xem danh sách nhóm
		protected.POST("/groups/join", groupHandler.Join) // Tham gia nhóm
		protected.POST("/groups/expenses", groupHandler.AddExpense)
		protected.POST("/scan-receipt", receiptHandler.Scan)
	}

	r.Run(":8080")
}
