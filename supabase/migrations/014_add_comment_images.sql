-- Add images column to comments for photo attachments
-- Migration: 014_add_comment_images.sql

-- ============================================
-- ADD IMAGES COLUMN TO COMMENTS
-- ============================================
ALTER TABLE public.comments ADD COLUMN images TEXT[] DEFAULT '{}';

-- ============================================
-- STORAGE BUCKET FOR COMMENT IMAGES
-- ============================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('comment-images', 'comment-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for comment-images bucket
-- Users can upload files to their own folder
CREATE POLICY "Users can upload comment images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'comment-images'
        AND auth.uid() = (storage.foldername(name))[1]::uuid
    );

-- Anyone can view comment images (public bucket)
CREATE POLICY "Anyone can view comment images"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'comment-images');

-- Users can update their own comment images
CREATE POLICY "Users can update their own comment images"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'comment-images'
        AND auth.uid() = (storage.foldername(name))[1]::uuid
    );

-- Users can delete their own comment images
CREATE POLICY "Users can delete their own comment images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'comment-images'
        AND auth.uid() = (storage.foldername(name))[1]::uuid
    );
