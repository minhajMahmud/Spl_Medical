-- Migration: Increase attachment_path column size to support full file paths
-- Date: 2026-01-03
-- Reason: VARCHAR(20) is too small for paths like 'uploaded_results/BK906039/lab_booking_BK780394'

ALTER TABLE test_results 
ALTER COLUMN attachment_path TYPE VARCHAR(255);

-- Add comment for documentation
COMMENT ON COLUMN test_results.attachment_path IS 'Relative path to uploaded result file, max 255 characters';
