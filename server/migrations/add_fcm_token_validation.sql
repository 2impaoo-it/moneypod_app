-- Migration: Add FCM Token Validation Columns
-- Created: 2026-01-05
-- Purpose: Track FCM token validity to prevent wasted API calls

-- Step 1: Add new columns
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS fcm_token_valid BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS fcm_token_updated_at TIMESTAMP;

-- Step 2: Set existing tokens as valid
UPDATE users 
SET fcm_token_valid = true 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- Step 3: Add index for performance
CREATE INDEX IF NOT EXISTS idx_users_fcm_token_valid 
ON users(fcm_token_valid) 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- Rollback script (if needed):
-- ALTER TABLE users DROP COLUMN IF EXISTS fcm_token_valid;
-- ALTER TABLE users DROP COLUMN IF EXISTS fcm_token_updated_at;
-- DROP INDEX IF EXISTS idx_users_fcm_token_valid;
