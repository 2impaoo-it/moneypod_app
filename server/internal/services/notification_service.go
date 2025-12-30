package services

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

type NotificationService struct {
	client *messaging.Client
}

// NewNotificationService initializes Firebase App and Messaging Client
func NewNotificationService(credentialsFile string) (*NotificationService, error) {
	ctx := context.Background()
	
    // Note: If credentialsFile is empty, it might try to use default credentials (env var).
    // For local dev, you might need a serviceAccountKey.json
    var opt option.ClientOption
    if credentialsFile != "" {
        opt = option.WithCredentialsFile(credentialsFile)
    }

    // Initialize App
    var app *firebase.App
    var err error
    
    if opt != nil {
        app, err = firebase.NewApp(ctx, nil, opt)
    } else {
        app, err = firebase.NewApp(ctx, nil)
    }

	if err != nil {
		return nil, fmt.Errorf("error initializing firebase app: %v", err)
	}

	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("error getting messaging client: %v", err)
	}

	return &NotificationService{client: client}, nil
}

// SendMulticastNotification sends a message to multiple tokens with data payload
func (s *NotificationService) SendMulticastNotification(tokens []string, title, body string, data map[string]string) {
	if s == nil || s.client == nil || len(tokens) == 0 {
        log.Println("NotificationService: Skipped sending (nil client or no tokens)")
		return
	}

	message := &messaging.MulticastMessage{
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data:   data,
		Tokens: tokens,
	}

	br, err := s.client.SendMulticast(context.Background(), message)
	if err != nil {
		log.Printf("NotificationService: Error sending multicast: %v\n", err)
        return
	}

	log.Printf("NotificationService: Sent %d messages. Success: %d, Failure: %d\n", br.SuccessCount+br.FailureCount, br.SuccessCount, br.FailureCount)
    
    // Optional: Handle invalid tokens cleanup here if needed
    if br.FailureCount > 0 {
        for idx, resp := range br.Responses {
            if !resp.Success {
                // Determine which token failed: tokens[idx]
                // Error: resp.Error
                log.Printf("Failed to send to token %s: %v", tokens[idx], resp.Error)
            }
        }
    }
}
