package main

import (
	"context"
	"fmt"
	"log"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

func main() {
	ctx := context.Background()
	// ⚠️ THAY KEY CỦA BẠN VÀO ĐÂY
	client, err := genai.NewClient(ctx, option.WithAPIKey("AIzaSyAa4ZfbVUypMKeuYlZtZ6b72PhAqba8TN0"))
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	fmt.Println("--- DANH SÁCH MODEL KHẢ DỤNG ---")
	iter := client.ListModels(ctx)
	for {
		m, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		// Chỉ in ra model nào hỗ trợ tạo nội dung (generateContent)
		for _, method := range m.SupportedGenerationMethods {
			if method == "generateContent" {
				fmt.Println("✅ Model:", m.Name)
				break
			}
		}
	}
	fmt.Println("-------------------------------")
}
