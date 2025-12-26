package services

import (
	"github.com/2impaoo-it/moneypod_app/backend/internal/models"
	"github.com/2impaoo-it/moneypod_app/backend/internal/repositories"
	"github.com/google/uuid"
)

type WalletService struct {
	walletRepo *repositories.WalletRepository
}

func NewWalletService(walletRepo *repositories.WalletRepository) *WalletService {
	return &WalletService{walletRepo: walletRepo}
}

func (s *WalletService) CreateWallet(userID uuid.UUID, name string, initialBalance float64) error {
	newWallet := &models.Wallet{
		UserID:  userID,
		Name:    name,
		Balance: initialBalance,
	}
	return s.walletRepo.CreateWallet(newWallet)
}

func (s *WalletService) GetMyWallets(userID uuid.UUID) ([]models.Wallet, error) {
	return s.walletRepo.GetWalletsByUserID(userID)
}
