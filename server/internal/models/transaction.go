package models

import (
	"time"

	"github.com/google/uuid"
)

type Transaction struct {
	BaseModel
	UserID     uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	WalletID   uuid.UUID `json:"wallet_id" gorm:"type:uuid;not null"`
	Amount     float64   `json:"amount" gorm:"not null"` // Số tiền
	Category   string    `json:"category"`               // Thể loại giao dịch
	Type       string    `json:"type" gorm:"not null"`   // "income" (Thu) hoặc "expense" (Chi)
	Note       string    `json:"note"`
	Date       time.Time `json:"date"`
	ProofImage string    `json:"proof_image"` // URL hình ảnh minh chứng

	User   User   `json:"user" gorm:"foreignKey:UserID"`
	Wallet Wallet `json:"wallet" gorm:"foreignKey:WalletID"`
}
