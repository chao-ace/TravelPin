// TravelPin AI Proxy — Supabase Edge Function
// Forwards AI requests to ZhipuAI GLM-5.1 with usage tracking and subscription gating.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const ZHIPUAI_URL = "https://open.bigmodel.cn/api/paas/v4/chat/completions"
const FREE_TIER_LIMIT = 20

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
}

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  try {
    // 1. Authenticate user
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return json({ error: "Missing authorization" }, 401)
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    )

    const token = authHeader.replace("Bearer ", "")
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return json({ error: "Invalid token" }, 401)
    }

    const userId = user.id

    // 2. Check subscription status
    const { data: sub } = await supabase
      .from("subscriptions")
      .select("status, expires_at")
      .eq("user_id", userId)
      .single()

    const isActive = sub?.status === "active" && (!sub.expires_at || new Date(sub.expires_at) > new Date())

    // 3. Check usage if not subscribed
    if (!isActive) {
      const { data: usage } = await supabase
        .from("ai_usage")
        .select("count")
        .eq("user_id", userId)
        .single()

      const count = usage?.count ?? 0
      if (count >= FREE_TIER_LIMIT) {
        return json({ error: "Usage limit exceeded", count, limit: FREE_TIER_LIMIT }, 403)
      }
    }

    // 4. Forward to ZhipuAI
    const body = await req.json()
    const zhipuResponse = await fetch(ZHIPUAI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${Deno.env.get("ZHIPUAI_API_KEY")}`,
      },
      body: JSON.stringify({
        model: "glm-5.1",
        messages: body.messages ?? [{ role: "user", content: body.prompt }],
        temperature: body.temperature ?? 0.7,
      }),
    })

    if (!zhipuResponse.ok) {
      const errText = await zhipuResponse.text()
      console.error(`ZhipuAI error: ${zhipuResponse.status} ${errText}`)
      return json({ error: "AI service error", detail: errText }, 502)
    }

    const aiData = await zhipuResponse.json()

    // 5. Increment usage (fire and forget for non-subscribers)
    if (!isActive) {
      await supabase.rpc("increment_ai_usage", { target_user: userId })
    }

    // 6. Return response
    return new Response(JSON.stringify(aiData), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })

  } catch (err) {
    console.error("Proxy error:", err)
    return json({ error: "Internal server error" }, 500)
  }
})

function json(body: object, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}
