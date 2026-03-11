# Build Stage
FROM golang:1.25-alpine AS builder
WORKDIR /app

# Copy file module trước để tận dụng cache
COPY go.mod go.sum ./
RUN go mod download

# Copy toàn bộ code và build
COPY . .
RUN go build -o moneypod-server cmd/server/main.go 


# Run Stage
FROM alpine:latest
WORKDIR /root/

# Cài đặt dữ liệu múi giờ
RUN apk add --no-cache tzdata
# Thiết lập múi giờ mặc định cho container
ENV TZ=Asia/Ho_Chi_Minh

COPY --from=builder /app/moneypod-server .


EXPOSE 8080
CMD ["./moneypod-server"]