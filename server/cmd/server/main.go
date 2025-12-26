package main

import (
	"log"

	"github.com/2impaoo-it/moneypod_app/backend/internal/config"
	"github.com/2impaoo-it/moneypod_app/backend/internal/handlers"
	"github.com/2impaoo-it/moneypod_app/backend/internal/middleware"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/2impaoo-it/moneypod_app/backend/internal/services"
	"github.com/2impaoo-it/moneypod_app/backend/pkg/db"
	"github.com/gin-gonic/gin"
)

func main() {
	// Load config từ file .env
	config.LoadConfig()

	// Kết nối database
	db.ConnectDatabase()

	// --- KHỞI TẠO SERVICES & HANDLERS ---
	// Sử dụng API Key từ config
	receiptService, err := services.NewReceiptService(config.AppConfig.GeminiAPIKey)
	if err != nil {
		log.Fatal("Lỗi khởi tạo Gemini:", err)
	}
	receiptHandler := handlers.NewReceiptHandler(receiptService)

	userRepo := repositories.NewUserRepository(db.DB)
	walletRepo := repositories.NewWalletRepository(db.DB)
	// Tạo Transaction Repo (nếu chưa có thì tạo mới file repository cho nó)
	transRepo := repositories.NewTransactionRepository(db.DB)

	// 2. Khởi tạo Dashboard Service & Handler
	dashboardService := services.NewDashboardService(userRepo, walletRepo, transRepo)
	dashboardHandler := handlers.NewDashboardHandler(dashboardService)

	authService := services.NewAuthService(userRepo)
	walletService := services.NewWalletService(walletRepo)

	authHandler := handlers.NewAuthHandler(authService)
	walletHandler := handlers.NewWalletHandler(walletService)

	transService := services.NewTransactionService(db.DB)
	transHandler := handlers.NewTransactionHandler(transService)

	groupService := services.NewGroupService(db.DB)
	groupHandler := handlers.NewGroupHandler(groupService)

	// --- SETUP ROUTER ---
	r := gin.Default()

	// 🔥 1. API ADMIN (Đặt TRƯỚC middleware bảo trì để luôn vào được)
	r.POST("/api/admin/maintenance", func(c *gin.Context) {
		var req struct {
			Enable bool `json:"enable"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(400, gin.H{"error": err.Error()})
			return
		}

		// Gọi hàm bên middleware để set biến
		middleware.SetMaintenanceMode(req.Enable)

		status := "Đã TẮT"
		if req.Enable {
			status = "Đã BẬT"
		}
		c.JSON(200, gin.H{"message": "Chế độ bảo trì: " + status})
	})

	// 🔥 2. KÍCH HOẠT CHẾ ĐỘ BẢO TRÌ (Chặn tất cả các route bên dưới nếu bật)
	r.Use(middleware.MaintenanceMiddleware())

	// NHÓM 1: CÔNG KHAI (Sẽ bị chặn khi bảo trì -> Tốt, không cho login/register lúc này)
	public := r.Group("/api/v1")
	{
		public.GET("/ping", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "Welcome to MoneyPod API!"})
		})
		public.POST("/register", authHandler.Register)
		public.POST("/login", authHandler.Login)
	}

	// NHÓM 2: RIÊNG TƯ (Sẽ bị chặn khi bảo trì)
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		protected.GET("/dashboard", dashboardHandler.GetOverview)
		protected.GET("/profile", authHandler.GetProfile)

		protected.POST("/wallets", walletHandler.CreateWallet)
		protected.GET("/wallets", walletHandler.GetList)

		protected.POST("/transactions", transHandler.Create)
		protected.GET("/transactions", transHandler.GetList)
		protected.POST("/transfer", transHandler.Transfer)

		protected.POST("/groups", groupHandler.Create)
		protected.GET("/groups", groupHandler.GetList)
		protected.POST("/groups/join", groupHandler.Join)
		protected.POST("/groups/expenses", groupHandler.AddExpense)
		protected.POST("/groups/settle/request", groupHandler.SendSettlementRequest)
		protected.POST("/groups/settle/confirm", groupHandler.ConfirmSettlementRequest)

		protected.POST("/scan-receipt", receiptHandler.Scan)
	}

	r.Run(":8080")
}
