-- =============================================================
-- Database Webhook Setup for Push Notifications
-- Run this in Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/hwjjwenymlgxbfwdtrbr/sql/new
-- =============================================================
-- NOTE: Edge Function must be deployed with --no-verify-jwt flag:
--   supabase functions deploy send-notification --no-verify-jwt
-- =============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Create function to call the Edge Function when a message is inserted
CREATE OR REPLACE FUNCTION notify_on_new_message()
RETURNS TRIGGER AS $$
DECLARE
  edge_function_url TEXT := 'https://hwjjwenymlgxbfwdtrbr.supabase.co/functions/v1/send-notification';
  anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3amp3ZW55bWxneGJmd2R0cmJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM2MTc4ODEsImV4cCI6MjA3OTE5Mzg4MX0.hlOBlhPbG1msAVZH1J9E-1x1B7FkccZYR3OmlRqV2io';
  payload JSONB;
  request_id BIGINT;
BEGIN
  -- Build payload matching webhook format
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'messages',
    'schema', 'public',
    'record', jsonb_build_object(
      'id', NEW.id,
      'sagId', NEW."sagId",
      'userId', NEW."userId",
      'userName', NEW."userName",
      'text', NEW.text,
      'timestamp', NEW.timestamp,
      'targetUserId', NEW."targetUserId",
      'targetUserName', NEW."targetUserName"
    ),
    'old_record', NULL
  );

  -- Make async HTTP request to Edge Function using pg_net
  SELECT net.http_post(
    url := edge_function_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || anon_key
    ),
    body := payload
  ) INTO request_id;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail the insert
    RAISE WARNING 'Failed to send notification: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if any
DROP TRIGGER IF EXISTS on_message_insert ON messages;

-- Create trigger on messages table
CREATE TRIGGER on_message_insert
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION notify_on_new_message();

-- Verify the setup
SELECT
  tgname as trigger_name,
  tgrelid::regclass as table_name,
  proname as function_name
FROM pg_trigger t
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE tgrelid = 'messages'::regclass;
