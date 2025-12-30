package models

// User đại diện cho bảng 'users' trong Database
type User struct {
	BaseModel // Cái này tự động thêm: ID, CreatedAt, UpdatedAt, DeletedAt

	// Email phải duy nhất, không được để trống
	Email string `gorm:"unique;not null" json:"email"`

	// Password lưu Hash, KHÔNG ĐƯỢC để trống.
	// `json:"-"` nghĩa là: Khi gửi dữ liệu về cho Frontend, DÒNG NÀY SẼ BỊ ẨN ĐI (Bảo mật)
	Password string `gorm:"not null" json:"-"`

	FullName  string `gorm:"not null" json:"full_name"`
	AvatarURL string `json:"avatar_url"`
	// 🔥 Sử dụng con trỏ *string để hỗ trợ NULL (Optional Unique)
	// Nếu không nhập SĐT -> nil -> NULL trong DB (Postgres cho phép nhiều NULL)
	// Nếu có nhập -> chuỗi -> DB check Unique bình thường
	Phone    *string `gorm:"unique" json:"phone"`
	FCMToken string  `json:"fcm_token"`
}
