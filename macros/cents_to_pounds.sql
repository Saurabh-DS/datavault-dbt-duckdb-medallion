{#
  cents_to_pounds — Convert a pence (integer) column to pounds (decimal).

  UK insurance source systems often store monetary values as integer pence
  to avoid floating-point precision issues. This macro handles the conversion
  consistently across all models.

  Usage:
    {{ cents_to_pounds('premium_pence') }} as annual_premium_gbp

  Returns: column / 100 cast to a double (decimal) value.

  Note: Not currently used in any model — scaffolded for future ingestion
  layers that receive monetary data in pence from upstream source systems.

  Arguments:
    col (str) — Column name containing the pence value
#}

{% macro cents_to_pounds(col) %}

  ({{ col }} / 100.0)

{% endmacro %}
