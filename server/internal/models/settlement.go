package models

import "github.com/google/uuid"

// Settlement: Lưu lịch sử trả nợ giữa các thành viên
type Settlement struct {
	BaseModel
	GroupID uuid.UUID `json:"group_id" gorm:"type:uuid;not null"`

	FromUserID uuid.UUID `json:"from_user_id" gorm:"type:uuid;not null"` // Người trả (Con nợ)
	ToUserID   uuid.UUID `json:"to_user_id" gorm:"type:uuid;not null"`   // Người nhận (Chủ nợ)

	WalletID uuid.UUID `json:"wallet_id" gorm:"type:uuid;not null"` // Trừ tiền từ ví nào của người trả
	Amount   float64   `json:"amount" gorm:"not null"`

	Status string `json:"status" gorm:"default:'pending'"` // 'pending' (chờ), 'confirmed' (xong), 'rejected' (từ chối)
}
