package services

import (
	"errors"

	"github.com/2impaoo-it/moneypod_app/server/internal/models"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// BudgetService handles all budget-related business logic
type BudgetService struct {
	db *gorm.DB
}

// NewBudgetService creates a new BudgetService
func NewBudgetService(db *gorm.DB) *BudgetService {
	return &BudgetService{db: db}
}

// CreateBudget creates a new budget for a category in a specific month
func (s *BudgetService) CreateBudget(userID uuid.UUID, category string, amount float64, month, year int) (*models.Budget, error) {
	// Check if budget already exists for this category/month/year
	var existing models.Budget
	err := s.db.Where("user_id = ? AND category = ? AND month = ? AND year = ?", userID, category, month, year).First(&existing).Error
	if err == nil {
		return nil, errors.New("ngân sách cho danh mục này trong tháng đã tồn tại")
	}

	budget := models.Budget{
		UserID:   userID,
		Category: category,
		Amount:   amount,
		Month:    month,
		Year:     year,
	}

	if err := s.db.Create(&budget).Error; err != nil {
		return nil, err
	}

	return &budget, nil
}

// GetBudgets returns all budgets for a user in a specific month/year
func (s *BudgetService) GetBudgets(userID uuid.UUID, month, year int) ([]BudgetWithSpent, error) {
	var budgets []models.Budget

	query := s.db.Where("user_id = ?", userID)
	if month > 0 {
		query = query.Where("month = ?", month)
	}
	if year > 0 {
		query = query.Where("year = ?", year)
	}

	if err := query.Find(&budgets).Error; err != nil {
		return nil, err
	}

	// Calculate spent for each budget from transactions
	result := make([]BudgetWithSpent, len(budgets))
	for i, b := range budgets {
		spent := s.calculateSpent(userID, b.Category, b.Month, b.Year)
		result[i] = BudgetWithSpent{
			Budget: b,
			Spent:  spent,
		}
	}

	return result, nil
}

// GetBudgetByID returns a specific budget
func (s *BudgetService) GetBudgetByID(budgetID, userID uuid.UUID) (*BudgetWithSpent, error) {
	var budget models.Budget
	if err := s.db.Where("id = ? AND user_id = ?", budgetID, userID).First(&budget).Error; err != nil {
		return nil, errors.New("ngân sách không tồn tại")
	}

	spent := s.calculateSpent(userID, budget.Category, budget.Month, budget.Year)
	return &BudgetWithSpent{
		Budget: budget,
		Spent:  spent,
	}, nil
}

// UpdateBudget updates a budget's amount
func (s *BudgetService) UpdateBudget(budgetID, userID uuid.UUID, amount float64, category string) error {
	var budget models.Budget
	if err := s.db.Where("id = ? AND user_id = ?", budgetID, userID).First(&budget).Error; err != nil {
		return errors.New("ngân sách không tồn tại")
	}

	updates := map[string]interface{}{}
	if amount > 0 {
		updates["amount"] = amount
	}
	if category != "" {
		updates["category"] = category
	}

	return s.db.Model(&budget).Updates(updates).Error
}

// DeleteBudget deletes a budget
func (s *BudgetService) DeleteBudget(budgetID, userID uuid.UUID) error {
	result := s.db.Where("id = ? AND user_id = ?", budgetID, userID).Delete(&models.Budget{})
	if result.RowsAffected == 0 {
		return errors.New("ngân sách không tồn tại")
	}
	return result.Error
}

// calculateSpent calculates total expense for a category in a month/year
func (s *BudgetService) calculateSpent(userID uuid.UUID, category string, month, year int) float64 {
	var total float64

	s.db.Model(&models.Transaction{}).
		Select("COALESCE(SUM(amount), 0)").
		Where("user_id = ? AND category = ? AND type = ? AND EXTRACT(MONTH FROM date) = ? AND EXTRACT(YEAR FROM date) = ?",
			userID, category, "expense", month, year).
		Scan(&total)

	return total
}

// BudgetWithSpent is a response struct that includes calculated spent amount
type BudgetWithSpent struct {
	models.Budget
	Spent float64 `json:"spent"`
}
