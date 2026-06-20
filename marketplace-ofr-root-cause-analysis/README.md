#  Advanced Marketplace Diagnostic: Root-Cause Analysis of an 8% Drop in Order Fulfillment Rate (OFR)

[![Data Analytics](https://img.shields.io/badge/Analytics-Product%20%7C%20Business-blue)](#)
[![SQL](https://img.shields.io/badge/Language-SQL-orange)](#)
[![Python](https://img.shields.io/badge/Language-Python-green)](#)
[![Framework](https://img.shields.io/badge/Methodology-4--Phase%20Diagnostic-success)](#)

This repository serves as a rigorous, end-to-end framework for diagnosing marketplace imbalances, algorithmic failures, and human incentive breakdowns in a three-sided on-demand delivery ecosystem (Consumers, Merchants, and Couriers). 

Use this documentation as an engineering and analytics reference model for handling open-ended diagnostic case studies, writing structured pipeline logic, and setting up automated statistical guardrails.

---

##  System & Metric Architecture

To accurately diagnose a marketplace anomaly, we must first map out the foundational telemetry and behavioral formulas governing the platform.

### 1. Mathematical Formulas & Core KPIs

* **Order Fulfillment Rate (OFR):** The primary north-star operational efficiency metric.
    
    $$\text{OFR} = \frac{\text{Completed Deliveries}}{\text{Total Orders Placed}}$$

* **Driver Acceptance Rate (DAR):** Measures supply-side willingness and matching efficiency.
    
    $$\text{DAR} = \frac{\text{Accepted Delivery Offers}}{\text{Total Matched Offers Dispatched}}$$

* **Gross Merchandise Value (GMV) Drop-off (Financial Leakage):** Quantifies the exact top-line run-rate destruction during an outage or degradation period ($t_1$ to $t_2$).
    
    $$\Delta \text{GMV} = \sum_{t=t_1}^{t_2} \left( \text{Orders Placed}_t \times ( \text{Baseline OFR} - \text{Observed OFR}_t ) \times \text{Average Order Value (AOV)} \right)$$

### 2. The Three-Sided Marketplace Funnel
A health degradation at any node cascades down the stack:

$$\text{Order Placed} \longrightarrow \text{Merchant Acceptance} \longrightarrow \text{Driver Dispatch/Match} \longrightarrow \text{Driver Acceptance} \longrightarrow \text{Order Fulfilled}$$

---

##  The 4-Phase Diagnostic Blueprint

```text
[Phase 1: Clarify & Scope] ──> [Phase 2: Hot/Cold Segmentation] ──> [Phase 3: Root Cause Isolation] ──> [Phase 4: Resolution & Circuit Breakers]
```


# 🟥 Phase 1: Clarify, Scope, & Isolate

Before analyzing data slices, we must establish the temporal footprint and eliminate baseline infrastructure failures.

### Temporal Footprint

Analysis of historical logs showed that the 8% drop occurred as a sudden **step-function drop** starting precisely at **08:00 AM UTC on Monday, June 1, 2026**. It was not a gradual, seasonal trend.

### Infrastructure Verification

Checked server latency logs, HTTP 5xx error rates, payment gateway API success status codes, and user app-crash analytics (Firebase/Sentry). All core systems were completely nominal, eliminating a hard technical outage.

### Deployment Mapping

Cross-referenced system deployment logs and verified that the Logistics Engineering team activated a feature flag routing a new pricing optimization algorithm (`TREATMENT_V2`) at **07:45 AM UTC** on that same Monday morning.

---

# 🟨 Phase 2: "Hot or Cold" Data Segmentation (SQL Engine)

To isolate the exact blast radius of the algorithmic failure, we execute multi-dimensional data slicing across the experiment metadata, geographical hierarchies, and marketplace matching funnels.

Here is the exact production-grade PostgreSQL diagnostic query utilized to pinpoint the anomaly:

```sql
WITH market_base AS (
    SELECT
        o.order_id,
        o.geo_region,
        o.experiment_group,
        o.order_value_usd,
        f.merchant_accepted,
        f.driver_dispatched,
        f.driver_accepted,
        f.is_completed,
        -- Calculate structural trip characteristics
        t.actual_driving_distance_miles,
        t.straight_line_distance_miles,
        (t.actual_driving_distance_miles - t.straight_line_distance_miles) AS routing_friction_delta
    FROM marketplace_orders o
    JOIN order_funnel_states f
        ON o.order_id = f.order_id
    JOIN trip_geometries t
        ON o.order_id = t.order_id
    WHERE o.order_timestamp >= '2026-06-01 00:00:00'
      AND o.order_timestamp <= '2026-06-15 23:59:59'
)

SELECT
    geo_region,
    experiment_group,
    COUNT(order_id) AS total_orders_placed,
    ROUND(AVG(order_value_usd), 2) AS average_order_value,

    -- Step-by-Step Funnel Conversion Tracking
    ROUND(
        SUM(
            CASE
                WHEN merchant_accepted = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(order_id),
        2
    ) AS merchant_accept_rate,

    ROUND(
        SUM(
            CASE
                WHEN driver_accepted = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN driver_dispatched = 1
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS driver_accept_rate,

    ROUND(
        SUM(
            CASE
                WHEN is_completed = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(order_id),
        2
    ) AS order_fulfillment_rate,

    -- Structural Feature Analysis
    ROUND(
        AVG(routing_friction_delta),
        2
    ) AS avg_urban_routing_friction

FROM market_base

GROUP BY 1, 2

HAVING COUNT(order_id) > 100

ORDER BY order_fulfillment_rate ASC;
```

#  Analytical Insights Extracted From Query Output

By analyzing the output of our data diagnostic pipeline, we isolated three distinct data signals that pinpointed the operational failure.

## The Experiment Isolation

The `CONTROL` group maintained a baseline Order Fulfillment Rate (OFR) of **93.2%**.

The `TREATMENT_V2` variant suffered a catastrophic drop to **68.4%**.

The algorithm update was definitively identified as the source of the system degradation.

---

## Geographical Clustering

Suburban and highly grid-structured cities (e.g., Phoenix, Indianapolis) showed standard statistical variations under the new release.

The metric drop was entirely concentrated in hyper-dense urban nodes with complex physical geography, spearheaded by **New York City (NYC)**.

---

## Funnel Breakdown

Merchant acceptance remained perfectly flat at **97.8%**.

However, driver acceptance rates (DAR) for delivery offers requiring cross-borough travel (e.g., Manhattan to Brooklyn or Queens) collapsed to an unprecedented **11.4%** (representing an 89% rejection rate).

---

# 🟩 Phase 3: Root Cause Deconstruction (Economic Incentives)

The data signals a deep mismatch between software design assumptions and physical-world economic constraints:

```text
[Euclidean Distance Calculation]
            │
            ▼
Underpriced Payouts
            │
            ▼
Rational Driver Rejections
            │
            ▼
Order Expiration/Cancellation
```

## The Algorithmic Flaw

The newly deployed pricing model (`TREATMENT_V2`) switched base courier payouts from a structural routing matrix engine to a pure Euclidean distance algorithm ("as the crow flies") to minimize upstream API calculation latency.

---

## The Geographic Penalty

In a region like New York City, a straight-line distance of 2 miles frequently requires crossing a heavily congested toll bridge, waiting in severe urban traffic tunnels, and navigating major gridlock.

---

## The Human Incentives Breakdown

Couriers operate as rational, independent economic actors maximizing their hourly net-earnings stream:

```text
Net Earnings
=
Gross Base Payout
− (Fuel Costs + Tolls + Opportunity Cost of Time Spent in Gridlock)
```

Under `TREATMENT_V2`, the payout for a cross-borough trip dropped by nearly **45%**, failing to account for a **$7.00 bridge toll** and **45 minutes of idling traffic**.

Drivers acted logically: they hit **Reject**.

The platform's automated matching system repeatedly re-dispatched the same underpriced orders to alternative couriers until:

- The food cooled.
- Delivery windows elapsed.
- The platform timed out.
- Customers canceled out of frustration.

---

# 🟦 Phase 4: Resolution & Resiliency Engineering

Fixing an analytical issue in an enterprise production environment requires moving fast across tactical rollbacks, quantifying the financial impact, and putting up structural data engineering guardrails.

## 1. Tactical Remediation

### Action

Executed an immediate localized override via our feature flag management console (**LaunchDarkly**), forcing a 100% rollback of the NYC market from `TREATMENT_V2` back to the baseline control pricing matrix.

### Result

Within **45 minutes** of the deployment rollback, driver acceptance rates normalized back to historical baselines (~88%), and the localized OFR fully recovered.

---

## 2. Mathematical Anomaly Detection (The "Circuit Breaker")

To guarantee that flawed experiment designs never cascade into macro-level revenue threats again, we implement a streaming real-time statistical anomaly guardrail within our Apache Flink/Spark data pipeline.

The script continuously tracks incoming metric deviations against moving windows using a dynamic rolling Z-score calculation.



```python
import numpy as np
import pandas as pd

def evaluate_marketplace_health(current_metrics_df, historical_baseline_df, threshold=3.0):
    """
    Real-time statistical anomaly detection engine (Circuit Breaker).
    Calculates rolling Z-scores on incoming stream metrics.
    """
    # Merge streaming real-time evaluation windows with 30-day historical baseline metrics
    merged_df = pd.merge(current_metrics_df, historical_baseline_df, on=['geo_region', 'segment_type'])
    
    # Calculate Z-score for Driver Rejection Rates
    # Z = (X - Mean) / StdDev
    merged_df['rejection_z_score'] = (
        (merged_df['observed_rejection_rate'] - merged_df['historical_mean_rejection_rate']) / 
        merged_df['historical_std_dev_rejection_rate']
    )
    
    # Flag severe anomalies where metrics deviate beyond critical statistical boundaries
    tripped_anomalies = merged_df[merged_df['rejection_z_score'] >= threshold]
    
    if not tripped_anomalies.empty:
        for index, row in tripped_anomalies.iterrows():
            print(f"🚨 [CIRCUIT BREAKER ALERT] Anomaly detected in region: {row['geo_region']}.")
            print(f"Triggering automated webhook to kill experiment variant. Current Z-Score: {row['rejection_z_score']:.2f}")
            execute_automated_rollback(experiment_id=row['experiment_id'], market=row['geo_region'])
    else:
        print("✅ Marketplace metrics running within standard statistical control boundaries.")

def execute_automated_rollback(experiment_id, market):
    # Simulated automated platform webhook call to Feature Flag API
    print(f"Sending POST request to FeatureFlag API -> Disabling {experiment_id} in {market}. Reverting to baseline.")
    # payload = {"experiment": experiment_id, "region": market, "status": "FORCE_OFF"}
```

#  Key Architectural Takeaways for Product Data Teams

## Metrics are Proxies for Human Behavior

Data streams do not exist in a vacuum. When core platform metrics experience unexpected structural breaks, analyze whether structural engineering updates have unintentionally corrupted real-world economic incentives.

---

## Defensive Engineering is Mandatory

Never deploy algorithm updates to complex physical systems without automated, algorithmic circuit breakers capable of killing code variants when real-time Z-scores deviate beyond normal statistical control boundaries (**> ±3.0σ**).

---

# 💼 Connect With Me

I specialize in transforming ambiguous, open-ended business chaos into structured data frameworks that defend bottom-line revenue and scale product efficiency.

I am actively interviewing for **Data Analytics**, **Product Analytics**, and **Business Intelligence** roles where data partners are expected to speak the simultaneous languages of engineering guardrails and business trade-offs.

- 🔗 **LinkedIn:** [Shivansh Awasthi](https://www.linkedin.com/in/shivanshawasthi87/)
- 📧 **Email:** shivanshawasthi87@gmail.com

