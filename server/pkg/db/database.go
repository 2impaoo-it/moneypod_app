package db

import (
	"fmt"
	"log"

	"github.com/2impaoo-it/moneypod_app/server/internal/config"
	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Biến DB toàn cục để các nơi khác gọi dùng
var DB *gorm.DB

func ConnectDatabase() {
	// Lấy DSN từ config
	dsn := config.AppConfig.GetDatabaseDSN()

	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

	if err != nil {
		log.Fatal("❌ Chết rồi! Không kết nối được Database: ", err)
	}

	fmt.Println("✅ Kết nối thành công đến PostgreSQL (Docker)!")

	// 🔥 QUAN TRỌNG: Kích hoạt Extension UUID trước khi tạo bảng
	// Nếu thiếu dòng này, PostgreSQL sẽ báo lỗi "function gen_random_uuid() does not exist"
	database.Exec("CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";")

	// Tự động tạo bảng dựa trên Struct
	err = database.AutoMigrate(
		&models.User{},
		&models.Wallet{},
		&models.Transaction{},
		&models.Group{},
		&models.GroupMember{},
		&models.Expense{},
		&models.Debt{},
		&models.DebtPaymentRequest{},  // Bảng debt_payment_requests
		&models.SavingsGoal{},         // Bảng savings_goals
		&models.SavingsTransaction{},  // Bảng savings_transactions
		&models.Notification{},        // Bảng notifications
		&models.NotificationSetting{}, // Bảng notification_settings
		&models.Budget{},              // Bảng budgets
	)
	if err != nil {
		log.Fatal("❌ Không thể khởi tạo bảng: ", err)
	}
	fmt.Println("✅ Đã tạo bảng và cấu trúc UUID thành công!")

	// Gán kết nối vào biến toàn cục
	DB = database
}
