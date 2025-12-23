package models

import "gorm.io/gorm"

// GroupExpense: Lưu hóa đơn tổng (Ví dụ: Đi ăn lẩu hết 300k do Bảo trả)
type GroupExpense struct {
	gorm.Model
	GroupID  uint    `json:"group_id"`
	PaidByID uint    `json:"paid_by_id"` // Người trả tiền
	Amount   float64 `json:"amount"`     // Tổng tiền
	Note     string  `json:"note"`       // Ghi chú (VD: Ăn tối)

	// Quan hệ: Một hóa đơn có nhiều người cùng chia (Splits)
	Splits []ExpenseSplit `json:"splits" gorm:"foreignKey:GroupExpenseID"`
}

// ExpenseSplit: Lưu chi tiết chia tiền (Ví dụ: An nợ 100k, Bình nợ 100k)
type ExpenseSplit struct {
	gorm.Model
	GroupExpenseID uint    `json:"group_expense_id"`
	UserID         uint    `json:"user_id"`
	Amount         float64 `json:"amount"` // Số tiền người này phải chịu
}
