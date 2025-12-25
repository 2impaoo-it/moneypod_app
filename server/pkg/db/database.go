package db

import (
	"fmt"
	"log"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Biến DB toàn cục để các nơi khác gọi dùng
var DB *gorm.DB

func ConnectDatabase() {
	// Thông tin này KHỚP với file docker-compose.yml ở trên
	dsn := "host=localhost user=postgres password=moneypod_secret dbname=moneypod port=5432 sslmode=disable TimeZone=Asia/Ho_Chi_Minh"

	database, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

	if err != nil {
		log.Fatal("❌ Chết rồi! Không kết nối được Database: ", err)
	}

	fmt.Println("✅ Kết nối thành công đến PostgreSQL (Docker)!")

	// Tự động tạo bảng dựa trên Struct
	err = database.AutoMigrate(
		&models.User{},
		&models.Wallet{},
		&models.Transaction{},
		&models.Group{},
		&models.GroupMember{},
		&models.GroupExpense{},
		&models.ExpenseSplit{},
	)
	if err != nil {
		log.Fatal("❌ Không thể khởi tạo bảng: ", err)
	}
	fmt.Println("✅ Đã tạo bảng Users thành công!")
	// Gán kết nối vào biến toàn cục
	DB = database
}
