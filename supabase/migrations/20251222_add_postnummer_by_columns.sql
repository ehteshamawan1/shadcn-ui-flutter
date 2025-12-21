-- Add missing postnummer and by columns to sager table
-- Run in Supabase SQL Editor or via CLI

ALTER TABLE sager ADD COLUMN IF NOT EXISTS "postnummer" TEXT;
ALTER TABLE sager ADD COLUMN IF NOT EXISTS "by" TEXT;

-- Add index for postnummer lookups
CREATE INDEX IF NOT EXISTS idx_sager_postnummer ON sager("postnummer");

-- Success message
DO $$ BEGIN RAISE NOTICE 'Added postnummer and by columns to sager table'; END $$;
