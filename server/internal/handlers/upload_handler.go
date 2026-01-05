package handlers

import (
	"net/http"

	"github.com/2impaoo-it/moneypod_app/server/internal/services"
	"github.com/gin-gonic/gin"
)

type UploadHandler struct {
	storageService *services.StorageService
}

// Constructor
func NewUploadHandler(storageService *services.StorageService) *UploadHandler {
	return &UploadHandler{storageService: storageService}
}

// API: Upload ảnh lên Cloudinary
// Method: POST /api/v1/upload
// Body: Form-Data (key = "file")

// UploadImage godoc
// @Summary      Upload ảnh lên Cloudinary
// @Description  Upload file ảnh lên Cloudinary và trả về URL
// @Tags         Upload
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        file  formData  file  true  "File ảnh cần upload"
// @Success      200  {object}  map[string]interface{} "Upload thành công, trả về URL"
// @Failure      400  {object}  map[string]interface{} "Không nhận được file"
// @Failure      500  {object}  map[string]interface{} "Lỗi upload"
// @Router       /upload [post]
func (h *UploadHandler) UploadImage(c *gin.Context) {
	// 1. Nhận file từ request (Form Data)
	// Lưu ý: Key gửi lên phải là "file" (hoặc bạn đổi thành "image" tùy ý, nhưng phải thống nhất với Flutter)
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Vui lòng gửi file ảnh với key là 'file'",
		})
		return
	}
	defer file.Close()

	// 2. Validate kích thước (Optional) - Ví dụ giới hạn 5MB
	// if header.Size > 5*1024*1024 {
	// 	c.JSON(http.StatusBadRequest, gin.H{"error": "File quá lớn (max 5MB)"})
	// 	return
	// }

	// 3. Gọi Service để upload lên Cloudinary
	url, err := h.storageService.UploadFile(file, header)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "Lỗi upload ảnh: " + err.Error(),
		})
		return
	}

	// 4. Trả về URL ảnh cho App Flutter
	c.JSON(http.StatusOK, gin.H{
		"message": "Upload thành công",
		"url":     url,
	})
}
