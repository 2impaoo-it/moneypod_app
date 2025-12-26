package models

import "github.com/google/uuid"

type Wallet struct {
	BaseModel
	Name     string  `json:"name" gorm:"not null"`          // Tên ví (VD: Tiền mặt, VCB)
	Balance  float64 `json:"balance" gorm:"default:0"`      // Số dư
	Currency string  `json:"currency" gorm:"default:'VND'"` // Loại tiền
	UserID   uuid.UUID  `json:"user_id" gorm:"type:uuid"`      // Ví này của ai?
}
