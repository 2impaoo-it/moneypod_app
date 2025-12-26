package models

type ReceiptData struct {
	Merchant string  `json:"merchant"` // Tên cửa hàng (VD: Highlands)
	Amount   float64 `json:"amount"`   // Tổng tiền (VD: 59000)
	Date     string  `json:"date"`     // Ngày hóa đơn (VD: 2023-10-25)
	Category string  `json:"category"` // Gợi ý: food, transport, shopping...
	Note     string  `json:"note"`     // Ghi chú thêm
}
