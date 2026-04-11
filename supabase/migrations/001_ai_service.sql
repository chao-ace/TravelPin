-- TravelPin AI Service Database Setup
-- Run in Supabase SQL Editor

-- Table: AI usage tracking
CREATE TABLE IF NOT EXISTS ai_usage (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  count INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: Subscription status
CREATE TABLE IF NOT EXISTS subscriptions (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'free',
  product_id TEXT,
  expires_at TIMESTAMPTZ,
  original_transaction_id TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RPC: Increment usage atomically
CREATE OR REPLACE FUNCTION increment_ai_usage(target_user UUID)
RETURNS void AS $$
BEGIN
  INSERT INTO ai_usage (user_id, count)
  VALUES (target_user, 1)
  ON CONFLICT (user_id)
  DO UPDATE SET count = ai_usage.count + 1, updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own usage" ON ai_usage FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users read own subscription" ON subscriptions FOR SELECT USING (auth.uid() = user_id);
