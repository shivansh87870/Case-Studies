# Case Study: Finding and Fixing a $36M Silent Subscription Leak

This case study reviews a hidden payment system glitch that accidentally downgraded hundreds of thousands of paying customers to a free account level, threatening millions in revenue.

Below is the complete blueprint of how the problem was detected, isolated, temporarily patched, and systematically prevented from ever happening again.

---

#  The 4-Step Problem-Solving Framework

When a massive company metric drops, guessing is a liability. This investigation relied on a strict, professional engineering framework to uncover the root cause:

```text
[1. Scope the Problem]
            ↓
[2. Slice the Data]
            ↓
[3. Find the Bug]
            ↓
[4. Fix & Protect]
```

---

#  Step 1: Scope the Problem & Calculate Financial Impact

## The Alarm

During a routine weekly health check, the data team flagged a sudden 5% drop in global Weekly Active Users (WAU).

To the core infrastructure and application teams, everything looked perfect:

- Media streaming servers reported 100% uptime.
- Client-side mobile application crash rates were near 0%.
- Content Delivery Networks (CDNs) were serving music smoothly.

Yet, millions of users were suddenly stopping their daily listening habits.

```text
Normal Global WAU Baseline:

████████████████ (100%)

Post-Deployment Drop:

██████████████░░ (95%)
```

---

## The Financial Math: Why a 5% Drop Costs $36 Million

A 5% drop in global usage might sound small, but when applied to a high-scale subscription business, the long-term compounding losses are massive.

### Economic Breakdown

- **Total Premium Subscribers At Risk:** 250,000 accounts were impacted.
- **Average Revenue Per User (ARPU):** ~$6.00 USD per month in these regional markets.
- **Average Customer Lifetime Value (LTV):** ~$144.00 USD (assuming an average user stays subscribed for 24 months).

### The Damage

```math
250,000 × $144.00 = $36,000,000
```

in potential lifetime revenue leaked if those users permanently walked away due to frustration.

---

#  Step 2: Slice the Data (Structural Segmentation)

An aggregate global chart lies because it dilutes deep, localized disasters.

To find the exact blast radius, we executed a multi-dimensional data slice across user tiers, devices, app versions, and geographies.

---

## The SQL Investigation

The first step was writing a query to see exactly where the drop was occurring over a 14-day window.

```sql
-- Querying session log deltas to isolate the drop across dimensions

SELECT
    -- Country of the user
    country_code,

    -- User type (Free or Premium)
    user_tier,

    -- Device platform (iOS or Android)
    device_platform,

    -- Count unique active users
    COUNT(DISTINCT user_id) AS active_users,

    -- Calculate percentage change compared to 7 days ago
    ROUND(

        (
            -- Current active users
            COUNT(DISTINCT user_id)

            -- Minus active users from 7 days ago
            -
            LAG(COUNT(DISTINCT user_id), 7) OVER (
                -- Calculate separately for each country, tier, and device
                PARTITION BY country_code,
                             user_tier,
                             device_platform

                -- Use event_date for chronological order
                ORDER BY event_date
            )
        )::NUMERIC

        -- Divide by previous week's active users
        /
        NULLIF(
            LAG(COUNT(DISTINCT user_id), 7) OVER (
                PARTITION BY country_code,
                             user_tier,
                             device_platform
                ORDER BY event_date
            ),

            -- Prevent division by zero
            0
        )

        -- Convert to percentage
        * 100,

        -- Round to 2 decimal places
        2

    ) AS weekly_percentage_change

FROM production.user_session_logs

-- Look only at the last 14 days
WHERE event_date >= CURRENT_DATE - INTERVAL '14 days'

GROUP BY
    country_code,
    user_tier,
    device_platform,
    event_date

-- Show latest dates first and biggest drops on top
ORDER BY
    event_date DESC,
    weekly_percentage_change ASC;
```

---

## The Diagnostics Matrix

| Dimension Sliced | Observed Variance | Conclusion |
|-----------------|------------------|------------|
| User Tier | Free Tier: 0.0% \| Premium Tier: -21.0% | The problem is strictly isolated to paying accounts. |
| Device Type | iOS: -4.9% \| Android: -5.1% | Platform-agnostic. This eliminates native client-side app store update bugs. |
| Geography | US/EU: 0.0% \| LATAM (Brazil & Mexico): -40.0% | 🛑 The Smoking Gun. A catastrophic regional collapse. |

The data proved this wasn't a product fatigue issue.

Something specific was ripping Premium access away from users in Brazil and Mexico.

---

#  Step 3: Find the Bug (Forensic Root Cause Analysis)

With the problem isolated to Premium users in Latin America (LATAM), we turned our attention to the subscription state logs and customer support queues.

---

## The System Log Discovery

We queried the `subscription_state_transitions` table, which tracks every time a user moves from Premium to Free.

The log revealed a massive wall of automated downgrades.

```text
[Active Premium Subscriber]
                ↓
(Trigger: Payment Renewal Failure)
                ↓
[Instant Free Tier Move]
```

The accompanying system error log was completely uniform:

```text
Payment_Failed_Gateway_Timeout
```

---

## Cross-Referencing the Release Calendar

We mapped these errors against our internal deployment schedules.

The surge in timeouts started at the exact minute a new billing backend microservice went live.

The update migrated the region to a highly secure payment gateway designed to enforce mandatory, synchronous 3D-Secure (3DS) authentication to combat credit card fraud.

```text
[New Billing Engine]
                ↓
(Demands Instant Verification Check)
                ↓
[Local Cash/Voucher Networks]
                ↓
(Takes time to settle...)
                ↓
(System Times Out & Fails)
                ↓
[Account Unfairly Stripped]
```

---

## The Architectural Disconnect

### The Local Reality

The most popular payment methods in Brazil (**Boleto Bancário**) and Mexico (**OXXO cash vouchers**) are asynchronous system networks.

They are invoice/ticket-based systems.

When a monthly subscription bill is generated, the user receives a digital voucher and pays it hours or days later via a local convenience store, ATM, or banking app.

### The Engineering Mistake

The new payment gateway was built assuming a standard credit card handshake—meaning it expected an instantaneous confirmation.

Because cash vouchers cannot reply instantly, the gateway timed out.

The billing engine misread this timeout as an explicit credit card rejection or cancellation, and instantly stripped away the user's premium privileges.

---

#  Step 4: The Recovery & Fix Playbook

During a major live outage, you cannot afford to wait days for a code patch to be rewritten and deployed.

You must execute a multi-phase emergency plan.

---

## Phase 1: Immediate Traffic Isolation (Minutes)

Instead of rolling back the payment infrastructure update globally (which would disrupt ongoing optimization work in Europe and the US), we used LaunchDarkly feature flags to split the traffic dynamically at the edge.

Within minutes, a targeted rule configuration was deployed:

```json
{
  "flag": "enable-payment-gateway-v2",
  "rules": [
    {
      "targeting": "country_code IN ['BR', 'MX']",
      "serve": "legacy_asynchronous_gateway"
    },
    {
      "targeting": "default",
      "serve": "secure_gateway_v2"
    }
  ]
}
```

This instantly safely routed all LATAM renewal attempts back to the legacy system, stopping the ongoing account downgrades immediately.

---

## Phase 2: Protecting Customer Sentiment & Habit Loops (Hours)

Tens of thousands of active users had already been booted to the free app tier, ruining their custom playlists and introducing disruptive ads.

Customer Support ticket volumes spiked by 600%.

To salvage customer goodwill, we bypassed traditional email marketing channels (which suffer from low open rates) and triggered an automated backend webhook to dispatch transactional notifications via WhatsApp and SMS directly to impacted users.

### The Retention Bridge

The notification provided an encrypted, tokenized, 1-click URL.

Clicking the link bypassed standard login forms, opened the app, and injected 3 weeks of complimentary Premium credit straight into the user's profile.

### The Strategy

While giving away 21 days of free access caused a short-term hit to our royalty payout pools, it completely saved the user's daily listening habit loop, kept them from deleting the app, and gave our core payment engineers a safe three-week window to properly refactor the gateway integration code.

---

#  Future Recommendations (Systemic Defensiveness)

To transition from a team that reactively fights fires to one that builds resilient systems, the platform architecture requires three permanent upgrades.

---

## 1. Introduce a Mandatory Grace-Period State

The primary systemic vulnerability was the billing system executing an immediate account degradation on a single API timeout.

The subscription engine state machine code must be refactored to separate transaction processing from instant user tier changes.

```text
[Premium Active]
        │
        ▼
(Gateway Timeout)
        │
        ▼
[Grace Period State]
        │
        ▼
(7-Day Background Retries)
        │
        ├── Success ─────────► [Premium Active]
        │
        └── Failure after 7 days
                    │
                    ▼
           [Downgrade to Free]
```

If a renewal fails or times out, the account must enter a temporary `Grace_Period` status.

The user retains full feature access while microservice workers try alternative retry intervals behind the scenes.

---

## 2. Build a Data-Driven "Circuit Breaker"

To eliminate human monitoring delays, we can deploy an automated monitoring script that evaluates account transitions hourly.

If regional failures spike past a normal statistical threshold, the system triggers its own emergency switch.

### Automated Tracking Script

```sql

WITH regional_hourly_downgrades AS (

    -- Count billing failures every hour by country
    SELECT

        country_code,

        -- Round timestamps to hourly buckets
        DATE_TRUNC('hour', transition_timestamp)
        AS failure_hour,

        -- Number of downgrades in that hour
        COUNT(*) AS downgrade_count

    FROM production.subscription_state_transitions

    WHERE transition_type = 'PREMIUM_TO_FREE'

      -- Focus only on billing failures
      AND reason = 'BILLING_FAILURE'

      -- Analyze the past 30 days
      AND transition_timestamp >= CURRENT_DATE - INTERVAL '30 days'

    GROUP BY
        country_code,
        DATE_TRUNC('hour', transition_timestamp)

),

stats_baseline AS (

    -- Calculate normal behavior for each country
    SELECT

        country_code,

        -- Average hourly failures
        AVG(downgrade_count)
        AS historical_mean,

        -- Standard deviation of failures
        STDDEV(downgrade_count)
        AS historical_stddev

    FROM regional_hourly_downgrades

    -- Exclude current hour from baseline calculations
    WHERE failure_hour < DATE_TRUNC('hour', CURRENT_TIMESTAMP)

    GROUP BY country_code

),

current_hour_data AS (

    -- Get downgrade count for the current hour
    SELECT

        country_code,

        downgrade_count AS current_count

    FROM regional_hourly_downgrades

    WHERE failure_hour =
          DATE_TRUNC('hour', CURRENT_TIMESTAMP)

)

SELECT

    c.country_code,

    -- Current hour failures
    c.current_count,

    -- Historical average failures
    s.historical_mean,

    -- Historical variation
    s.historical_stddev,

    -- Calculate Z-score
    -- Formula:
    -- (Current Count - Mean) / Standard Deviation
    (
        c.current_count - s.historical_mean
    )

    /

    -- Prevent division by zero
    NULLIF(s.historical_stddev, 0)

    AS current_z_score

FROM current_hour_data c

JOIN stats_baseline s
ON c.country_code = s.country_code

-- If Z-score exceeds 3,
-- consider it an anomaly
WHERE
(
    c.current_count - s.historical_mean
)
/
NULLIF(s.historical_stddev, 0)

> 3.0;

-- If this query returns rows:
-- Trigger PagerDuty alert
-- Freeze deployment routing
-- Prevent further revenue loss
```

---

## 3. Implement Canary Releases for Payment Gates

Never launch infrastructure changes affecting monetary transaction processing to 100% of a country at the same time.

### The Canary Pipeline

- Route just 1% of regional traffic through the new payment gateway during a 48-hour trial window.
- Keep the remaining 99% on the safe legacy engine.
- Expand deployment rollout groups to 10%, 25%, and eventually 100% only after confirming that the canary tier's subscription renewal success ratios match pre-deployment baselines.

---
