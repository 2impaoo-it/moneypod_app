-- ====================================
-- TEST SCRIPT: Verify Notification Optimization
-- ====================================

-- Test 1: Check new columns exist
SELECT 
    column_name, 
    data_type, 
    column_default
FROM information_schema.columns
WHERE table_name = 'users' 
AND column_name IN ('fcm_token_valid', 'fcm_token_updated_at');

-- Expected: 2 rows showing both columns

-- Test 2: Count users by token validity
SELECT 
    fcm_token_valid,
    COUNT(*) as user_count,
    COUNT(CASE WHEN fcm_token IS NOT NULL AND fcm_token != '' THEN 1 END) as with_token
FROM users
GROUP BY fcm_token_valid;

-- Expected: All users should have fcm_token_valid = true initially

-- Test 3: Simulate debt reminder query (NEW VERSION)
SELECT 
    d.from_user_id,
    COUNT(DISTINCT d.id) as debt_count,
    SUM(d.amount) as total_amount,
    u.fcm_token,
    u.fcm_token_valid,
    STRING_AGG(DISTINCT g.name, ', ') as group_names
FROM debts d
JOIN expenses e ON d.expense_id = e.id
JOIN groups g ON e.group_id = g.id
JOIN users u ON d.from_user_id = u.id
WHERE d.is_paid = false 
AND u.fcm_token != ''
AND u.fcm_token_valid = true
GROUP BY d.from_user_id, u.fcm_token, u.fcm_token_valid
ORDER BY debt_count DESC
LIMIT 10;

-- Expected: Users grouped with their total debts

-- Test 4: Compare OLD vs NEW notification count
-- OLD: Number of individual debt notifications
SELECT COUNT(*) as old_notification_count
FROM debts d
JOIN users u ON d.from_user_id = u.id
WHERE d.is_paid = false 
AND u.fcm_token != '';

-- NEW: Number of grouped notifications (1 per user)
SELECT COUNT(DISTINCT d.from_user_id) as new_notification_count
FROM debts d
JOIN users u ON d.from_user_id = u.id
WHERE d.is_paid = false 
AND u.fcm_token != ''
AND u.fcm_token_valid = true;

-- Calculate reduction percentage
WITH old_count AS (
    SELECT COUNT(*) as cnt
    FROM debts d
    JOIN users u ON d.from_user_id = u.id
    WHERE d.is_paid = false 
    AND u.fcm_token != ''
),
new_count AS (
    SELECT COUNT(DISTINCT d.from_user_id) as cnt
    FROM debts d
    JOIN users u ON d.from_user_id = u.id
    WHERE d.is_paid = false 
    AND u.fcm_token != ''
    AND u.fcm_token_valid = true
)
SELECT 
    old_count.cnt as old_notifications,
    new_count.cnt as new_notifications,
    old_count.cnt - new_count.cnt as reduction,
    ROUND(((old_count.cnt - new_count.cnt)::numeric / old_count.cnt * 100), 2) as reduction_percentage
FROM old_count, new_count;

-- Test 5: Find user with most debts (test case for spam issue)
SELECT 
    u.id,
    u.email,
    COUNT(*) as debt_count,
    SUM(d.amount) as total_debt,
    u.fcm_token_valid
FROM debts d
JOIN users u ON d.from_user_id = u.id
WHERE d.is_paid = false
GROUP BY u.id, u.email, u.fcm_token_valid
ORDER BY debt_count DESC
LIMIT 1;

-- Expected: Should show user 29a18a18-b406-4d25-a086-0e3b75f840a7 with ~12 debts

-- Test 6: Check notification history (after running scheduler)
SELECT 
    type,
    user_id,
    title,
    body,
    created_at,
    data::json->'debt_count' as debt_count,
    data::json->'total_amount' as total_amount
FROM notifications
WHERE type = 'debt_reminder'
ORDER BY created_at DESC
LIMIT 10;

-- Expected: New notifications should have debt_count and total_amount in data

-- Test 7: Verify no duplicate notifications in 24h
SELECT 
    user_id,
    COUNT(*) as notification_count,
    MAX(created_at) as last_sent
FROM notifications
WHERE type = 'debt_reminder'
AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Expected: 0 rows (no duplicates)

-- Test 8: Simulate invalid token scenario
-- (Run this to manually test auto-disable feature)
/*
UPDATE users 
SET fcm_token_valid = false,
    fcm_token_updated_at = NOW()
WHERE email = 'test@example.com';

-- Then check if scheduler skips this user
SELECT * FROM users WHERE email = 'test@example.com';
*/
