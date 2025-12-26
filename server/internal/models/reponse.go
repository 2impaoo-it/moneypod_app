package models

// DashboardData: Cấu trúc dữ liệu trả về cho màn hình Home
type DashboardData struct {
	UserInfo           User          `json:"user_info"`           // Tên, Avatar...
	TotalBalance       float64       `json:"total_balance"`       // Tổng tiền tất cả các ví cộng lại
	Wallets            []Wallet      `json:"wallets"`             // Danh sách các ví
	RecentTransactions []Transaction `json:"recent_transactions"` // 5-10 giao dịch gần nhất
}
