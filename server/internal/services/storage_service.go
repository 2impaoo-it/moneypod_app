package services

import (
	"context"
	"mime/multipart"

	"github.com/2impaoo-it/moneypod_app/backend/internal/config"
	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
)

type StorageService struct {
	cld *cloudinary.Cloudinary
}

// Khởi tạo Cloudinary
func NewStorageService() (*StorageService, error) {
	// Đọc config từ .env
	cld, err := cloudinary.NewFromParams(
		config.AppConfig.CloudinaryCloudName,
		config.AppConfig.CloudinaryAPIKey,
		config.AppConfig.CloudinaryAPISecret,
	)
	if err != nil {
		return nil, err
	}

	return &StorageService{cld: cld}, nil
}

// Hàm Upload File
func (s *StorageService) UploadFile(file multipart.File, fileHeader *multipart.FileHeader) (string, error) {
	ctx := context.Background()

	// Upload lên Cloudinary
	// Folder: "moneypod_uploads" là tên thư mục trên mây, bạn đặt gì cũng được
	resp, err := s.cld.Upload.Upload(ctx, file, uploader.UploadParams{
		Folder: "moneypod_uploads",
	})

	if err != nil {
		return "", err
	}

	// Trả về đường dẫn ảnh (SecureURL là https)
	return resp.SecureURL, nil
}
