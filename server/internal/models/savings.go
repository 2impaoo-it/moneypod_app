package models

import (
	"time"

	"github.com/google/uuid"
)

// SavingsGoal: Mục tiêu tiết kiệm
type SavingsGoal struct {
	BaseModel
	UserID        uuid.UUID  `json:"user_id" gorm:"type:uuid;not null"`
	Name          string     `json:"name" gorm:"not null"`
	TargetAmount  float64    `json:"target_amount"`                   // Mục tiêu (VD: 50tr)
	CurrentAmount float64    `json:"current_amount" gorm:"default:0"` // Hiện có
	Color         string     `json:"color"`                           // Màu hiển thị (Hex code)
	Icon          string     `json:"icon"`
	Status        string     `json:"status" gorm:"default:'IN_PROGRESS'"` // IN_PROGRESS, COMPLETED
	Deadline      *time.Time `json:"deadline"`                            // Ngày hết hạn (Optional)

	// 🔥 TRƯỜNG ẢO (Virtual Field): Không lưu vào DB, chỉ dùng để trả về JSON
	IsOverdue bool `json:"is_overdue" gorm:"-"`
}

// SavingsTransaction: Lịch sử nạp/rút riêng của quỹ
type SavingsTransaction struct {
	BaseModel
	GoalID   uuid.UUID `json:"goal_id" gorm:"type:uuid;not null"`
	WalletID uuid.UUID `json:"wallet_id" gorm:"type:uuid;not null"` // Lấy tiền từ ví nào
	Amount   float64   `json:"amount" gorm:"not null"`
	Type     string    `json:"type" gorm:"not null"` // 'DEPOSIT' (Nạp) hoặc 'WITHDRAW' (Rút)
	Note     string    `json:"note"`
}
