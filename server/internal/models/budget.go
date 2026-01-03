package models

import "github.com/google/uuid"

// Budget represents a spending limit for a category in a specific month
type Budget struct {
	BaseModel
	UserID   uuid.UUID `json:"user_id" gorm:"type:uuid;not null;index"`
	Category string    `json:"category" gorm:"not null"`        // Category name (e.g., "Ăn uống", "Di chuyển")
	Amount   float64   `json:"amount" gorm:"not null"`          // Budget limit
	Month    int       `json:"month" gorm:"not null;index"`     // Month (1-12)
	Year     int       `json:"year" gorm:"not null;index"`      // Year (e.g., 2026)
}

// TableName returns the table name for GORM
func (Budget) TableName() string {
	return "budgets"
}
