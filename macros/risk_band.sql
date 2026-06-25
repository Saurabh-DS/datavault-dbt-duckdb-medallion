{#
  risk_band — Classify a customer into a risk tier.

  Thresholds are driven by project variables so they can be tuned in
  dbt_project.yml or overridden at runtime without changing macro code:

    vars:
      risk_high_claim_threshold: 3       # lifetime claims ≥ this → high
      risk_high_value_threshold: 10000   # lifetime value ≥ this  → high

  Usage:
    {{ risk_band('lifetime_claim_count', 'lifetime_claim_value') }} as risk_band

  Returns:
    'high'   — lifetime_claim_count ≥ threshold OR lifetime_claim_value ≥ threshold
    'medium' — at least one claim
    'low'    — no claims

  Arguments:
    claim_count_col (str) — Column name holding lifetime claim count
    claim_value_col (str) — Column name holding lifetime claim value in GBP
#}

{% macro risk_band(claim_count_col, claim_value_col) %}

  case
    when {{ claim_count_col }} >= {{ var('risk_high_claim_threshold', 3) }}
      or {{ claim_value_col }} >= {{ var('risk_high_value_threshold', 10000) }}
      then 'high'
    when {{ claim_count_col }} >= 1
      then 'medium'
    else 'low'
  end

{% endmacro %}
