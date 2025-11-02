-- Location: supabase/migrations/20251102121005_subscription_system_with_trial.sql
-- Schema Analysis: Extending existing journal system with subscription management
-- Integration Type: Addition - New subscription module
-- Dependencies: user_profiles (existing table)

-- 1. Create subscription-related enums
CREATE TYPE public.subscription_status AS ENUM ('trial', 'active', 'expired', 'cancelled', 'past_due');
CREATE TYPE public.subscription_plan AS ENUM ('free', 'premium_monthly', 'premium_yearly');
CREATE TYPE public.payment_status AS ENUM ('pending', 'paid', 'failed', 'refunded');

-- 2. Create subscriptions table
CREATE TABLE public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    plan public.subscription_plan NOT NULL DEFAULT 'free'::public.subscription_plan,
    status public.subscription_status NOT NULL DEFAULT 'trial'::public.subscription_status,
    trial_start_date TIMESTAMPTZ,
    trial_end_date TIMESTAMPTZ,
    subscription_start_date TIMESTAMPTZ,
    subscription_end_date TIMESTAMPTZ,
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    is_auto_renew BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create payment_history table
CREATE TABLE public.payment_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    payment_method TEXT,
    stripe_payment_intent_id TEXT,
    payment_status public.payment_status DEFAULT 'pending'::public.payment_status,
    payment_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Create indexes for performance
CREATE INDEX idx_subscriptions_user_id ON public.subscriptions(user_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_subscriptions_stripe_customer ON public.subscriptions(stripe_customer_id);
CREATE INDEX idx_payment_history_user_id ON public.payment_history(user_id);
CREATE INDEX idx_payment_history_subscription_id ON public.payment_history(subscription_id);

-- 5. Enable Row Level Security
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_history ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies
CREATE POLICY "users_manage_own_subscriptions"
ON public.subscriptions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_view_own_payment_history"
ON public.payment_history
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 7. Functions for subscription management

-- Function to create trial subscription for new users
CREATE OR REPLACE FUNCTION public.create_trial_subscription(user_uuid UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    subscription_id UUID;
    trial_start TIMESTAMPTZ := CURRENT_TIMESTAMP;
    trial_end TIMESTAMPTZ := CURRENT_TIMESTAMP + INTERVAL '30 days';
BEGIN
    -- Check if user already has a subscription
    IF EXISTS (SELECT 1 FROM public.subscriptions WHERE user_id = user_uuid) THEN
        RETURN NULL; -- User already has subscription
    END IF;
    
    -- Create new trial subscription
    INSERT INTO public.subscriptions (
        user_id,
        plan,
        status,
        trial_start_date,
        trial_end_date
    ) VALUES (
        user_uuid,
        'free'::public.subscription_plan,
        'trial'::public.subscription_status,
        trial_start,
        trial_end
    ) RETURNING id INTO subscription_id;
    
    -- Update user_profiles to set is_premium = true during trial
    UPDATE public.user_profiles 
    SET is_premium = true, updated_at = CURRENT_TIMESTAMP
    WHERE id = user_uuid;
    
    RETURN subscription_id;
END;
$$;

-- Function to check if user has active subscription or trial
CREATE OR REPLACE FUNCTION public.has_active_subscription(user_uuid UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM public.subscriptions s
    WHERE s.user_id = user_uuid 
    AND (
        (s.status = 'trial' AND s.trial_end_date > CURRENT_TIMESTAMP) OR
        (s.status = 'active' AND s.subscription_end_date > CURRENT_TIMESTAMP)
    )
)
$$;

-- Function to get subscription details
CREATE OR REPLACE FUNCTION public.get_user_subscription(user_uuid UUID)
RETURNS TABLE(
    subscription_id UUID,
    plan TEXT,
    status TEXT,
    is_trial BOOLEAN,
    days_remaining INTEGER,
    trial_end_date TIMESTAMPTZ,
    subscription_end_date TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id,
        s.plan::TEXT,
        s.status::TEXT,
        (s.status = 'trial')::BOOLEAN,
        CASE 
            WHEN s.status = 'trial' THEN EXTRACT(DAY FROM s.trial_end_date - CURRENT_TIMESTAMP)::INTEGER
            WHEN s.status = 'active' THEN EXTRACT(DAY FROM s.subscription_end_date - CURRENT_TIMESTAMP)::INTEGER
            ELSE 0
        END,
        s.trial_end_date,
        s.subscription_end_date
    FROM public.subscriptions s
    WHERE s.user_id = user_uuid
    ORDER BY s.created_at DESC
    LIMIT 1;
END;
$$;

-- Function to expire trial subscriptions
CREATE OR REPLACE FUNCTION public.expire_trial_subscriptions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    expired_count INTEGER := 0;
BEGIN
    -- Update expired trial subscriptions
    UPDATE public.subscriptions 
    SET 
        status = 'expired'::public.subscription_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE status = 'trial' 
    AND trial_end_date <= CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    -- Update user_profiles to remove premium access for expired trials
    UPDATE public.user_profiles 
    SET 
        is_premium = false,
        updated_at = CURRENT_TIMESTAMP
    WHERE id IN (
        SELECT user_id FROM public.subscriptions 
        WHERE status = 'expired' 
        AND NOT public.has_active_subscription(user_id)
    );
    
    RETURN expired_count;
END;
$$;

-- 8. Update the existing handle_new_user function to create trial subscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    user_subscription_id UUID;
BEGIN
    -- Create user profile
    INSERT INTO public.user_profiles (id, email, full_name, role, is_premium)
    VALUES (
        NEW.id, 
        NEW.email, 
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'free_user')::public.user_role,
        true  -- Set to true initially for trial
    );
    
    -- Create 30-day trial subscription
    SELECT public.create_trial_subscription(NEW.id) INTO user_subscription_id;
    
    RETURN NEW;
END;
$$;

-- 9. Function to handle updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_subscription_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- 10. Create triggers
CREATE TRIGGER on_subscriptions_updated
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.handle_subscription_updated_at();

CREATE TRIGGER on_payment_history_updated
    BEFORE UPDATE ON public.payment_history
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 11. Mock data for testing subscriptions
DO $$
DECLARE
    existing_user_id UUID;
    test_subscription_id UUID;
BEGIN
    -- Get existing user for testing
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
        -- Create sample subscription data
        INSERT INTO public.subscriptions (
            user_id,
            plan,
            status,
            trial_start_date,
            trial_end_date
        ) VALUES (
            existing_user_id,
            'free'::public.subscription_plan,
            'trial'::public.subscription_status,
            CURRENT_TIMESTAMP - INTERVAL '5 days',
            CURRENT_TIMESTAMP + INTERVAL '25 days'
        ) ON CONFLICT DO NOTHING
        RETURNING id INTO test_subscription_id;
        
        -- Create sample payment history
        IF test_subscription_id IS NOT NULL THEN
            INSERT INTO public.payment_history (
                user_id,
                subscription_id,
                amount,
                currency,
                payment_method,
                payment_status,
                payment_date
            ) VALUES (
                existing_user_id,
                test_subscription_id,
                0.00,
                'USD',
                'trial',
                'paid'::public.payment_status,
                CURRENT_TIMESTAMP
            );
        END IF;
        
        RAISE NOTICE 'Created test subscription data for user: %', existing_user_id;
    ELSE
        RAISE NOTICE 'No existing users found. Create users first.';
    END IF;
END $$;

-- 12. Comments for documentation
COMMENT ON TABLE public.subscriptions IS 'User subscription management with trial support';
COMMENT ON TABLE public.payment_history IS 'Payment transaction history for subscriptions';
COMMENT ON FUNCTION public.create_trial_subscription(UUID) IS 'Creates a 30-day free trial for new users';
COMMENT ON FUNCTION public.has_active_subscription(UUID) IS 'Checks if user has active subscription or trial';
COMMENT ON FUNCTION public.get_user_subscription(UUID) IS 'Returns detailed subscription information for a user';
COMMENT ON FUNCTION public.expire_trial_subscriptions() IS 'Batch function to expire trial subscriptions - run daily';