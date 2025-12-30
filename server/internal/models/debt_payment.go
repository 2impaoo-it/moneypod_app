package models

import "github.com/google/uuid"

// DebtPaymentRequest: Lưu request trả nợ từ con nợ
type DebtPaymentRequest struct {
	BaseModel
	DebtID          uuid.UUID `json:"debt_id" gorm:"type:uuid;not null"`
	FromUserID      uuid.UUID `json:"from_user_id" gorm:"type:uuid;not null"`      // Người nợ (người gửi request)
	ToUserID        uuid.UUID `json:"to_user_id" gorm:"type:uuid;not null"`        // Chủ nợ (người nhận request)
	PaymentWalletID uuid.UUID `json:"payment_wallet_id" gorm:"type:uuid;not null"` // Ví người nợ dùng để trả
	Amount          float64   `json:"amount" gorm:"not null"`                      // Số tiền trả
	Status          string    `json:"status" gorm:"default:'PENDING'"`             // PENDING, CONFIRMED, REJECTED
	Note            string    `json:"note"`                                        // Ghi chú

	// Thông tin xác nhận từ chủ nợ
	ReceiveWalletID *uuid.UUID `json:"receive_wallet_id" gorm:"type:uuid"` // Ví chủ nợ nhận tiền (chỉ có khi confirmed)

	// Quan hệ
	Debt Debt `json:"debt" gorm:"foreignKey:DebtID"`
}
