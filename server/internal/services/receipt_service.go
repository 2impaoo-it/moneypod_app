package services

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

type ReceiptService struct {
	client *genai.Client
}

func NewReceiptService(apiKey string) (*ReceiptService, error) {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, err
	}
	return &ReceiptService{client: client}, nil
}

func (s *ReceiptService) AnalyzeReceipt(imageData []byte) (*models.ReceiptData, error) {
	ctx := context.Background()
	model := s.client.GenerativeModel("gemini-2.5-flash")

	// Cấu hình để Gemini trả về JSON chuẩn
	model.ResponseMIMEType = "application/json"

	// Câu lệnh (Prompt) "thần thánh"
	prompt := []genai.Part{
		genai.ImageData("jpeg", imageData),
		genai.Text(`
			Bạn là một trợ lý kế toán AI. Hãy phân tích hình ảnh hóa đơn này và trích xuất thông tin dưới dạng JSON.
			Cấu trúc JSON yêu cầu:
			{
				"merchant": "Tên cửa hàng hoặc nhà cung cấp",
				"amount": Số tiền tổng cộng cuối cùng (kiểu số, không có dấu phẩy ngăn cách hàng nghìn),
				"date": "Ngày tháng trên hóa đơn (định dạng DD/MM/YYYY)",
				"category": "Dựa vào tên cửa hàng, hãy đoán 1 trong các loại sau: 'food', 'transport', 'shopping', 'entertainment', 'salary', 'other'",
				"note": "Ghi chú thêm nếu có"
			}
			Nếu không tìm thấy thông tin nào, hãy để null hoặc 0. Đừng giải thích gì thêm, chỉ trả về JSON.
		`),
	}

	resp, err := model.GenerateContent(ctx, prompt...)
	if err != nil {
		return nil, err
	}

	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return nil, errors.New("không đọc được nội dung từ ảnh")
	}

	// Lấy chuỗi JSON từ phản hồi
	jsonStr := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])

	// Làm sạch chuỗi (đôi khi Gemini thêm markdown ```json ... ```)
	jsonStr = strings.TrimPrefix(jsonStr, "```json")
	jsonStr = strings.TrimSuffix(jsonStr, "```")
	jsonStr = strings.TrimSpace(jsonStr)

	// Parse JSON sang Struct Go
	var result models.ReceiptData
	if err := json.Unmarshal([]byte(jsonStr), &result); err != nil {
		return nil, errors.New("lỗi phân tích dữ liệu JSON từ AI: " + err.Error())
	}

	return &result, nil
}
