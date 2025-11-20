-- ==================================================================
-- Flutter Finance App - Supabase Schema Rebuild
-- Generated: 2025-11-17
-- This script recreates all application tables, views, functions, RLS
-- policies, and helper objects required by the Flutter client.
-- ==================================================================

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = off;
SET search_path = public;

-- ------------------------------------------------------------------
-- 1. SAFETY CLEANUP
-- ------------------------------------------------------------------
DO $$
BEGIN
    -- Drop dependent views first
    EXECUTE 'DROP VIEW IF EXISTS transactions CASCADE';

    -- Drop triggers explicitly to avoid dependency noise (guarded in case tables do not yet exist)
    IF to_regclass('public.expenses') IS NOT NULL THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_expense_budget_guard ON expenses';
    END IF;

    IF to_regclass('public.expense_participants') IS NOT NULL THEN
        EXECUTE 'DROP TRIGGER IF EXISTS trg_expense_participant_status ON expense_participants';
    END IF;

    -- Drop helper functions
    EXECUTE 'DROP FUNCTION IF EXISTS fn_set_updated_timestamp() CASCADE';
    EXECUTE 'DROP FUNCTION IF EXISTS fn_budget_guard() CASCADE';
    EXECUTE 'DROP FUNCTION IF EXISTS fn_refresh_expense_status() CASCADE';
    EXECUTE 'DROP FUNCTION IF EXISTS add_group_creator_as_admin(uuid, uuid) CASCADE';
    EXECUTE 'DROP FUNCTION IF EXISTS fn_is_group_member(uuid, uuid) CASCADE';
    EXECUTE 'DROP FUNCTION IF EXISTS fn_is_group_admin(uuid, uuid) CASCADE';
    EXECUTE 'DROP FUNCTION IF EXISTS handle_new_user() CASCADE';

    -- Drop auth trigger (table always exists in auth schema)
    EXECUTE 'DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users';

    -- Drop tables in reverse dependency order
    EXECUTE 'DROP TABLE IF EXISTS budget_categories CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS budgets CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS notifications CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS settlements CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS expense_participants CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS expenses CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS group_members CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS groups CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS friends CASCADE';
    EXECUTE 'DROP TABLE IF EXISTS profiles CASCADE';

    -- Drop custom types last
    EXECUTE 'DROP TYPE IF EXISTS friend_status CASCADE';
    EXECUTE 'DROP TYPE IF EXISTS group_member_role CASCADE';
    EXECUTE 'DROP TYPE IF EXISTS settlement_status CASCADE';
    EXECUTE 'DROP TYPE IF EXISTS notification_kind CASCADE';
    EXECUTE 'DROP TYPE IF EXISTS recurring_frequency CASCADE';
END$$;

-- ------------------------------------------------------------------
-- 2. REQUIRED EXTENSIONS
-- ------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------
-- 3. DOMAIN & ENUM DEFINITIONS
-- ------------------------------------------------------------------
CREATE TYPE friend_status AS ENUM ('pending', 'accepted', 'rejected', 'blocked');
CREATE TYPE group_member_role AS ENUM ('owner', 'admin', 'member');
CREATE TYPE settlement_status AS ENUM ('pending', 'completed', 'cancelled');
CREATE TYPE notification_kind AS ENUM (
    'system',
    'friend_request',
    'friend_response',
    'expense_created',
    'expense_updated',
    'settlement',
    'settlement_paid',
    'budget_limit',
    'group_invitation'
);
CREATE TYPE recurring_frequency AS ENUM (
    'none',
    'daily',
    'weekly',
    'bi_weekly',
    'monthly',
    'quarterly',
    'yearly',
    'custom'
);

-- ------------------------------------------------------------------
-- 4. TABLE DEFINITIONS
-- ------------------------------------------------------------------

-- 4.1 Profiles (public user metadata mirrored from auth.users)
CREATE TABLE profiles (
    id                uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    full_name         text        NOT NULL,
    email             text        NOT NULL UNIQUE,
    username          text        UNIQUE,
    avatar_url        text,
    phone             text,
    default_currency  text        NOT NULL DEFAULT 'NPR',
    timezone          text        NOT NULL DEFAULT 'UTC',
    bio               text,
    preferences       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    last_active_at    timestamptz,
    created_at        timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at        timestamptz NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE profiles IS 'Public profile data synced with auth.users';

-- 4.2 Friend graph (pending + accepted requests live in the same table)
CREATE TABLE friends (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    friend_id       uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    status          friend_status NOT NULL DEFAULT 'pending',
    initiated_by    uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    last_action_by  uuid REFERENCES profiles (id) ON DELETE SET NULL,
    last_action_at  timestamptz NOT NULL DEFAULT timezone('utc', now()),
    created_at      timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at      timestamptz NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT chk_no_self_friend CHECK (user_id <> friend_id)
);

CREATE UNIQUE INDEX idx_friends_pair
    ON friends (LEAST(user_id, friend_id), GREATEST(user_id, friend_id));

-- 4.3 Groups (shared budgets / expense pools)
CREATE TABLE groups (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name             text NOT NULL,
    description      text,
    cover_image_url  text,
    currency         text NOT NULL DEFAULT 'NPR',
    invite_code      text UNIQUE,
    is_archived      boolean NOT NULL DEFAULT false,
    settlement_cycle text NOT NULL DEFAULT 'as_needed'
        CHECK (settlement_cycle IN ('as_needed', 'weekly', 'monthly', 'custom')),
    created_by       uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    created_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at       timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- 4.4 Group members
CREATE TABLE group_members (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id      uuid NOT NULL REFERENCES groups (id) ON DELETE CASCADE,
    user_id       uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    role          group_member_role NOT NULL DEFAULT 'member',
    display_name  text,
    invite_status text NOT NULL DEFAULT 'accepted'
        CHECK (invite_status IN ('pending', 'accepted', 'declined')),
    added_by      uuid REFERENCES profiles (id) ON DELETE SET NULL,
    created_at    timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at    timestamptz NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT group_members_unique UNIQUE (group_id, user_id)
);

-- 4.5 Expenses
CREATE TABLE expenses (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    group_id             uuid REFERENCES groups (id) ON DELETE SET NULL,
    title                text NOT NULL,
    description          text,
    category             text NOT NULL DEFAULT 'General',
    subcategory          text,
    amount               numeric(14, 2) NOT NULL,
    currency             text NOT NULL DEFAULT 'NPR',
    date                 timestamptz NOT NULL DEFAULT timezone('utc', now()),
    is_recurring         boolean NOT NULL DEFAULT false,
    recurring_frequency  recurring_frequency NOT NULL DEFAULT 'none',
    is_monthly           boolean NOT NULL DEFAULT false,
    status               text NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'settled', 'void')),
    notes                text,
    receipt_url          text,
    metadata             jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at           timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at           timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- 4.6 Expense participants
CREATE TABLE expense_participants (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id   uuid NOT NULL REFERENCES expenses (id) ON DELETE CASCADE,
    user_id      uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    share_amount numeric(14, 2) NOT NULL DEFAULT 0,
    paid_amount  numeric(14, 2) NOT NULL DEFAULT 0,
    is_settled   boolean NOT NULL DEFAULT false,
    created_at   timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at   timestamptz NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT expense_participants_unique UNIQUE (expense_id, user_id)
);

-- 4.7 Settlements
CREATE TABLE settlements (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payer_id     uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    receiver_id  uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    group_id     uuid REFERENCES groups (id) ON DELETE SET NULL,
    expense_id   uuid REFERENCES expenses (id) ON DELETE SET NULL,
    amount       numeric(14, 2) NOT NULL,
    currency     text NOT NULL DEFAULT 'NPR',
    status       settlement_status NOT NULL DEFAULT 'pending',
    method       text NOT NULL DEFAULT 'manual',
    due_date     date,
    notes        text,
    metadata     jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at   timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at   timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- 4.8 Budgets (monthly per user)
CREATE TABLE budgets (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    month            int  NOT NULL CHECK (month BETWEEN 1 AND 12),
    year             int  NOT NULL CHECK (year >= 2000),
    amount           numeric(14, 2) NOT NULL DEFAULT 0,
    currency         text NOT NULL DEFAULT 'NPR',
    warning_threshold numeric(5, 2) NOT NULL DEFAULT 0.9,
    notes            text,
    created_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at       timestamptz NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT budgets_unique UNIQUE (user_id, month, year)
);

-- 4.9 Optional per-category limits
CREATE TABLE budget_categories (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id      uuid NOT NULL REFERENCES budgets (id) ON DELETE CASCADE,
    category       text NOT NULL,
    planned_amount numeric(14, 2) NOT NULL DEFAULT 0,
    spent_amount   numeric(14, 2) NOT NULL DEFAULT 0,
    created_at     timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at     timestamptz NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT budget_categories_unique UNIQUE (budget_id, category)
);

-- 4.10 Notifications
CREATE TABLE notifications (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       uuid NOT NULL REFERENCES profiles (id) ON DELETE CASCADE,
    sender_id     uuid REFERENCES profiles (id) ON DELETE SET NULL,
    type          notification_kind NOT NULL DEFAULT 'system',
    content       jsonb NOT NULL DEFAULT '{}'::jsonb,
    related_table text,
    related_id    uuid,
    is_read       boolean NOT NULL DEFAULT false,
    channel       text NOT NULL DEFAULT 'in_app'
        CHECK (channel IN ('in_app', 'email', 'push')),
    created_at    timestamptz NOT NULL DEFAULT timezone('utc', now()),
    updated_at    timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- ------------------------------------------------------------------
-- 5. MATERIALIZED VIEWS / VIEWS
-- ------------------------------------------------------------------
-- Transactions view exposes expenses as generic ledger rows used by the
-- budget widgets. Extend this view later if incomes/transfers are added.
CREATE VIEW transactions AS
SELECT
    e.id,
    e.user_id,
    'expense'::text AS type,
    e.amount,
    e.currency,
    e.category,
    e.subcategory,
    e.description,
    e.date,
    e.created_at,
    e.updated_at,
    e.group_id,
    e.metadata
FROM expenses e;

-- ------------------------------------------------------------------
-- 6. HELPER FUNCTIONS & TRIGGERS
-- ------------------------------------------------------------------

-- 6.1 Generic updated_at trigger
CREATE OR REPLACE FUNCTION fn_set_updated_timestamp()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$;

-- 6.2 Budget guard: warns when monthly spending exceeds allocation
CREATE OR REPLACE FUNCTION fn_budget_guard()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    budget_rec   budgets;
    month_start  date;
    month_end    date;
    total_spent  numeric(14, 2);
BEGIN
    SELECT * INTO budget_rec
    FROM budgets
    WHERE user_id = NEW.user_id
      AND month = EXTRACT(MONTH FROM NEW.date)::int
      AND year  = EXTRACT(YEAR  FROM NEW.date)::int;

    IF budget_rec IS NULL THEN
        RETURN NEW;
    END IF;

    month_start := date_trunc('month', NEW.date)::date;
    month_end   := (date_trunc('month', NEW.date) + INTERVAL '1 month')::date;

    SELECT COALESCE(SUM(amount), 0)
      INTO total_spent
      FROM expenses
     WHERE user_id = NEW.user_id
       AND date >= month_start
       AND date <  month_end;

    IF total_spent > budget_rec.amount THEN
        INSERT INTO notifications (user_id, sender_id, type, content, related_table, related_id)
        VALUES (
            NEW.user_id,
            NEW.user_id,
            'budget_limit',
            jsonb_build_object(
                'message', format('Budget exceeded for %s/%s', budget_rec.month, budget_rec.year),
                'total_spent', total_spent,
                'limit', budget_rec.amount
            ),
            'budgets',
            budget_rec.id
        );
    END IF;

    RETURN NEW;
END;
$$;

-- 6.3 Expense status refresher triggered after participant payments update
CREATE OR REPLACE FUNCTION fn_refresh_expense_status()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
    unpaid integer;
BEGIN
    SELECT COUNT(*) INTO unpaid
      FROM expense_participants ep
     WHERE ep.expense_id = NEW.expense_id
       AND (ep.share_amount - ep.paid_amount) > 0.009;

    IF unpaid = 0 THEN
        UPDATE expenses SET status = 'settled'
        WHERE id = NEW.expense_id;
    END IF;

    RETURN NEW;
END;
$$;

-- 6.4 Helper RPC used by the Flutter client immediately after group creation
CREATE OR REPLACE FUNCTION add_group_creator_as_admin(p_group_id uuid, p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO group_members (group_id, user_id, role, display_name, invite_status, added_by)
    VALUES (
        p_group_id,
        p_user_id,
        'owner',
        (SELECT full_name FROM profiles WHERE id = p_user_id),
        'accepted',
        p_user_id
    )
    ON CONFLICT (group_id, user_id) DO NOTHING;
END;
$$;

GRANT EXECUTE ON FUNCTION add_group_creator_as_admin(uuid, uuid) TO authenticated;

-- 6.5 Group membership helper functions used by RLS policies
CREATE OR REPLACE FUNCTION fn_is_group_member(p_group_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    exists_row boolean;
BEGIN
    SELECT TRUE INTO exists_row
    FROM group_members
    WHERE group_id = p_group_id
      AND user_id = p_user_id
    LIMIT 1;

    RETURN COALESCE(exists_row, FALSE);
END;
$$;

GRANT EXECUTE ON FUNCTION fn_is_group_member(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION fn_is_group_admin(p_group_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    exists_row boolean;
BEGIN
    SELECT TRUE INTO exists_row
    FROM group_members
    WHERE group_id = p_group_id
      AND user_id = p_user_id
      AND role IN ('owner', 'admin')
    LIMIT 1;

    RETURN COALESCE(exists_row, FALSE);
END;
$$;

GRANT EXECUTE ON FUNCTION fn_is_group_admin(uuid, uuid) TO authenticated;

-- 6.6 Auth hook to auto-provision profile rows from auth.users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO profiles (id, full_name, email, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        NEW.email,
        timezone('utc', now()),
        timezone('utc', now())
    )
    ON CONFLICT (id) DO UPDATE
        SET full_name = EXCLUDED.full_name,
            email = EXCLUDED.email,
            updated_at = timezone('utc', now());

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- 6.7 Attach triggers
CREATE TRIGGER trg_profiles_updated
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_friends_updated
    BEFORE UPDATE ON friends
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_groups_updated
    BEFORE UPDATE ON groups
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_group_members_updated
    BEFORE UPDATE ON group_members
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_expenses_updated
    BEFORE UPDATE ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_expense_participants_updated
    BEFORE UPDATE ON expense_participants
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_settlements_updated
    BEFORE UPDATE ON settlements
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_budgets_updated
    BEFORE UPDATE ON budgets
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_budget_categories_updated
    BEFORE UPDATE ON budget_categories
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_notifications_updated
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_timestamp();

CREATE TRIGGER trg_expense_budget_guard
    AFTER INSERT ON expenses
    FOR EACH ROW
    EXECUTE FUNCTION fn_budget_guard();

CREATE TRIGGER trg_expense_participant_status
    AFTER UPDATE OR INSERT ON expense_participants
    FOR EACH ROW
    EXECUTE FUNCTION fn_refresh_expense_status();

-- ------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY POLICIES
-- ------------------------------------------------------------------

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 7.1 Profiles policies
CREATE POLICY profiles_select_authenticated
    ON profiles FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY profiles_insert_self
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY profiles_update_self
    ON profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 7.2 Friends policies
CREATE POLICY friends_select_involved
    ON friends FOR SELECT
    USING (auth.uid() IN (user_id, friend_id));

CREATE POLICY friends_insert_requester
    ON friends FOR INSERT
    WITH CHECK (auth.uid() = initiated_by AND auth.uid() = user_id);

CREATE POLICY friends_update_participants
    ON friends FOR UPDATE
    USING (auth.uid() IN (user_id, friend_id))
    WITH CHECK (auth.uid() IN (user_id, friend_id));

CREATE POLICY friends_delete_participants
    ON friends FOR DELETE
    USING (auth.uid() IN (user_id, friend_id));

-- 7.3 Groups policies
CREATE POLICY groups_select_members
    ON groups FOR SELECT
    USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = groups.id
              AND gm.user_id = auth.uid()
        )
    );

CREATE POLICY groups_insert_owner
    ON groups FOR INSERT
    WITH CHECK (auth.uid() = created_by);

CREATE POLICY groups_update_admin
    ON groups FOR UPDATE
    USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = groups.id
              AND gm.user_id = auth.uid()
              AND gm.role IN ('owner', 'admin')
        )
    )
    WITH CHECK (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = groups.id
              AND gm.user_id = auth.uid()
              AND gm.role IN ('owner', 'admin')
        )
    );

CREATE POLICY groups_delete_owner
    ON groups FOR DELETE
    USING (auth.uid() = created_by);

-- 7.4 Group members policies
CREATE POLICY group_members_select_members
    ON group_members FOR SELECT
    USING (fn_is_group_member(group_members.group_id, auth.uid()));

CREATE POLICY group_members_insert_admins
    ON group_members FOR INSERT
    WITH CHECK (fn_is_group_admin(group_members.group_id, auth.uid()));

CREATE POLICY group_members_update_admins
    ON group_members FOR UPDATE
    USING (fn_is_group_admin(group_members.group_id, auth.uid()))
    WITH CHECK (fn_is_group_admin(group_members.group_id, auth.uid()));

CREATE POLICY group_members_delete_admins
    ON group_members FOR DELETE
    USING (fn_is_group_admin(group_members.group_id, auth.uid()));

-- 7.5 Expenses policies
CREATE POLICY expenses_select_scope
    ON expenses FOR SELECT
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = expenses.group_id
              AND gm.user_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM expense_participants ep
            WHERE ep.expense_id = expenses.id
              AND ep.user_id = auth.uid()
        )
    );

CREATE POLICY expenses_insert_owner
    ON expenses FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY expenses_update_owner
    ON expenses FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY expenses_delete_owner
    ON expenses FOR DELETE
    USING (auth.uid() = user_id);

-- 7.6 Expense participants policies
CREATE POLICY expense_participants_select_members
    ON expense_participants FOR SELECT
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM expenses e
            WHERE e.id = expense_participants.expense_id
              AND e.user_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM group_members gm
            WHERE gm.group_id = (
                SELECT e.group_id FROM expenses e WHERE e.id = expense_participants.expense_id
            )
              AND gm.user_id = auth.uid()
        )
    );

CREATE POLICY expense_participants_modify_owner
    ON expense_participants FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM expenses e
            WHERE e.id = expense_participants.expense_id
              AND e.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM expenses e
            WHERE e.id = expense_participants.expense_id
              AND e.user_id = auth.uid()
        )
    );

-- 7.7 Settlements policies
CREATE POLICY settlements_select_involved
    ON settlements FOR SELECT
    USING (auth.uid() IN (payer_id, receiver_id));

CREATE POLICY settlements_insert_payer
    ON settlements FOR INSERT
    WITH CHECK (auth.uid() = payer_id);

CREATE POLICY settlements_update_involved
    ON settlements FOR UPDATE
    USING (auth.uid() IN (payer_id, receiver_id))
    WITH CHECK (auth.uid() IN (payer_id, receiver_id));

CREATE POLICY settlements_delete_involved
    ON settlements FOR DELETE
    USING (auth.uid() IN (payer_id, receiver_id));

-- 7.8 Budgets policies
CREATE POLICY budgets_owner_all
    ON budgets FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY budget_categories_owner_all
    ON budget_categories FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM budgets b
            WHERE b.id = budget_categories.budget_id
              AND b.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM budgets b
            WHERE b.id = budget_categories.budget_id
              AND b.user_id = auth.uid()
        )
    );

-- 7.9 Notifications policies
CREATE POLICY notifications_select_owner
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY notifications_insert_sender
    ON notifications FOR INSERT
    WITH CHECK (sender_id IS NOT NULL AND auth.uid() = sender_id);

CREATE POLICY notifications_update_owner
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY notifications_delete_owner
    ON notifications FOR DELETE
    USING (auth.uid() = user_id);

-- ------------------------------------------------------------------
-- 8. INDEXES & PERFORMANCE TUNING
-- ------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles (lower(email));
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles (lower(username));
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends (user_id);
CREATE INDEX IF NOT EXISTS idx_friends_friend ON friends (friend_id);
CREATE INDEX IF NOT EXISTS idx_groups_creator ON groups (created_by);
CREATE INDEX IF NOT EXISTS idx_group_members_group ON group_members (group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members (user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_user ON expenses (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_group ON expenses (group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_status ON expenses (status);
CREATE INDEX IF NOT EXISTS idx_expense_participants_user ON expense_participants (user_id);
CREATE INDEX IF NOT EXISTS idx_settlements_payer ON settlements (payer_id);
CREATE INDEX IF NOT EXISTS idx_settlements_receiver ON settlements (receiver_id);
CREATE INDEX IF NOT EXISTS idx_budgets_owner_month ON budgets (user_id, year DESC, month DESC);
CREATE INDEX IF NOT EXISTS idx_budget_categories_budget ON budget_categories (budget_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications (user_id, is_read, created_at DESC);

-- ------------------------------------------------------------------
-- 9. FINAL NOTES
-- ------------------------------------------------------------------
-- * Run this script in the Supabase SQL editor or via psql.
-- * After executing, refresh the Supabase dashboard so PostgREST picks up
--   the new RLS policies and RPC function.
-- * Storage buckets / policies are managed separately and are not included
--   in this file.

