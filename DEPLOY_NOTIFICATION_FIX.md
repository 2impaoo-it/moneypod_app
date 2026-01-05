# 🚀 QUICK START: Deploy Notification Optimization

## ⚡ TL;DR - 3 Steps to Deploy

```bash
# 1. Run migration (requires psql or database access)
cd server
psql -U postgres -d moneypod -f migrations/add_fcm_token_validation.sql

# 2. Rebuild and restart server
go build -o bin/server.exe cmd/server/main.go
./bin/server.exe

# 3. Verify (check logs for new messages)
# Look for: "📊 Tìm thấy X users có nợ chưa trả"
```

---

## 📝 Detailed Steps

### Step 1: Backup Database (Optional but Recommended)

```bash
pg_dump -U postgres moneypod > backup_before_migration.sql
```

### Step 2: Run Migration

```bash
# Option A: Using psql
cd d:\HUTECH\moneypod_app\server
psql -U postgres -d moneypod -f migrations/add_fcm_token_validation.sql

# Option B: Using PgAdmin
# - Open PgAdmin
# - Connect to moneypod database
# - Open Query Tool
# - Copy/paste content from migrations/add_fcm_token_validation.sql
# - Execute (F5)
```

**Expected Output:**

```
ALTER TABLE
UPDATE 50
CREATE INDEX
```

### Step 3: Verify Migration

```bash
psql -U postgres -d moneypod -f test_notification_optimization.sql
```

Look for Test 1 output:

```
 column_name         | data_type | column_default
---------------------+-----------+----------------
 fcm_token_valid     | boolean   | true
 fcm_token_updated_at| timestamp |
```

### Step 4: Rebuild Server

```bash
cd d:\HUTECH\moneypod_app\server
go build -o bin/server.exe cmd/server/main.go
```

**Expected:** No errors

### Step 5: Start Server

```bash
./bin/server.exe
```

**Look for these logs:**

```
✅ Đã kết nối Firebase Cloud Messaging!
✅ Debt Reminder Scheduler đã khởi động (chạy mỗi 24h)
```

### Step 6: Wait for Scheduler (or trigger manually)

Scheduler runs:

- **First run:** After 1 minute
- **Subsequent:** Every 24 hours

**Watch for new log format:**

```
🔔 Đang gửi nhắc nhở nợ...
📊 Tìm thấy 10 users có nợ chưa trả
⏭️  Bỏ qua 3 users đã nhận thông báo trong 24h
✅ Đã gửi 7 thông báo nhắc nhở nợ (bỏ qua 3, tổng 10 users)
```

**If invalid token detected:**

```
❌ Lỗi gửi thông báo FCM: Requested entity was not found
🔧 Vô hiệu hóa FCM token cho user <uuid>
```

---

## ✅ Verification Checklist

After deployment, verify:

### 1. Database Structure

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('fcm_token_valid', 'fcm_token_updated_at');
```

✅ Should return 2 rows

### 2. Notification Reduction

```sql
-- Count: old vs new
SELECT
    (SELECT COUNT(*) FROM debts WHERE is_paid = false) as old_count,
    (SELECT COUNT(DISTINCT from_user_id) FROM debts WHERE is_paid = false) as new_count;
```

✅ `new_count` should be much less than `old_count`

### 3. Server Logs

✅ Look for:

- "📊 Tìm thấy X users" (NEW log format)
- No "Requested entity was not found" spam
- Faster execution time

### 4. User Experience

✅ Users should receive:

- 1 notification per 24h (not 12)
- Clear summary message
- No spam

---

## 🐛 Troubleshooting

### Error: "column does not exist"

**Cause:** Migration not run
**Fix:** Run Step 2 (migration) first

### Error: "too many arguments to function"

**Cause:** Old code calling `NewNotificationService()` without `db`
**Fix:** Ensure all changes committed, rebuild

### Error: FCM still showing invalid token errors

**Cause:** Token not disabled yet (first occurrence)
**Expected:** Token will be disabled after first error, then no more errors

### Scheduler not running

**Check:**

```bash
# In server logs, look for:
✅ Debt Reminder Scheduler đã khởi động (chạy mỗi 24h)
```

**Fix:** Ensure `scheduler.StartDebtReminderScheduler()` is called in main.go

---

## 📊 Expected Results

### Before Optimization:

```
Log output every minute:
📥 CreateAndSendNotification: UserID=29a18a18..., Type=debt_reminder
📥 CreateAndSendNotification: UserID=29a18a18..., Type=debt_reminder
📥 CreateAndSendNotification: UserID=29a18a18..., Type=debt_reminder
... (12 times for same user!)
❌ Lỗi gửi thông báo FCM: Requested entity was not found
❌ Lỗi gửi thông báo FCM: Requested entity was not found
... (repeating forever!)
```

### After Optimization:

```
Log output once per 24h:
🔔 Đang gửi nhắc nhở nợ...
📊 Tìm thấy 10 users có nợ chưa trả
⏭️  Bỏ qua 3 users đã nhận thông báo trong 24h
📥 CreateAndSendNotification: UserID=29a18a18..., Type=debt_reminder
✅ FCM: Gửi thông báo thành công
... (only 7 logs for 10 users)
✅ Đã gửi 7 thông báo nhắc nhở nợ (bỏ qua 3, tổng 10 users)

--- First error occurrence ---
❌ Lỗi gửi thông báo FCM: Requested entity was not found
🔧 Vô hiệu hóa FCM token cho user <uuid>

--- Next run (24h later) ---
📊 Tìm thấy 9 users có nợ chưa trả  ← One less (invalid token skipped!)
```

---

## 🎯 Success Metrics

| Metric               | Target | How to Measure   |
| -------------------- | ------ | ---------------- |
| Notification spam    | 0      | User complaints  |
| Invalid token errors | -99%   | Server logs      |
| Execution time       | < 5s   | Log timestamps   |
| DB queries           | -95%   | Database monitor |
| User satisfaction    | ⬆️     | Feedback         |

---

## 📞 Support

If issues persist:

1. Check [NOTIFICATION_OPTIMIZATION_COMPLETE.md](NOTIFICATION_OPTIMIZATION_COMPLETE.md) for details
2. Review [ANALYSIS_NOTIFICATION_ISSUES.md](ANALYSIS_NOTIFICATION_ISSUES.md) for root cause analysis
3. Run test queries in [test_notification_optimization.sql](server/test_notification_optimization.sql)

**Status:** ✅ All code changes implemented and tested
**Build:** ✅ Success
**Ready:** ⚠️ Pending migration
