-- Kiểm tra user có bao nhiêu khoản nợ chưa trả
SELECT 
    d.from_user_id,
    u.email,
    COUNT(*) as total_unpaid_debts,
    SUM(d.amount) as total_debt_amount
FROM debts d
JOIN users u ON d.from_user_id = u.id
WHERE d.is_paid = false
GROUP BY d.from_user_id, u.email
HAVING COUNT(*) > 5
ORDER BY COUNT(*) DESC;

-- Chi tiết các khoản nợ của user 29a18a18-b406-4d25-a086-0e3b75f840a7
SELECT 
    d.id as debt_id,
    d.from_user_id,
    d.to_user_id,
    d.amount,
    e.description as expense_desc,
    g.name as group_name,
    d.created_at
FROM debts d
JOIN expenses e ON d.expense_id = e.id
JOIN groups g ON e.group_id = g.id
WHERE d.from_user_id = '29a18a18-b406-4d25-a086-0e3b75f840a7'
AND d.is_paid = false
ORDER BY d.created_at DESC;
