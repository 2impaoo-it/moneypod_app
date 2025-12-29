package models

import (
	"github.com/google/uuid"
)

type Group struct {
	BaseModel
	Name        string `json:"name" gorm:"not null"`
	Description string `json:"description"`
	InviteCode  string `json:"invite_code" gorm:"unique;not null;index"`

	// Quan hệ
	Members  []GroupMember `json:"members"`
	Expenses []Expense     `json:"expenses"`
}

type GroupMember struct {
	BaseModel
	GroupID uuid.UUID `json:"group_id" gorm:"type:uuid;not null"`
	UserID  uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	Role    string    `json:"role" gorm:"default:'member'"` // 'leader' hoặc 'member'

	User User `json:"user" gorm:"foreignKey:UserID"`
}
