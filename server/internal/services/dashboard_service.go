package services

import (
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/google/uuid"
)

type DashboardService struct {
	userRepo   *repositories.UserRepository
	walletRepo *repositories.WalletRepository
	transRepo  *repositories.TransactionRepository // Bạn cần đảm bảo đã có Repo này (hoặc truy vấn trực tiếp DB)
}

func NewDashboardService(u *repositories.UserRepository, w *repositories.WalletRepository, t *repositories.TransactionRepository) *DashboardService {
	return &DashboardService{userRepo: u, walletRepo: w, transRepo: t}
}

func (s *DashboardService) GetDashboardData(userID uuid.UUID) (*models.DashboardData, error) {
	// 1. Lấy thông tin User
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return nil, err
	}

	// 2. Lấy danh sách Ví
	wallets, err := s.walletRepo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}

	// 3. Tính tổng tiền (Cộng dồn balance các ví)
	var totalBalance float64 = 0
	for _, w := range wallets {
		totalBalance += w.Balance
	}

	// 4. Lấy 5 giao dịch gần nhất (Cần viết thêm hàm này trong TransactionRepo nếu chưa có)
	// Tạm thời nếu bạn chưa tách Repo cho Transaction thì gọi DB trực tiếp ở đây cũng được,
	// nhưng chuẩn là phải gọi qua Repo. Giả sử ta có hàm GetRecent này.
	transactions, err := s.transRepo.GetRecent(userID, 5)
	if err != nil {
		// Nếu lỗi lấy giao dịch, có thể trả về mảng rỗng thay vì báo lỗi server
		transactions = []models.Transaction{}
	}

	// 5. Đóng gói trả về
	return &models.DashboardData{
		UserInfo:           *user,
		TotalBalance:       totalBalance,
		Wallets:            wallets,
		RecentTransactions: transactions,
	}, nil
}
