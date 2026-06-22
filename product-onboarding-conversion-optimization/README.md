# 📊 AI Onboarding Conversion Analysis: Root Cause Analysis of a 12% Subscription Decline

[![Product Analytics](https://img.shields.io/badge/Domain-Product%20Analytics-blue)](#)
[![SQL](https://img.shields.io/badge/Language-SQL-orange)](#)
[![Python](https://img.shields.io/badge/Language-Python-green)](#)
[![A/B Testing](https://img.shields.io/badge/Methodology-Experimentation-success)](#)

This repository presents a structured investigation into how a redesigned AI onboarding experience unexpectedly reduced premium subscriptions despite significantly increasing product engagement.

The analysis demonstrates how optimizing the wrong metric can create hidden revenue leakage and illustrates the importance of experimentation guardrails, user intent, and monetization transparency.

---

# Executive Summary

## Problem

A redesigned AI onboarding flow doubled user engagement but unexpectedly caused premium subscriptions to decline by **12% globally**.

## Impact

- Annual recurring revenue loss: **$420,000**
- Pricing page views dropped by approximately **63%**
- Conversion rate declined from **3.0% to 2.64%**

## Root Cause

The new onboarding removed qualification steps and attracted low-intent users while introducing a surprise paywall that damaged trust.

## Resolution

Strategic friction and recovery workflows restored conversion efficiency.

---

# Problem Statement

The product team launched a faster AI-first onboarding flow designed to help users create graphics immediately.

Although engagement improved substantially, premium subscriptions unexpectedly declined.

Historical telemetry showed the decline appeared immediately after deployment.

---

# Business Impact

| Metric | Control | Variant |
|----------|---------|---------|
| Onboarding Completion | 62% | 88% |
| Graphic Creation | 45% | 82% |
| Paywall Views | 8.5% | 3.1% |
| Paid Conversion | 3.0% | 2.64% |

### Revenue Impact

Estimated annual recurring revenue leakage:

**≈ $420,000**

---

# Investigation Framework

```text
Problem
    ↓
Investigation
    ↓
Root Cause
    ↓
Solution
    ↓
Prevention
```

---

# SQL Analysis

To understand where users disappeared, funnel events were aggregated using conditional flags (`MAX(CASE WHEN...)`).

This approach efficiently reconstructs user journeys while scanning millions of telemetry records.

The complete SQL query is available in:

```text
sql/funnel_analysis.sql
```

---

# Key Findings

## Finding 1: Onboarding Success Increased

The new experience dramatically improved onboarding completion.

```text
62%
↓
88%
```

Graphic creation activity nearly doubled.

```text
45%
↓
82%
```

---

## Finding 2: Export Funnel Leakage

Although more users created graphics, many exited before downloading.

```text
82,000 users
↓
24,000 export clicks
```

More than 58,000 users abandoned the flow before export.

---

## Finding 3: Pricing Discovery Collapsed

Paywall traffic dropped sharply.

```text
8.5%
↓
3.1%
```

Resulting in a decline in premium subscriptions.

```text
3.0%
↓
2.64%
```

---

# Root Cause

The redesign optimized engagement rather than purchase intent.

```text
Easy Prompt Box
        ↓
Casual Image Testing
        ↓
Surprise Paywall on Export
        ↓
Users Exit
```

---

## Setup Change

### Previous Flow

- Three business qualification questions.
- Explicit premium template selection.
- Clear monetization expectations.

### New Flow

Users immediately landed on:

```text
Type anything to make an image instantly!
```

---

## Low-Intent Traffic

Removing friction attracted casual experimentation.

Examples included:

- Funny cat astronaut
- Meme prompts
- Random image generation

Many users never intended to purchase.

---

## Surprise Paywall Shock

Serious users spent time creating graphics believing the experience was free.

Only when attempting export did they encounter pricing.

This unexpected friction damaged trust and reduced paywall traffic.

---

# Solution

## Variant C

Instead of rolling back globally, LaunchDarkly feature flags were used to introduce a third experiment variant.

One piece of useful friction was reintroduced:

```text
Enter your business website
to automatically sync your
brand's official color palette.
```

This filtered low-intent users while preserving the AI experience.

---

## Customer Recovery Workflow

Users who abandoned immediately after hitting the paywall received an email within 60 minutes containing:

- A high-resolution preview.
- A free trial offer.

This reduced permanent churn and improved customer sentiment.

---

# Prevention

## Statistical Validation

Experiment outcomes are validated using a Chi-Square significance test.

Complete implementation:

```text
python/significance_test.py
```

---

## Canary Rollouts

Future onboarding and pricing releases must follow:

```text
1% Traffic
     ↓
48 Hours
     ↓
Metric Monitoring
     ↓
Global Rollout
```

Automatic rollback is triggered whenever premium conversion falls outside historical thresholds.

---

# Lessons Learned

## Engagement ≠ Revenue

Higher activity does not necessarily imply higher monetization.

---

## User Intent Matters

Removing friction indiscriminately can attract the wrong audience.

---

## Hidden Paywalls Destroy Trust

Unexpected monetization creates negative user experiences and hurts conversion.

---

## Guardrails Are Essential

Statistical validation and canary deployments should accompany every experiment.

---

# Repository Structure

```text
AI-Onboarding-Conversion-Analysis

│── README.md

├── sql
│     funnel_analysis.sql

├── python
│     significance_test.py

└── docs
      assumptions.md
```

---

# Connect With Me

I enjoy solving ambiguous product and business problems through structured analytics and experimentation.

I am actively seeking opportunities in:

- Data Analytics
- Product Analytics
- Business Intelligence

- 🔗 LinkedIn: www.linkedin.com/in/shivanshawasthi87
- 📧 Email: shivanshawasthi87@gmail.com
