package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// BaseModel thay thế cho gorm.Model
type BaseModel struct {
	// ID là UUID, tự động sinh ngẫu nhiên khi tạo mới
	ID        uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

// Hook: Trước khi tạo, nếu chưa có ID thì tự tạo (Phòng hờ DB không hỗ trợ gen_random_uuid)
func (base *BaseModel) BeforeCreate(tx *gorm.DB) (err error) {
	if base.ID == uuid.Nil {
		base.ID = uuid.New()
	}
	return
}
