-- =========================================================
-- PURPOSE
-- Reconstruct user journeys and calculate
-- conversion metrics for each experiment variant.
--
-- BUSINESS QUESTION
-- Where are users dropping off?
-- =========================================================

WITH experiment_cohorts AS (

    -- Identify experiment assignment
    SELECT
        user_id,
        variant_group,
        assigned_at

    FROM telemetry.experiment_assignments

    WHERE experiment_name =
    'onboarding_v2_friction_test'

),

user_funnel_progress AS (

    -- Aggregate milestone events

    SELECT

        user_id,

        MAX(
            CASE
                WHEN event_name='sign_up'
                THEN 1
                ELSE 0
            END
        ) AS step_1_signup,

        MAX(
            CASE
                WHEN event_name='complete_onboarding'
                THEN 1
                ELSE 0
            END
        ) AS step_2_onboard,

        MAX(
            CASE
                WHEN event_name='create_graphic'
                THEN 1
                ELSE 0
            END
        ) AS step_3_create,

        MAX(
            CASE
                WHEN event_name='click_export'
                THEN 1
                ELSE 0
            END
        ) AS step_4_export,

        MAX(
            CASE
                WHEN event_name='view_pricing'
                THEN 1
                ELSE 0
            END
        ) AS step_5_paywall,

        MAX(
            CASE
                WHEN event_name='purchase_subscribed'
                THEN 1
                ELSE 0
            END
        ) AS step_6_paid

    FROM telemetry.product_user_events

    GROUP BY user_id

)

-- Compute conversion metrics

SELECT

    c.variant_group,

    COUNT(c.user_id) AS total_traffic,

    SUM(f.step_2_onboard) AS completed_onboarding,

    SUM(f.step_3_create) AS created_graphic,

    SUM(f.step_4_export) AS clicked_export,

    SUM(f.step_5_paywall) AS viewed_paywall,

    SUM(f.step_6_paid) AS total_subscriptions,

    ROUND(
        SUM(f.step_6_paid) * 100.0 /
        COUNT(c.user_id),
        2
    ) AS registration_to_paid_pct

FROM experiment_cohorts c

INNER JOIN user_funnel_progress f

ON c.user_id = f.user_id

GROUP BY c.variant_group;
