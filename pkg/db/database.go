package db

import (
	"fmt"
	"log"

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
	
	// Gán kết nối vào biến toàn cục
	DB = database
}