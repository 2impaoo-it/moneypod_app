package models

import "gorm.io/gorm"

type Group struct {
	gorm.Model
	Name      string `json:"name" gorm:"not null"`
	Code      string `json:"code" gorm:"unique;not null"` // Mã mời (VD: ABC123)
	CreatorID uint   `json:"creator_id" gorm:"not null"`

	// Quan hệ: Một nhóm có nhiều thành viên
	Members []GroupMember `json:"members" gorm:"foreignKey:GroupID"`
}

type GroupMember struct {
	gorm.Model
	GroupID uint   `json:"group_id" gorm:"not null"`
	UserID  uint   `json:"user_id" gorm:"not null"`
	Role    string `json:"role" gorm:"default:'member'"` // 'admin' hoặc 'member'

	// Balance: Số dư trong nhóm (Quan trọng cho tính năng chia tiền sau này)
	Balance float64 `json:"balance" gorm:"default:0"`

	// Preload để lấy tên user hiển thị lên App
	User User `json:"user" gorm:"foreignKey:UserID"`
}
