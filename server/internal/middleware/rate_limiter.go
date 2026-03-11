package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// Simple rate limiter using token bucket algorithm
type rateLimiter struct {
	visitors map[string]*visitor
	mu       sync.RWMutex
	rate     time.Duration
	burst    int
}

type visitor struct {
	limiter  *time.Ticker
	lastSeen time.Time
}

var limiter *rateLimiter

func init() {
	limiter = &rateLimiter{
		visitors: make(map[string]*visitor),
		rate:     time.Second, // 1 giây
		burst:    10,          // Tối đa 10 requests
	}

	// Cleanup old visitors every 5 minutes
	go limiter.cleanupVisitors()
}

func (rl *rateLimiter) getVisitor(ip string) *visitor {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	v, exists := rl.visitors[ip]
	if !exists {
		v = &visitor{
			limiter: time.NewTicker(rl.rate),
		}
		rl.visitors[ip] = v
	}

	v.lastSeen = time.Now()
	return v
}

func (rl *rateLimiter) cleanupVisitors() {
	for {
		time.Sleep(5 * time.Minute)
		rl.mu.Lock()
		for ip, v := range rl.visitors {
			if time.Since(v.lastSeen) > 10*time.Minute {
				v.limiter.Stop()
				delete(rl.visitors, ip)
			}
		}
		rl.mu.Unlock()
	}
}

// RateLimitMiddleware giới hạn số request từ một IP
func RateLimitMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		v := limiter.getVisitor(ip)

		select {
		case <-v.limiter.C:
			c.Next()
		default:
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error":   "RATE_LIMIT_EXCEEDED",
				"message": "Quá nhiều yêu cầu. Vui lòng thử lại sau.",
			})
		}
	}
}

// StrictRateLimitMiddleware - Rate limit nghiêm ngặt hơn cho các endpoint nhạy cảm (login, register)
func StrictRateLimitMiddleware() gin.HandlerFunc {
	visitors := make(map[string]*strictVisitor)
	var mu sync.RWMutex

	return func(c *gin.Context) {
		ip := c.ClientIP()

		mu.Lock()
		v, exists := visitors[ip]
		if !exists {
			v = &strictVisitor{
				count:     0,
				resetTime: time.Now().Add(15 * time.Minute),
			}
			visitors[ip] = v
		}

		// Reset nếu hết thời gian
		if time.Now().After(v.resetTime) {
			v.count = 0
			v.resetTime = time.Now().Add(15 * time.Minute)
		}

		// Kiểm tra limit (5 requests per 15 minutes)
		if v.count >= 5 {
			mu.Unlock()
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error":   "RATE_LIMIT_EXCEEDED",
				"message": "Quá nhiều lần thử. Vui lòng đợi 15 phút.",
			})
			return
		}

		v.count++
		mu.Unlock()

		c.Next()
	}
}

type strictVisitor struct {
	count     int
	resetTime time.Time
}
