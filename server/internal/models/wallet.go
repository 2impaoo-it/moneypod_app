package models

import "gorm.io/gorm"

type Wallet struct {
	gorm.Model
	Name     string  `json:"name" gorm:"not null"`          // Tên ví (VD: Tiền mặt, VCB)
	Balance  float64 `json:"balance" gorm:"default:0"`      // Số dư
	Currency string  `json:"currency" gorm:"default:'VND'"` // Loại tiền
	UserID   uint    `json:"user_id" gorm:"not null"`       // Ví này của ai?
}
