-- SKA-DAN Phase 2 Schema Migration
-- Run this in Supabase SQL Editor
-- Date: 2025-12-19

-- ============================================
-- Messages: Enhanced communication features
-- ============================================

-- Add priority levels (low, normal, high)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS priority TEXT DEFAULT 'normal';

-- Add message types (message, question, urgent)
ALTER TABLE messages ADD COLUMN IF NOT EXISTS "messageType" TEXT DEFAULT 'message';

-- Add threading support
ALTER TABLE messages ADD COLUMN IF NOT EXISTS "parentMessageId" TEXT;

-- Add read/unread status
ALTER TABLE messages ADD COLUMN IF NOT EXISTS "isRead" BOOLEAN DEFAULT false;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS "readAt" TEXT;

-- ============================================
-- Sager: Attention/notification system
-- ============================================

-- Flag for cases requiring attention
ALTER TABLE sager ADD COLUMN IF NOT EXISTS "needsAttention" BOOLEAN DEFAULT false;

-- Note explaining why attention is needed
ALTER TABLE sager ADD COLUMN IF NOT EXISTS "attentionNote" TEXT;

-- Tracking who acknowledged the attention
ALTER TABLE sager ADD COLUMN IF NOT EXISTS "attentionAcknowledgedAt" TEXT;
ALTER TABLE sager ADD COLUMN IF NOT EXISTS "attentionAcknowledgedBy" TEXT;

-- ============================================
-- Users: Activity tracking
-- ============================================

-- Track last active timestamp for each user
ALTER TABLE users ADD COLUMN IF NOT EXISTS "lastActiveAt" TEXT;

-- ============================================
-- Indexes for performance
-- ============================================

-- Index for message threading
CREATE INDEX IF NOT EXISTS idx_messages_parent ON messages("parentMessageId");

-- Index for unread messages
CREATE INDEX IF NOT EXISTS idx_messages_read ON messages("isRead");

-- Index for cases needing attention
CREATE INDEX IF NOT EXISTS idx_sager_attention ON sager("needsAttention");

-- ============================================
-- Verification
-- ============================================

-- Verify messages table
DO $$
BEGIN
    RAISE NOTICE '=== Messages Table Columns ===';
    PERFORM column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'messages'
    ORDER BY ordinal_position;
END $$;

-- Verify sager table
DO $$
BEGIN
    RAISE NOTICE '=== Sager Table Columns ===';
    PERFORM column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'sager'
    ORDER BY ordinal_position;
END $$;

-- Verify users table
DO $$
BEGIN
    RAISE NOTICE '=== Users Table Columns ===';
    PERFORM column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_name = 'users'
    ORDER BY ordinal_position;
END $$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Phase 2 migration completed successfully!';
END $$;

-- ============================================
-- IMPORTANT NOTES
-- ============================================

/*
1. This migration adds new columns to existing tables
2. All new columns are nullable or have defaults to avoid breaking existing data
3. Indexes are created for frequently queried columns
4. The migration is idempotent - safe to run multiple times

AFTER RUNNING THIS MIGRATION:
1. Regenerate Hive adapters in Flutter:
   flutter packages pub run build_runner build --delete-conflicting-outputs

2. Test the app thoroughly:
   - Create/read messages with priorities
   - Set attention flags on cases
   - Verify sync works correctly

3. Clear local storage if you encounter type errors:
   - Web: Clear IndexedDB in browser DevTools
   - Android: Clear app data

ROLLBACK (if needed):
If you need to rollback, run:
ALTER TABLE messages DROP COLUMN IF EXISTS priority;
ALTER TABLE messages DROP COLUMN IF EXISTS "messageType";
ALTER TABLE messages DROP COLUMN IF EXISTS "parentMessageId";
ALTER TABLE messages DROP COLUMN IF EXISTS "isRead";
ALTER TABLE messages DROP COLUMN IF EXISTS "readAt";
ALTER TABLE sager DROP COLUMN IF EXISTS "needsAttention";
ALTER TABLE sager DROP COLUMN IF EXISTS "attentionNote";
ALTER TABLE sager DROP COLUMN IF EXISTS "attentionAcknowledgedAt";
ALTER TABLE sager DROP COLUMN IF EXISTS "attentionAcknowledgedBy";
ALTER TABLE users DROP COLUMN IF EXISTS "lastActiveAt";
DROP INDEX IF EXISTS idx_messages_parent;
DROP INDEX IF EXISTS idx_messages_read;
DROP INDEX IF EXISTS idx_sager_attention;
*/
