package models

import "github.com/google/uuid"

// GroupExpense: Lưu hóa đơn tổng (Ví dụ: Đi ăn lẩu hết 300k do Bảo trả)
type GroupExpense struct {
	BaseModel
	GroupID  uuid.UUID `json:"group_id" gorm:"type:uuid"`
	PaidByID uuid.UUID `json:"paid_by_id" gorm:"type:uuid"` // Người trả tiền
	Amount   float64   `json:"amount"`                      // Tổng tiền
	Note     string    `json:"note"`                        // Ghi chú (VD: Ăn tối)

	// Quan hệ: Một hóa đơn có nhiều người cùng chia (Splits)
	Splits []ExpenseSplit `json:"splits" gorm:"foreignKey:GroupExpenseID"`
}

// ExpenseSplit: Lưu chi tiết chia tiền (Ví dụ: An nợ 100k, Bình nợ 100k)
type ExpenseSplit struct {
	BaseModel
	GroupExpenseID uuid.UUID `json:"group_expense_id" gorm:"type:uuid"`
	UserID         uuid.UUID `json:"user_id" gorm:"type:uuid"`
	Amount         float64   `json:"amount"` // Số tiền người này phải chịu
}
