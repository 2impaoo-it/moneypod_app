package models

import "github.com/google/uuid"

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
}

// Debt: Lưu ai nợ ai - Kết quả sau khi chia
type Debt struct {
	BaseModel
	ExpenseID  uuid.UUID `json:"expense_id" gorm:"type:uuid;not null"`   // Gắn với hóa đơn nào
	FromUserID uuid.UUID `json:"from_user_id" gorm:"type:uuid;not null"` // Con nợ (Người phải trả)
	ToUserID   uuid.UUID `json:"to_user_id" gorm:"type:uuid;not null"`   // Chủ nợ (Người được nhận - PayerID)
	Amount     float64   `json:"amount" gorm:"not null"`                 // Số tiền phải trả
	IsPaid     bool      `json:"is_paid" gorm:"default:false"`

	Expense Expense `json:"expense" gorm:"foreignKey:ExpenseID"` // Đã trả chưa?
}
