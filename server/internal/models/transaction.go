package models

import (
	"time"

	"gorm.io/gorm"
)

type Transaction struct {
	gorm.Model
	UserID   uint      `json:"user_id" gorm:"not null"`
	WalletID uint      `json:"wallet_id" gorm:"not null"`
	Amount   float64   `json:"amount" gorm:"not null"` // Số tiền
	Category string    `json:"category"`               // Thể loại giao dịch
	Type     string    `json:"type" gorm:"not null"`   // "income" (Thu) hoặc "expense" (Chi)
	Note     string    `json:"note"`
	Date     time.Time `json:"date"`
}
