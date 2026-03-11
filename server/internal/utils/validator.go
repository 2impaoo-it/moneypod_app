package utils

import (
	"errors"
	"regexp"
	"strings"
	"unicode"
)

// ValidateEmail kiểm tra định dạng email hợp lệ
func ValidateEmail(email string) error {
	if email == "" {
		return errors.New("email không được để trống")
	}

	// Regex pattern cơ bản cho email
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(email) {
		return errors.New("định dạng email không hợp lệ")
	}

	return nil
}

// ValidatePassword kiểm tra độ mạnh của password
func ValidatePassword(password string) error {
	if len(password) < 8 {
		return errors.New("mật khẩu phải có ít nhất 8 ký tự")
	}

	if len(password) > 72 {
		return errors.New("mật khẩu không được quá 72 ký tự")
	}

	var (
		hasUpper   = false
		hasLower   = false
		hasNumber  = false
		hasSpecial = false
	)

	for _, char := range password {
		switch {
		case unicode.IsUpper(char):
			hasUpper = true
		case unicode.IsLower(char):
			hasLower = true
		case unicode.IsNumber(char):
			hasNumber = true
		case unicode.IsPunct(char) || unicode.IsSymbol(char):
			hasSpecial = true
		}
	}

	if !hasUpper {
		return errors.New("mật khẩu phải chứa ít nhất 1 chữ hoa")
	}
	if !hasLower {
		return errors.New("mật khẩu phải chứa ít nhất 1 chữ thường")
	}
	if !hasNumber {
		return errors.New("mật khẩu phải chứa ít nhất 1 chữ số")
	}
	if !hasSpecial {
		return errors.New("mật khẩu phải chứa ít nhất 1 ký tự đặc biệt")
	}

	return nil
}

// ValidatePhoneNumber kiểm tra số điện thoại Việt Nam
func ValidatePhoneNumber(phone string) error {
	if phone == "" {
		return errors.New("số điện thoại không được để trống")
	}

	// Loại bỏ khoảng trắng và dấu -
	phone = strings.ReplaceAll(phone, " ", "")
	phone = strings.ReplaceAll(phone, "-", "")

	// Kiểm tra định dạng: 0XXXXXXXXX hoặc +84XXXXXXXXX (9-11 số)
	phoneRegex := regexp.MustCompile(`^(\+84|84|0)(3|5|7|8|9)([0-9]{8})$`)
	if !phoneRegex.MatchString(phone) {
		return errors.New("số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam")
	}

	return nil
}

// SanitizeInput loại bỏ các ký tự nguy hiểm khỏi input
func SanitizeInput(input string) string {
	// Loại bỏ SQL injection patterns cơ bản
	input = strings.ReplaceAll(input, "'", "")
	input = strings.ReplaceAll(input, "\"", "")
	input = strings.ReplaceAll(input, "--", "")
	input = strings.ReplaceAll(input, ";", "")
	input = strings.ReplaceAll(input, "<script>", "")
	input = strings.ReplaceAll(input, "</script>", "")

	return strings.TrimSpace(input)
}
