-- Location: supabase/migrations/20241102115143_journal_system_with_auth.sql
-- Schema Analysis: No existing schema detected - creating fresh journal system
-- Integration Type: Fresh project setup with authentication
-- Dependencies: None - creating complete journal system

-- 1. Types and Enums
CREATE TYPE public.user_role AS ENUM ('admin', 'premium_user', 'free_user');
CREATE TYPE public.journal_mood AS ENUM ('happy', 'sad', 'excited', 'calm', 'anxious', 'angry', 'grateful', 'peaceful', 'neutral', 'stressed');
CREATE TYPE public.sync_status AS ENUM ('pending', 'synced', 'failed', 'local_only');

-- 2. Core Tables
-- User profiles table (intermediary for PostgREST compatibility)
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'free_user'::public.user_role,
    is_premium BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_sync_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Journal entries table
CREATE TABLE public.journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    mood public.journal_mood,
    entry_date DATE NOT NULL,
    word_count INTEGER DEFAULT 0,
    has_ai_insight BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    sync_status public.sync_status DEFAULT 'synced'::public.sync_status,
    local_created_at TIMESTAMPTZ,
    local_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- AI insights table for generated insights
CREATE TABLE public.ai_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID REFERENCES public.journal_entries(id) ON DELETE CASCADE,
    insight_type TEXT NOT NULL, -- 'mood_analysis', 'patterns', 'suggestions'
    insight_content JSONB NOT NULL,
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Mood tracking table for analytics
CREATE TABLE public.mood_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    mood public.journal_mood NOT NULL,
    tracking_date DATE NOT NULL,
    entry_count INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, tracking_date, mood)
);

-- 3. Essential Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_journal_entries_user_id ON public.journal_entries(user_id);
CREATE INDEX idx_journal_entries_entry_date ON public.journal_entries(entry_date);
CREATE INDEX idx_journal_entries_mood ON public.journal_entries(mood);
CREATE INDEX idx_journal_entries_sync_status ON public.journal_entries(sync_status);
CREATE INDEX idx_ai_insights_entry_id ON public.ai_insights(entry_id);
CREATE INDEX idx_mood_tracking_user_date ON public.mood_tracking(user_id, tracking_date);

-- 4. Functions for automatic profile creation and updates
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'free_user'::public.user_role)
  );  
  RETURN NEW;
END;
$$;

-- Update function for timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Function to update mood tracking
CREATE OR REPLACE FUNCTION public.update_mood_tracking()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.mood IS NOT NULL THEN
    INSERT INTO public.mood_tracking (user_id, mood, tracking_date, entry_count)
    VALUES (NEW.user_id, NEW.mood, NEW.entry_date, 1)
    ON CONFLICT (user_id, tracking_date, mood)
    DO UPDATE SET entry_count = mood_tracking.entry_count + 1;
  END IF;
  RETURN NEW;
END;
$$;

-- 5. RLS Setup
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_tracking ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies using Pattern 1 and Pattern 2
-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for journal entries
CREATE POLICY "users_manage_own_journal_entries"
ON public.journal_entries
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Pattern 2: Simple user ownership for AI insights
CREATE POLICY "users_manage_own_ai_insights"
ON public.ai_insights
FOR ALL
TO authenticated
USING (EXISTS (
  SELECT 1 FROM public.journal_entries je 
  WHERE je.id = ai_insights.entry_id AND je.user_id = auth.uid()
));

-- Pattern 2: Simple user ownership for mood tracking
CREATE POLICY "users_manage_own_mood_tracking"
ON public.mood_tracking
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 7. Triggers
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_user_profiles_updated
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_journal_entries_updated
  BEFORE UPDATE ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER on_journal_entry_mood_tracking
  AFTER INSERT OR UPDATE ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION public.update_mood_tracking();

-- 8. Complete Mock Data for Testing
DO $$
DECLARE
    user1_auth_id UUID := gen_random_uuid();
    user2_auth_id UUID := gen_random_uuid();
    entry1_id UUID := gen_random_uuid();
    entry2_id UUID := gen_random_uuid();
    entry3_id UUID := gen_random_uuid();
BEGIN
    -- Create auth users with complete field structure
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (user1_auth_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'journal.user@emotionanchor.com', crypt('journalpass123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Sarah Johnson"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (user2_auth_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'premium.user@emotionanchor.com', crypt('premiumpass123', gen_salt('bf', 10)), now(), now(), now(),
         '{"full_name": "Michael Chen"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

    -- Create journal entries
    INSERT INTO public.journal_entries (id, user_id, title, content, mood, entry_date, word_count, has_ai_insight, is_pinned, sync_status)
    VALUES
        (entry1_id, user1_auth_id, 'Productive Monday', 
         'Had a great start to the week. Completed my morning workout and felt energized throughout the day. The new project at work is challenging but exciting. I am grateful for the opportunities that come my way and feel optimistic about what lies ahead.',
         'happy'::public.journal_mood, CURRENT_DATE - INTERVAL '1 day', 42, true, false, 'synced'::public.sync_status),
        (entry2_id, user1_auth_id, 'Weekend Reflections', 
         'Spent quality time with family this weekend. Feeling grateful for these moments of connection and peace. Sometimes slowing down is exactly what we need. The quiet moments remind me of what truly matters in life.',
         'calm'::public.journal_mood, CURRENT_DATE - INTERVAL '2 days', 38, true, true, 'synced'::public.sync_status),
        (entry3_id, user2_auth_id, 'Morning Meditation Success', 
         'Started the day with 20 minutes of meditation. The clarity and peace I felt afterward reminded me why this practice is so important for my wellbeing. Today I feel centered and ready to tackle whatever comes my way.',
         'peaceful'::public.journal_mood, CURRENT_DATE, 41, true, false, 'synced'::public.sync_status);

    -- Create AI insights for entries
    INSERT INTO public.ai_insights (entry_id, insight_type, insight_content, confidence_score)
    VALUES
        (entry1_id, 'mood_analysis', 
         '{"dominant_emotion": "happiness", "energy_level": "high", "themes": ["productivity", "gratitude", "optimism"]}'::jsonb, 0.92),
        (entry2_id, 'patterns', 
         '{"pattern": "family_connection", "frequency": "weekly", "impact": "positive", "recommendation": "maintain_family_time"}'::jsonb, 0.85),
        (entry3_id, 'suggestions', 
         '{"suggestion": "continue_meditation_practice", "reason": "consistent_positive_impact", "frequency": "daily"}'::jsonb, 0.88);

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END $$;