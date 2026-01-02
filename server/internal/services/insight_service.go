package services

import (
	"context"
	"fmt"
	"time"

	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
	"gorm.io/gorm"
)

type InsightService struct {
	db     *gorm.DB
	client *genai.Client
}

func NewInsightService(db *gorm.DB, apiKey string) (*InsightService, error) {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		return nil, err
	}
	return &InsightService{
		db:     db,
		client: client,
	}, nil
}

// GetMonthlyInsight - Tạo insight thông minh cho tháng hiện tại dựa trên giao dịch
func (s *InsightService) GetMonthlyInsight(userID string, month, year int) (string, error) {
	ctx := context.Background()

	// 1. Lấy tất cả giao dịch của user trong tháng
	var transactions []models.Transaction
	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)
	endDate := startDate.AddDate(0, 1, 0).Add(-time.Second)

	err := s.db.Where("user_id = ? AND date BETWEEN ? AND ?", userID, startDate, endDate).
		Find(&transactions).Error
	if err != nil {
		return "", fmt.Errorf("lỗi khi lấy giao dịch: %w", err)
	}

	// 2. Nếu không có giao dịch nào
	if len(transactions) == 0 {
		return "Bạn chưa có giao dịch nào trong tháng này. Hãy bắt đầu ghi chép chi tiêu để nhận insight!", nil
	}

	// 3. Tạo summary data để gửi cho Gemini
	var totalIncome, totalExpense float64
	categoryExpense := make(map[string]float64)
	categoryIncome := make(map[string]float64)

	for _, tx := range transactions {
		if tx.Type == "expense" {
			totalExpense += tx.Amount
			categoryExpense[tx.Category] += tx.Amount
		} else if tx.Type == "income" {
			totalIncome += tx.Amount
			categoryIncome[tx.Category] += tx.Amount
		}
	}

	// 4. Tạo prompt cho Gemini
	prompt := fmt.Sprintf(`
Phân tích chi tiêu tháng %d/%d. Trả về 1-2 CÂU DUY NHẤT (tối đa 60 từ):

Thu nhập: %.0f VNĐ | Chi tiêu: %.0f VNĐ
Chi tiêu theo danh mục: %v
Giao dịch: %d

YÊU CẦU:
- Chỉ 1-2 câu ngắn gọn
- Nhận xét 1 điểm nổi bật + đề xuất 1 hành động
- Giọng thân thiện
- KHÔNG giải thích, KHÔNG phân tích dài

VD: "Chi ăn uống 1.5 triệu đồng (40%% tổng chi), hãy nấu ăn nhà nhiều hơn để tiết kiệm nhé!"
`,
		month, year,
		totalIncome,
		totalExpense,
		categoryExpense,
		len(transactions),
	)

	// 5. Gọi Gemini API
	model := s.client.GenerativeModel("gemini-2.5-flash")
	resp, err := model.GenerateContent(ctx, genai.Text(prompt))
	if err != nil {
		return "", fmt.Errorf("lỗi khi gọi Gemini API: %w", err)
	}

	// 6. Parse response
	if len(resp.Candidates) == 0 || len(resp.Candidates[0].Content.Parts) == 0 {
		return "Không thể tạo insight lúc này. Vui lòng thử lại sau.", nil
	}

	insight := fmt.Sprintf("%v", resp.Candidates[0].Content.Parts[0])
	return insight, nil
}
