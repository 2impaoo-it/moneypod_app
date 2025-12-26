package config

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DBHost     string
	DBUser     string
	DBPassword string
	DBName     string
	DBPort     string
	DBTimezone string

	JWTSecretKey string
	GeminiAPIKey string

	ServerPort string
	GinMode    string
}

var AppConfig *Config

// LoadConfig đọc file .env và khởi tạo config
func LoadConfig() {
	// Load file .env
	err := godotenv.Load()
	if err != nil {
		log.Println("⚠️  Không tìm thấy file .env, sử dụng biến môi trường hệ thống")
	}

	AppConfig = &Config{
		DBHost:     getEnv("DB_HOST", "localhost"),
		DBUser:     getEnv("DB_USER", "postgres"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		DBName:     getEnv("DB_NAME", "moneypod"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBTimezone: getEnv("DB_TIMEZONE", "Asia/Ho_Chi_Minh"),

		JWTSecretKey: getEnv("JWT_SECRET_KEY", "default_secret_key"),
		GeminiAPIKey: getEnv("GEMINI_API_KEY", ""),

		ServerPort: getEnv("SERVER_PORT", "8080"),
		GinMode:    getEnv("GIN_MODE", "debug"),
	}

	fmt.Println("✅ Đã load cấu hình từ .env")
}

// getEnv lấy giá trị từ environment variable, nếu không có thì dùng default
func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// GetDatabaseDSN trả về connection string cho database
func (c *Config) GetDatabaseDSN() string {
	return fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=%s",
		c.DBHost, c.DBUser, c.DBPassword, c.DBName, c.DBPort, c.DBTimezone,
	)
}
