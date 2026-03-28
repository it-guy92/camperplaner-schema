SET lock_timeout = '10s';
SET statement_timeout = '15min';

CREATE TABLE IF NOT EXISTS public.billing_customers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    provider text NOT NULL DEFAULT 'stripe' CHECK (provider = 'stripe'),
    provider_customer_id text NOT NULL,
    email_snapshot text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT billing_customers_user_id_key UNIQUE (user_id),
    CONSTRAINT billing_customers_provider_customer_id_key UNIQUE (provider_customer_id)
);

COMMENT ON TABLE public.billing_customers IS
'Maps a CamperPlaner profile to its billing provider customer record.';

COMMENT ON COLUMN public.billing_customers.user_id IS
'References public.profiles.id. One billing customer row per user.';

COMMENT ON COLUMN public.billing_customers.provider_customer_id IS
'Provider-native customer identifier, currently Stripe customer id.';


CREATE TABLE IF NOT EXISTS public.billing_subscriptions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    billing_customer_id uuid NOT NULL REFERENCES public.billing_customers(id) ON DELETE CASCADE,
    provider text NOT NULL DEFAULT 'stripe' CHECK (provider = 'stripe'),
    provider_subscription_id text NOT NULL,
    provider_price_id text,
    plan_code text NOT NULL CHECK (plan_code IN ('free', 'premium_monthly', 'premium_yearly')),
    status text NOT NULL CHECK (status IN (
        'incomplete',
        'incomplete_expired',
        'trialing',
        'active',
        'past_due',
        'canceled',
        'unpaid',
        'paused'
    )),
    current_period_start timestamptz,
    current_period_end timestamptz,
    cancel_at_period_end boolean NOT NULL DEFAULT false,
    canceled_at timestamptz,
    trial_end timestamptz,
    last_webhook_event_id text,
    last_synced_at timestamptz NOT NULL DEFAULT now(),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT billing_subscriptions_provider_subscription_id_key UNIQUE (provider_subscription_id)
);

COMMENT ON TABLE public.billing_subscriptions IS
'Stores normalized subscription lifecycle state imported from the billing provider.';

COMMENT ON COLUMN public.billing_subscriptions.plan_code IS
'Normalized commercial plan code consumed by product logic.';

COMMENT ON COLUMN public.billing_subscriptions.status IS
'Normalized provider subscription status, aligned to Stripe subscription lifecycle values.';


CREATE TABLE IF NOT EXISTS public.user_entitlements (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_code text NOT NULL DEFAULT 'free' CHECK (plan_code IN ('free', 'premium_monthly', 'premium_yearly')),
    is_premium boolean NOT NULL DEFAULT false,
    features jsonb NOT NULL DEFAULT '{"can_export_trip": false, "can_use_advanced_filters": false, "can_use_trip_templates": false}'::jsonb,
    limits jsonb NOT NULL DEFAULT '{"max_saved_trips": 2, "max_vehicle_profiles": 1, "max_favorites": 20}'::jsonb,
    source_subscription_id uuid REFERENCES public.billing_subscriptions(id) ON DELETE SET NULL,
    effective_from timestamptz NOT NULL DEFAULT now(),
    effective_until timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT user_entitlements_user_id_key UNIQUE (user_id),
    CONSTRAINT user_entitlements_features_object_check CHECK (jsonb_typeof(features) = 'object'),
    CONSTRAINT user_entitlements_limits_object_check CHECK (jsonb_typeof(limits) = 'object')
);

COMMENT ON TABLE public.user_entitlements IS
'Current product-readable entitlement snapshot for a user. Missing row must be treated as free.';

COMMENT ON COLUMN public.user_entitlements.features IS
'Capability flags keyed by feature code, e.g. can_export_trip.';

COMMENT ON COLUMN public.user_entitlements.limits IS
'Product usage limits keyed by limit code, e.g. max_saved_trips.';


CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_user_id
    ON public.billing_subscriptions (user_id);

CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_user_status
    ON public.billing_subscriptions (user_id, status);

CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_billing_customer_id
    ON public.billing_subscriptions (billing_customer_id);

CREATE INDEX IF NOT EXISTS idx_billing_subscriptions_current_period_end
    ON public.billing_subscriptions (current_period_end DESC NULLS LAST);

CREATE INDEX IF NOT EXISTS idx_user_entitlements_plan_code
    ON public.user_entitlements (plan_code);

CREATE INDEX IF NOT EXISTS idx_user_entitlements_source_subscription_id
    ON public.user_entitlements (source_subscription_id)
    WHERE source_subscription_id IS NOT NULL;


DO $$
DECLARE
    tbl text;
    tables text[] := ARRAY[
        'billing_customers',
        'billing_subscriptions',
        'user_entitlements'
    ];
BEGIN
    FOREACH tbl IN ARRAY tables
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_updated_at ON public.%I;',
            tbl,
            tbl
        );

        EXECUTE format(
            'CREATE TRIGGER trg_%I_updated_at
             BEFORE UPDATE ON public.%I
             FOR EACH ROW
             EXECUTE FUNCTION public.update_updated_at_column();',
            tbl,
            tbl
        );
    END LOOP;
END $$;


ALTER TABLE public.billing_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_entitlements ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'billing_customers'
          AND policyname = 'Users can view their own billing customer'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can view their own billing customer" ON public.billing_customers FOR SELECT USING (auth.uid() = user_id)';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'billing_customers'
          AND policyname = 'Service role can manage billing customers'
    ) THEN
        EXECUTE 'CREATE POLICY "Service role can manage billing customers" ON public.billing_customers FOR ALL USING (auth.role() = ''service_role'') WITH CHECK (auth.role() = ''service_role'')';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'billing_subscriptions'
          AND policyname = 'Users can view their own billing subscriptions'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can view their own billing subscriptions" ON public.billing_subscriptions FOR SELECT USING (auth.uid() = user_id)';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'billing_subscriptions'
          AND policyname = 'Service role can manage billing subscriptions'
    ) THEN
        EXECUTE 'CREATE POLICY "Service role can manage billing subscriptions" ON public.billing_subscriptions FOR ALL USING (auth.role() = ''service_role'') WITH CHECK (auth.role() = ''service_role'')';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'user_entitlements'
          AND policyname = 'Users can view their own entitlements'
    ) THEN
        EXECUTE 'CREATE POLICY "Users can view their own entitlements" ON public.user_entitlements FOR SELECT USING (auth.uid() = user_id)';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'user_entitlements'
          AND policyname = 'Service role can manage user entitlements'
    ) THEN
        EXECUTE 'CREATE POLICY "Service role can manage user entitlements" ON public.user_entitlements FOR ALL USING (auth.role() = ''service_role'') WITH CHECK (auth.role() = ''service_role'')';
    END IF;
END $$;


CREATE OR REPLACE FUNCTION public.get_current_user_entitlements()
RETURNS TABLE (
    user_id uuid,
    plan_code text,
    is_premium boolean,
    features jsonb,
    limits jsonb,
    subscription_status text,
    current_period_end timestamptz,
    cancel_at_period_end boolean,
    source_subscription_id uuid,
    effective_from timestamptz,
    effective_until timestamptz,
    updated_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    WITH auth_context AS (
        SELECT auth.uid() AS user_id
    ),
    resolved_entitlement AS (
        SELECT
            ue.user_id,
            ue.plan_code,
            ue.is_premium,
            ue.features,
            ue.limits,
            ue.source_subscription_id,
            ue.effective_from,
            ue.effective_until,
            ue.updated_at
        FROM public.user_entitlements ue
        JOIN auth_context ac
          ON ac.user_id IS NOT NULL
         AND ue.user_id = ac.user_id
    )
    SELECT
        ce.user_id,
        ce.plan_code,
        ce.is_premium,
        ce.features,
        ce.limits,
        bs.status AS subscription_status,
        bs.current_period_end,
        COALESCE(bs.cancel_at_period_end, false) AS cancel_at_period_end,
        ce.source_subscription_id,
        ce.effective_from,
        ce.effective_until,
        ce.updated_at
    FROM resolved_entitlement ce
    LEFT JOIN public.billing_subscriptions bs
      ON bs.id = ce.source_subscription_id

    UNION ALL

    SELECT
        ac.user_id,
        'free'::text AS plan_code,
        false AS is_premium,
        '{"can_export_trip": false, "can_use_advanced_filters": false, "can_use_trip_templates": false}'::jsonb AS features,
        '{"max_saved_trips": 2, "max_vehicle_profiles": 1, "max_favorites": 20}'::jsonb AS limits,
        NULL::text AS subscription_status,
        NULL::timestamptz AS current_period_end,
        false AS cancel_at_period_end,
        NULL::uuid AS source_subscription_id,
        now() AS effective_from,
        NULL::timestamptz AS effective_until,
        now() AS updated_at
    FROM auth_context ac
    WHERE ac.user_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM resolved_entitlement);
$$;

REVOKE ALL ON FUNCTION public.get_current_user_entitlements() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_current_user_entitlements() TO authenticated, service_role;

COMMENT ON FUNCTION public.get_current_user_entitlements() IS
'Returns the current authenticated users entitlement snapshot with a safe free fallback when no entitlement row exists.';

NOTIFY pgrst, 'reload schema';
