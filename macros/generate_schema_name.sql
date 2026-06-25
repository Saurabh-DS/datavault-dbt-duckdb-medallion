{#
  generate_schema_name — Override dbt's default schema prefixing behaviour.

  Without this override, dbt prepends the target name to every schema:
    dev  + staging  → dev_staging
    prod + marts    → prod_marts

  This override strips the prefix so schemas are clean:
    staging, intermediate, marts, snapshots, raw

  This is the pattern recommended in the dbt docs for projects that want
  predictable, environment-independent schema names. It is intentional that
  the target name is ignored — all environments use the same schema names,
  separated by the DuckDB file path (dev vs prod) rather than schema names.

  Source: https://docs.getdbt.com/docs/build/custom-schemas
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

  {%- set default_schema = target.schema -%}

  {%- if custom_schema_name is none -%}

    {# No custom schema declared on this node — use the target default #}
    {{ default_schema }}

  {%- else -%}

    {# Custom schema declared — use it as-is, no target prefix #}
    {{ custom_schema_name | trim }}

  {%- endif -%}

{%- endmacro %}
