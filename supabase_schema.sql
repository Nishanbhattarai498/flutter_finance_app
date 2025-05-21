-- Supabase SQL Schema for Flutter Finance App

-- Drop existing objects if they exist to ensure idempotent execution
DO $$ 
BEGIN
    -- Drop triggers
    DROP TRIGGER IF EXISTS update_expense_settlement ON expense_participants;
    DROP TRIGGER IF EXISTS create_settlement_notification ON settlements;
    DROP TRIGGER IF EXISTS check_budget_limits ON budget_expenses;

    -- Drop functions
    DROP FUNCTION IF EXISTS check_expense_settlement();
    DROP FUNCTION IF EXISTS notify_settlement();
    DROP FUNCTION IF EXISTS check_budget_limit();

    -- Drop tables (in correct order to handle dependencies)
    DROP TABLE IF EXISTS notifications;
    DROP TABLE IF EXISTS budget_expenses;
    DROP TABLE IF EXISTS budgets;
    DROP TABLE IF EXISTS settlements;
    DROP TABLE IF EXISTS expense_participants;
    DROP TABLE IF EXISTS expenses;
    DROP TABLE IF EXISTS friend_requests;
    DROP TABLE IF EXISTS friends;
    DROP TABLE IF EXISTS group_members;
    DROP TABLE IF EXISTS groups;
    DROP TABLE IF EXISTS users;
END $$;

-- Table: users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table: budgets
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    period TEXT NOT NULL CHECK (period IN ('daily', 'weekly', 'monthly', 'yearly')),
    start_date TIMESTAMP NOT NULL DEFAULT NOW(),
    category TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table: budget_expenses
CREATE TABLE budget_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id UUID REFERENCES budgets(id) ON DELETE CASCADE,
    expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(budget_id, expense_id)
);

-- Function: Check budget limit
CREATE OR REPLACE FUNCTION check_budget_limit() RETURNS TRIGGER AS $$
DECLARE
    v_budget_total DECIMAL(12,2);
    v_budget_limit DECIMAL(12,2);
    v_period_start TIMESTAMP;
BEGIN
    -- Get the budget details
    SELECT amount, period, start_date INTO v_budget_limit, v_period, v_period_start
    FROM budgets WHERE id = NEW.budget_id;

    -- Calculate period start based on budget period
    v_period_start = CASE 
        WHEN v_period = 'daily' THEN DATE_TRUNC('day', NOW())
        WHEN v_period = 'weekly' THEN DATE_TRUNC('week', NOW())
        WHEN v_period = 'monthly' THEN DATE_TRUNC('month', NOW())
        WHEN v_period = 'yearly' THEN DATE_TRUNC('year', NOW())
    END;

    -- Calculate current total
    SELECT COALESCE(SUM(amount), 0) INTO v_budget_total
    FROM budget_expenses
    WHERE budget_id = NEW.budget_id
    AND created_at >= v_period_start;

    -- Check if new expense would exceed budget
    IF (v_budget_total + NEW.amount) > v_budget_limit THEN
        INSERT INTO notifications (user_id, type, content, related_id)
        SELECT user_id, 'budget_limit', 
               format('Budget limit exceeded for %s', name),
               id
        FROM budgets
        WHERE id = NEW.budget_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Monitor budget limits
CREATE TRIGGER check_budget_limits
    BEFORE INSERT ON budget_expenses
    FOR EACH ROW
    EXECUTE FUNCTION check_budget_limit();

-- Table: expenses
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    date TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    notes TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'settled'))
);

-- Table: expense_participants
CREATE TABLE expense_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_id UUID REFERENCES expenses(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    share_amount DECIMAL(12,2) NOT NULL,
    paid_amount DECIMAL(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(expense_id, user_id)
);

-- Table: settlements
CREATE TABLE settlements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payer_id UUID REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(12,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    notes TEXT
);

-- Function: Update expense status when all participants have settled
CREATE OR REPLACE FUNCTION check_expense_settlement() RETURNS TRIGGER AS $$
BEGIN
    -- Check if all participants have paid their share
    IF NOT EXISTS (
        SELECT 1 FROM expense_participants
        WHERE expense_id = NEW.expense_id
        AND share_amount > paid_amount
    ) THEN
        UPDATE expenses SET status = 'settled'
        WHERE id = NEW.expense_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update expense status
CREATE TRIGGER update_expense_settlement
    AFTER UPDATE ON expense_participants
    FOR EACH ROW
    EXECUTE FUNCTION check_expense_settlement();

-- Function: Create notification on settlement creation
CREATE OR REPLACE FUNCTION notify_settlement() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, type, content, related_id)
    VALUES (
        NEW.recipient_id,
        'settlement',
        format('You have a new settlement request for %s %s', NEW.amount, NEW.currency),
        NEW.id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-create notification for new settlements
CREATE TRIGGER create_settlement_notification
    AFTER INSERT ON settlements
    FOR EACH ROW
    EXECUTE FUNCTION notify_settlement();

-- Table: groups
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table: group_members
CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Table: notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (
        type IN (
            'friend_request',
            'expense_created',
            'settlement',
            'budget_limit',
            'group_invitation'
        )
    ),
    content TEXT NOT NULL,
    related_id UUID,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Table: friends
CREATE TABLE friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

-- Table: friend_requests
CREATE TABLE friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(sender_id, receiver_id)
);

-- RLS Policies
ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Friends policies
CREATE POLICY "Users can view their own friends"
    ON friends FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "Users can delete their own friends"
    ON friends FOR DELETE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Friend requests policies
CREATE POLICY "Users can view requests they're involved in"
    ON friend_requests FOR SELECT
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send friend requests"
    ON friend_requests FOR INSERT
    WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update requests they received"
    ON friend_requests FOR UPDATE
    USING (auth.uid() = receiver_id);

-- Expenses policies
CREATE POLICY "Users can view expenses they're involved in"
    ON expenses FOR SELECT
    USING (
        auth.uid() = creator_id OR
        EXISTS (
            SELECT 1 FROM expense_participants
            WHERE expense_id = expenses.id AND user_id = auth.uid()
        ) OR
        EXISTS (
            SELECT 1 FROM group_members
            WHERE group_id = expenses.group_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create expenses"
    ON expenses FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their expenses"
    ON expenses FOR UPDATE
    USING (auth.uid() = creator_id);

CREATE POLICY "Creators can delete their expenses"
    ON expenses FOR DELETE
    USING (auth.uid() = creator_id);

-- Expense participants policies
CREATE POLICY "Users can view expense participants they're involved with"
    ON expense_participants FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM expenses e
            WHERE e.id = expense_id AND (
                e.creator_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM group_members
                    WHERE group_id = e.group_id AND user_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "Expense creators can manage participants"
    ON expense_participants FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM expenses
            WHERE id = expense_id AND creator_id = auth.uid()
        )
    );

-- Settlements policies
CREATE POLICY "Users can view settlements they're involved in"
    ON settlements FOR SELECT
    USING (auth.uid() = payer_id OR auth.uid() = recipient_id);

CREATE POLICY "Users can create settlements"
    ON settlements FOR INSERT
    WITH CHECK (auth.uid() = payer_id);

CREATE POLICY "Involved users can update settlements"
    ON settlements FOR UPDATE
    USING (auth.uid() IN (payer_id, recipient_id));

-- Budgets policies
CREATE POLICY "Users can manage their own budgets"
    ON budgets FOR ALL
    USING (auth.uid() = user_id);

-- Budget expenses policies
CREATE POLICY "Users can manage their budget expenses"
    ON budget_expenses FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM budgets
            WHERE id = budget_id AND user_id = auth.uid()
        )
    );

-- Notifications policies
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Indexes for better performance
CREATE INDEX idx_friends_user_id ON friends(user_id);
CREATE INDEX idx_friends_friend_id ON friends(friend_id);
CREATE INDEX idx_friend_requests_sender ON friend_requests(sender_id);
CREATE INDEX idx_friend_requests_receiver ON friend_requests(receiver_id);
CREATE INDEX idx_expenses_creator ON expenses(creator_id);
CREATE INDEX idx_expenses_group ON expenses(group_id);
CREATE INDEX idx_expense_participants_expense ON expense_participants(expense_id);
CREATE INDEX idx_expense_participants_user ON expense_participants(user_id);
CREATE INDEX idx_settlements_payer ON settlements(payer_id);
CREATE INDEX idx_settlements_recipient ON settlements(recipient_id);
CREATE INDEX idx_settlements_group ON settlements(group_id);
CREATE INDEX idx_settlements_status ON settlements(status);
CREATE INDEX idx_budgets_user ON budgets(user_id);
CREATE INDEX idx_budgets_period ON budgets(period);
CREATE INDEX idx_budget_expenses_budget ON budget_expenses(budget_id);
CREATE INDEX idx_budget_expenses_expense ON budget_expenses(expense_id);
CREATE INDEX idx_budget_expenses_created ON budget_expenses(created_at);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_created ON notifications(created_at);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);

-- Add extension for handling currency operations safely
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Basic database functions
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to all relevant tables
DO $$
DECLARE
    t text;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE column_name = 'updated_at'
    LOOP
        EXECUTE format('
            CREATE TRIGGER set_timestamp
            BEFORE UPDATE ON %I
            FOR EACH ROW
            EXECUTE FUNCTION trigger_set_timestamp();
        ', t);
    END LOOP;
END
$$;
