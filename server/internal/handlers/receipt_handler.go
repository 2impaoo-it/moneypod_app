package handlers

import (
	"io"
	"net/http"

	"github.com/2impaoo-it/moneypod_app/server/internal/services"
	"github.com/gin-gonic/gin"
)

type ReceiptHandler struct {
	service *services.ReceiptService
}

func NewReceiptHandler(service *services.ReceiptService) *ReceiptHandler {
	return &ReceiptHandler{service: service}
}

// Scan godoc
// @Summary      Quét hóa đơn bằng AI
// @Description  Upload ảnh hóa đơn và sử dụng Gemini AI để trích xuất thông tin (số tiền, danh mục...)
// @Tags         Receipt
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        images  formData  file  true  "File ảnh hóa đơn (key: images hoặc image)"
// @Success      200  {object}  map[string]interface{} "Quét thành công"
// @Failure      400  {object}  map[string]interface{} "Không nhận được file"
// @Failure      500  {object}  map[string]interface{} "Lỗi xử lý AI"
// @Router       /receipts/scan [post]
func (h *ReceiptHandler) Scan(c *gin.Context) {
	// 1. Nhận file từ Request (Key là "images" - hỗ trợ multi-file từ Flutter)
	file, _, err := c.Request.FormFile("images")
	if err != nil {
		// Fallback thử key "image" nếu không tìm thấy "images"
		file, _, err = c.Request.FormFile("image")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Vui lòng gửi file ảnh với key là 'images' hoặc 'image'"})
			return
		}
	}
	defer file.Close()

	// 2. Đọc file thành byte array
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi đọc file"})
		return
	}

	// 3. Gọi Service Gemini xử lý
	result, err := h.service.AnalyzeReceipt(fileBytes)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Lỗi xử lý AI: " + err.Error()})
		return
	}

	// 4. Trả kết quả về cho Flutter
	c.JSON(http.StatusOK, gin.H{
		"message": "Quét thành công",
		"data":    result,
	})
}
