package models

import (
	"time"

	"github.com/google/uuid"
)

// Expense: Lưu hóa đơn gốc
type Expense struct {
	BaseModel
	GroupID     uuid.UUID `json:"group_id" gorm:"type:uuid;not null"`
	PayerID     uuid.UUID `json:"payer_id" gorm:"type:uuid;not null"` // Người trả tiền (Chủ nợ)
	Amount      float64   `json:"amount" gorm:"not null"`             // Tổng bill
	Description string    `json:"description"`
	ImageURL    string    `json:"image_url"` // Ảnh chụp hóa đơn (nếu có)

	// Quan hệ: Một hóa đơn sinh ra nhiều khoản nợ
	Debts []Debt `json:"debts" gorm:"foreignKey:ExpenseID"`
	// Thông tin người trả
	Payer User `json:"payer" gorm:"foreignKey:PayerID"`
}

// Debt: Lưu ai nợ ai - Kết quả sau khi chia
type Debt struct {
	BaseModel
	ExpenseID          uuid.UUID  `json:"expense_id" gorm:"type:uuid;not null"`   // Gắn với hóa đơn nào
	FromUserID         uuid.UUID  `json:"from_user_id" gorm:"type:uuid;not null"` // Con nợ (Người phải trả)
	ToUserID           uuid.UUID  `json:"to_user_id" gorm:"type:uuid;not null"`   // Chủ nợ (Người được nhận - PayerID)
	Amount             float64    `json:"amount" gorm:"not null"`                 // Số tiền phải trả
	IsPaid             bool       `json:"is_paid" gorm:"default:false"`
	PaymentWalletID    *uuid.UUID `json:"payment_wallet_id" gorm:"type:uuid"` // Ví được dùng để trả nợ
	ProofImageURL      string     `json:"proof_image_url"`                    // Hình ảnh minh chứng thanh toán
	PaymentNote        string     `json:"payment_note"`                       // Ghi chú của người trả
	PaymentConfirmedAt *time.Time `json:"payment_confirmed_at"`               // Thời gian chủ nợ xác nhận

	Expense  Expense `json:"expense" gorm:"foreignKey:ExpenseID"`    // Đã trả chưa?
	FromUser User    `json:"from_user" gorm:"foreignKey:FromUserID"` // Người nợ
	ToUser   User    `json:"to_user" gorm:"foreignKey:ToUserID"`     // Người được trả
}
