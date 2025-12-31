package models

import (
	"time"

	"github.com/google/uuid"
)

// Notification đại diện cho bảng 'notifications' trong Database
type Notification struct {
	BaseModel

	UserID uuid.UUID  `gorm:"not null;index" json:"user_id"`
	Type   string     `gorm:"not null;index" json:"type"` // group, expense, transaction, wallet, savings, system
	Title  string     `gorm:"not null" json:"title"`
	Body   string     `gorm:"not null" json:"body"`
	Data   string     `gorm:"type:jsonb" json:"data"` // Metadata (JSON) - lưu thêm thông tin như group_id, expense_id...
	IsRead bool       `gorm:"default:false;index" json:"is_read"`
	ReadAt *time.Time `json:"read_at,omitempty"`

	// Relations
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// NotificationSetting đại diện cho bảng 'notification_settings' trong Database
type NotificationSetting struct {
	BaseModel

	UserID uuid.UUID `gorm:"unique;not null" json:"user_id"`

	// Group notifications
	GroupExpense       bool `gorm:"default:true" json:"group_expense"`
	GroupMemberAdded   bool `gorm:"default:true" json:"group_member_added"`
	GroupMemberRemoved bool `gorm:"default:true" json:"group_member_removed"`
	GroupDeleted       bool `gorm:"default:true" json:"group_deleted"`
	ExpenseUpdated     bool `gorm:"default:true" json:"expense_updated"`
	ExpenseDeleted     bool `gorm:"default:true" json:"expense_deleted"`

	// Transaction notifications
	TransactionCreated bool `gorm:"default:true" json:"transaction_created"`
	LowBalance         bool `gorm:"default:true" json:"low_balance"`
	BudgetExceeded     bool `gorm:"default:true" json:"budget_exceeded"`
	DailySummary       bool `gorm:"default:false" json:"daily_summary"`

	// Savings notifications
	SavingsGoalReached bool `gorm:"default:true" json:"savings_goal_reached"`
	SavingsReminder    bool `gorm:"default:true" json:"savings_reminder"`
	SavingsProgress    bool `gorm:"default:true" json:"savings_progress"` // 50%, 75%, 90%

	// System notifications
	SystemAnnouncement bool `gorm:"default:true" json:"system_announcement"`
	SecurityAlert      bool `gorm:"default:true" json:"security_alert"`
	AppUpdate          bool `gorm:"default:true" json:"app_update"`
	Maintenance        bool `gorm:"default:true" json:"maintenance"`

	// Relations
	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// Notification Types Constants
const (
	NotificationTypeGroup       = "group"
	NotificationTypeExpense     = "expense"
	NotificationTypeTransaction = "transaction"
	NotificationTypeWallet      = "wallet"
	NotificationTypeSavings     = "savings"
	NotificationTypeSystem      = "system"
	NotificationTypeDebt        = "debt"
)
