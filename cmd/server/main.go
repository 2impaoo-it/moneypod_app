package main

import (
	"github.com/2impaoo-it/MoneyPod_Backend/internal/routes"
	"github.com/2impaoo-it/MoneyPod_Backend/pkg/db" // Import package db vừa viết
)

func main() {
	// 1. Kết nối Database đầu tiên
	db.ConnectDatabase()

	// 2. Setup Router
	r := routes.SetupRouter()

	// 3. Chạy Server
	r.Run(":8080")
}