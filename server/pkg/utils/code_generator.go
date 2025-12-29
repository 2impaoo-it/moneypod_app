package utils

import (
	"math/rand"
	"time"
)

// GenerateInviteCode tạo mã mời ngẫu nhiên với độ dài xác định
func GenerateInviteCode(length int) string {
	const charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	seededRand := rand.New(rand.NewSource(time.Now().UnixNano()))

	code := make([]byte, length)
	for i := range code {
		code[i] = charset[seededRand.Intn(len(charset))]
	}

	return string(code)
}
