package models

import "github.com/google/uuid"

type Group struct {
	BaseModel
	Name      string    `json:"name" gorm:"not null"`
	Code      string    `json:"code" gorm:"unique;not null"` // Mã mời (VD: ABC123)
	CreatorID uuid.UUID `json:"creator_id" gorm:"type:uuid;not null"`

	// Quan hệ: Một nhóm có nhiều thành viên
	Members []GroupMember `json:"members" gorm:"foreignKey:GroupID"`
}

type GroupMember struct {
	BaseModel
	GroupID uuid.UUID `json:"group_id" gorm:"type:uuid;not null"`
	UserID  uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	Role    string    `json:"role" gorm:"default:'member'"` // 'admin' hoặc 'member'

	// Balance: Số dư trong nhóm (Quan trọng cho tính năng chia tiền sau này)
	Balance float64 `json:"balance" gorm:"default:0"`

	// Preload để lấy tên user hiển thị lên App
	User User `json:"user" gorm:"foreignKey:UserID"`
}
