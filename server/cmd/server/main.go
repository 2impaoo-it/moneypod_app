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
	// 1. Load config từ file .env
	config.LoadConfig()

	// 2. Kết nối database
	db.ConnectDatabase()

	// --- KHỞI TẠO REPOSITORIES ---
	userRepo := repositories.NewUserRepository(db.DB)
	walletRepo := repositories.NewWalletRepository(db.DB)
	transRepo := repositories.NewTransactionRepository(db.DB)
	savingsRepo := repositories.NewSavingsRepository(db.DB)

	// 3. 🔥 KHỞI TẠO NOTIFICATION SERVICE
	// Lưu ý: Bạn cần có file serviceAccountKey.json ở cùng thư mục
	notifService, err := services.NewNotificationService("./serviceAccountKey.json")
	if err != nil {
		log.Println("⚠️ Cảnh báo: Không thể kết nối Firebase (Chưa có key hoặc sai đường dẫn). Tính năng thông báo sẽ không chạy.")
		notifService = nil // Vẫn cho server chạy nhưng không gửi được thông báo
	} else {
		log.Println("✅ Đã kết nối Firebase Cloud Messaging!")
	}
	// --- KHỞI TẠO SERVICES ---

	// ✅ Cloudinary Service
	storageService, err := services.NewStorageService()
	if err != nil {
		log.Fatal("❌ Lỗi kết nối Cloudinary:", err)
	}

	// ✅ Gemini AI Service
	receiptService, err := services.NewReceiptService(config.AppConfig.GeminiAPIKey)
	if err != nil {
		log.Fatal("❌ Lỗi khởi tạo Gemini AI:", err)
	}

	authService := services.NewAuthService(userRepo)
	walletService := services.NewWalletService(walletRepo)
	dashboardService := services.NewDashboardService(userRepo, walletRepo, transRepo)
	transService := services.NewTransactionService(db.DB, transRepo, walletRepo)
	groupService := services.NewGroupService(db.DB, notifService, userRepo)
	savingsService := services.NewSavingsService(db.DB, savingsRepo, walletRepo)

	// --- KHỞI TẠO HANDLERS ---
	// 🔥 THÊM DÒNG NÀY: Khởi tạo UploadHandler
	uploadHandler := handlers.NewUploadHandler(storageService)

	receiptHandler := handlers.NewReceiptHandler(receiptService)
	authHandler := handlers.NewAuthHandler(authService)
	walletHandler := handlers.NewWalletHandler(walletService)
	dashboardHandler := handlers.NewDashboardHandler(dashboardService)
	transHandler := handlers.NewTransactionHandler(transService)
	groupHandler := handlers.NewGroupHandler(groupService)
	savingsHandler := handlers.NewSavingsHandler(savingsService)
	// --- SETUP ROUTER ---
	r := gin.Default()

	// --- API ADMIN ---
	adminGroup := r.Group("/api/admin")
	adminGroup.Use(middleware.AdminMiddleware())
	{
		adminGroup.POST("/maintenance", func(c *gin.Context) {
			var req struct {
				Enable bool `json:"enable"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(400, gin.H{"error": err.Error()})
				return
			}
			middleware.SetMaintenanceMode(req.Enable)
			status := "Đã TẮT"
			if req.Enable {
				status = "Đã BẬT"
			}
			c.JSON(200, gin.H{"message": "Chế độ bảo trì: " + status})
		})
	}

	// Middleware bảo trì toàn cục
	r.Use(middleware.MaintenanceMiddleware())

	// --- PUBLIC API ---
	public := r.Group("/api/v1")
	{
		public.GET("/ping", func(c *gin.Context) {
			c.JSON(200, gin.H{"message": "Welcome to MoneyPod API!"})
		})
		public.POST("/register", authHandler.Register)
		public.POST("/login", authHandler.Login)
	}

	// --- PROTECTED API ---
	protected := r.Group("/api/v1")
	protected.Use(middleware.AuthMiddleware())
	{
		protected.POST("/fcm-token", authHandler.UpdateFCMToken) // API cập nhật token

		// Dashboard & Profile
		protected.GET("/dashboard", dashboardHandler.GetOverview)
		protected.GET("/profile", authHandler.GetProfile)
		protected.PUT("/profile", authHandler.UpdateProfile)
		protected.PUT("/profile/avatar", authHandler.UpdateAvatar)
		protected.POST("/profile/phone", authHandler.LinkPhone) // API cập nhật SĐT
		// Ví
		protected.POST("/wallets", walletHandler.CreateWallet)
		protected.GET("/wallets", walletHandler.GetList)
		protected.PUT("/wallets/:id", walletHandler.UpdateWallet)       // Cập nhật ví
		protected.DELETE("/wallets/:id", walletHandler.DeleteWallet)    // Xóa ví

		// Giao dịch
		protected.POST("/transactions", transHandler.Create)
		protected.GET("/transactions", transHandler.GetList)
		protected.PUT("/transactions/:id", transHandler.UpdateTransaction)    // Sửa giao dịch
		protected.DELETE("/transactions/:id", transHandler.DeleteTransaction) // Xóa giao dịch

		// Nhóm & Chi tiêu
		protected.POST("/groups", groupHandler.Create)
		protected.GET("/groups", groupHandler.GetList)
		protected.GET("/groups/:id", groupHandler.GetDetail)
		protected.PUT("/groups/:id", groupHandler.UpdateGroup)                            // Cập nhật nhóm
		protected.POST("/groups/join", groupHandler.Join)
		protected.POST("/groups/expenses", groupHandler.AddExpense)
		protected.GET("/groups/:id/expenses", groupHandler.GetGroupExpenses)
		protected.GET("/groups/expenses/:expense_id", groupHandler.GetExpenseDetail)      // Xem chi tiết hóa đơn
		protected.DELETE("/groups/expenses/:expense_id", groupHandler.DeleteExpense)      // Xóa hóa đơn
		protected.PUT("/groups/expenses/:expense_id", groupHandler.UpdateExpense)         // Sửa hóa đơn
		protected.POST("/groups/:id/members", groupHandler.AddMember)
		protected.DELETE("/groups/:id/members/:user_id", groupHandler.KickMember)         // Kick thành viên
		protected.POST("/groups/:id/leave", groupHandler.LeaveGroup)                      // Rời nhóm
		protected.PUT("/groups/debts/:debt_id/paid", groupHandler.MarkDebtPaid)
		protected.GET("/groups/:id/my-debts", groupHandler.GetMyDebts)
		protected.GET("/groups/:id/debts-to-me", groupHandler.GetDebtsToMe)
		protected.DELETE("/groups/:id", groupHandler.DeleteGroup)

		// AI & Upload
		protected.POST("/scan-receipt", receiptHandler.Scan)

		// Route Upload ảnh
		protected.POST("/upload", uploadHandler.UploadImage)

		// ROUTES TIẾT KIỆM
		protected.POST("/savings", savingsHandler.Create)                         // Tạo heo đất
		protected.GET("/savings", savingsHandler.GetList)                         // Xem heo đất
		protected.PUT("/savings/:id", savingsHandler.UpdateGoal)                  // Sửa mục tiêu
		protected.DELETE("/savings/:id", savingsHandler.DeleteGoal)               // Xóa mục tiêu
		protected.POST("/savings/:id/deposit", savingsHandler.Deposit)            // Cho heo ăn
		protected.POST("/savings/:id/withdraw", savingsHandler.Withdraw)          // Đập heo
		protected.GET("/savings/:id/transactions", savingsHandler.GetGoalTransactions) // Lịch sử nạp/rút
	}

	// Chạy Server
	log.Println("🚀 Server is running on port " + config.AppConfig.ServerPort)
	r.Run(":" + config.AppConfig.ServerPort)
}
