# DataVault

A production-grade dbt analytics engineering pipeline built on DuckDB. Implements medallion architecture (bronze, silver, gold), SCD Type 1 and Type 2, dbt data contracts, custom singular tests, slim CI via GitHub Actions, and daily orchestration via Apache Airflow.

Built on a synthetic UK motor insurance dataset. The insurance domain is intentional: it mirrors the FCA-regulated data environment the author works in professionally and makes SCD and data quality requirements concrete rather than contrived.

Live docs (lineage graph, column-level descriptions, test results): *Deploy to GitHub Pages after first push to main — see CI/CD section.*

---

## What this project covers

| Concept | Implementation |
|---|---|
| Medallion architecture | Bronze (staging views), Silver (intermediate tables), Gold (mart tables) |
| SCD Type 1 | dbt snapshot with check strategy on customer contact details |
| SCD Type 2 | dbt snapshot with timestamp strategy on policy premium history |
| Data contracts | Enforced column names and types on all gold mart models |
| Source freshness | 24h warn / 48h error thresholds on raw seeds |
| Custom singular tests | Overlapping SCD date range detection, claim amount vs vehicle value |
| Generic schema tests | not_null, unique, relationships, accepted_values, dbt_expectations range checks |
| Slim CI | GitHub Actions running staging and intermediate build on every pull request |
| Docs deployment | dbt docs auto-published to GitHub Pages on merge to main |
| Orchestration | Apache Airflow DAG with task-level dependency chain and Slack failure alerts |
| Reusable macros | risk_band classification, schema name override, cents_to_pounds utility |
| Project variables | Configurable renewal lookahead days and risk thresholds in dbt_project.yml |

---

## Architecture

```
Raw Seeds (CSV)
     |
     v
+-------------------+
|  BRONZE (staging) |   -- Views. Type casting, renaming, _loaded_at timestamp.
|  stg_customers    |   -- No business logic here.
|  stg_policies     |
|  stg_claims       |
+-------------------+
     |
     |-----> SCD Snapshots
     |       scd_customers (SCD Type 1: check strategy on address/phone)
     |       scd_policies  (SCD Type 2: timestamp strategy on premium)
     |
     v
+-------------------------+
|  SILVER (intermediate)  |   -- Tables. Business logic, joins, aggregations.
|  int_policy_claims_bridge    |   -- LEFT JOIN policies to claims. Claim metrics per policy.
|  int_customer_risk_profile   |   -- Customer-level lifetime aggregation + risk_band macro.
+-------------------------+
     |
     v
+------------------+
|  GOLD (marts)    |   -- Tables with enforced dbt contracts.
|  mart_customer_risk      |   -- One row per customer. Risk band, lifetime claim history.
|  mart_claims_summary     |   -- Monthly claim aggregation with 3-month rolling averages.
|  mart_policy_renewals    |   -- Active policies due for renewal in next 30 days.
+------------------+
```

---

## Quickstart

You need Python 3.11 and Git. Docker is only needed for Airflow orchestration.

### 1. Clone and install

```bash
git clone https://github.com/Saurabh-DS/datavault-dbt-duckdb-medallion.git
cd datavault-dbt-duckdb-medallion
pip install -r requirements.txt
dbt deps --profiles-dir .
```

### 2. Generate synthetic data

```bash
python scripts/generate_data.py
```

This writes three CSV files into `seeds/`:
- `raw_customers.csv` (10,000 rows)
- `raw_policies.csv` (~25,000 rows, including renewal rows for SCD Type 2 demonstration)
- `raw_claims.csv` (8,000 rows)

The script prints a summary showing SCD Type 1 eligible rows (customers with address changes) and SCD Type 2 eligible rows (policies with renewal history via shared `policy_number`).

### 3. Run the full pipeline

```bash
make full-run
```

This runs: `generate → seed → snapshot → build → test`

Or run steps individually:

```bash
dbt seed --profiles-dir .
dbt snapshot --profiles-dir .
dbt build --profiles-dir .
dbt test --profiles-dir .
```

### 4. View the lineage graph

```bash
make docs
```

Opens the dbt docs UI at http://localhost:8080. The lineage graph shows every model, snapshot, seed, and test and their dependencies.

### 5. Run Airflow locally (optional)

```bash
make airflow-up
```

Opens Airflow at http://localhost:8080. Default credentials: `admin` / `admin`. The `datavault_pipeline` DAG runs daily at 06:00 UTC. Trigger it manually from the UI to test.

> **Slack alerts**: See [SLACK_SETUP.md](SLACK_SETUP.md) for a step-by-step guide to configuring Slack failure notifications.

---

## Project structure

```
datavault-dbt-duckdb-medallion/
  models/
    staging/                  Bronze layer. One model per source table.
      stg_customers.sql
      stg_policies.sql
      stg_claims.sql
      schema.yml              Source freshness, column tests, relationship tests.
    intermediate/             Silver layer. Business logic and aggregations.
      int_policy_claims_bridge.sql
      int_customer_risk_profile.sql
      schema.yml
    marts/                    Gold layer. Contract-enforced output tables.
      mart_customer_risk.sql
      mart_claims_summary.sql
      mart_policy_renewals.sql
      schema.yml              Column-level contracts, accepted value tests.
  snapshots/
    scd_customers.sql         SCD Type 1. Overwrites on address or phone change.
    scd_policies.sql          SCD Type 2. Preserves premium history on renewal.
  tests/
    assert_no_overlapping_scd_policy_dates.sql
    assert_claim_amount_within_vehicle_value.sql
  macros/
    generate_schema_name.sql  Overrides default dbt schema prefixing for DuckDB.
    risk_band.sql             Classifies customers as low / medium / high risk.
    cents_to_pounds.sql       Utility macro for future monetary conversions.
  analyses/
    renewal_pipeline_value.sql   One-off analysis. Not materialised.
  seeds/
    raw_customers.csv
    raw_policies.csv
    raw_claims.csv
    schema.yml
  scripts/
    generate_data.py          Synthetic data generator. Run before dbt seed.
  .github/
    workflows/
      ci.yml                  Slim CI on pull requests.
      docs.yml                Full build and docs deploy on merge to main.
  dags/
    datavault_dag.py          Airflow DAG definition.
  docker-compose.yml          Local Airflow stack.
  dbt_project.yml
  profiles.yml
  packages.yml
  requirements.txt
  Makefile
  SLACK_SETUP.md              Step-by-step guide to Slack alert configuration.
```

---

## Data model

### Synthetic dataset: UK motor insurance

The synthetic data represents a mid-size UK motor insurer. All data is generated by `scripts/generate_data.py` and is entirely fictitious.

**raw_customers** (10,000 rows)
Represents the customer master record. 20 percent of customers have a later `updated_at` date indicating an address or phone number change. These records drive SCD Type 1 snapshot behaviour.

**raw_policies** (~25,000 rows)
One row per policy version. Each customer holds 1 to 4 policies. 20 percent of expired policies have a renewal row with a new `policy_id`, the same stable `policy_number`, incremented `no_claims_discount`, and recalculated `annual_premium`. These renewal rows drive SCD Type 2 snapshot behaviour on the `scd_policies` snapshot.

The `policy_number` is the stable identifier used as the snapshot `unique_key`. A `policy_number` with two rows in the snapshot (before and after renewal) is the SCD Type 2 demonstration record.

Annual premium is calculated from `vehicle_value`, `cover_type`, and `no_claims_discount` using a deterministic formula, making the data internally consistent for testing downstream mart calculations.

**raw_claims** (8,000 rows)
One row per claim. Claims join to policies on `policy_id`. Comprehensive policies are 3x more likely to generate claims than third party policies. Settled claims have a `days_to_settle` value. Open and rejected claims have null `days_to_settle`.

---

## SCD implementation detail

### SCD Type 1: scd_customers

Uses the dbt `check` strategy. Tracks changes to: `address_line_1`, `city`, `postcode`, `phone`.

When any of these columns changes on a customer record, dbt overwrites the existing snapshot row with the new values. No history is preserved. This is the correct approach for contact details: you want the current address, not a history of every address the customer has ever had.

To see SCD Type 1 in action, run `dbt snapshot` twice with different versions of `raw_customers.csv`. The second run will overwrite rows where address or phone changed.

```sql
-- Verify SCD Type 1 is working: should show one row per customer
select customer_id, count(*) as row_count
from snapshots.scd_customers
group by customer_id
having count(*) > 1
-- Returns zero rows if SCD Type 1 is working correctly
```

### SCD Type 2: scd_policies

Uses the dbt `timestamp` strategy on the `updated_at` column. `policy_number` is the stable `unique_key`. When a `policy_number` row changes (renewal with new premium), dbt:
1. Sets `dbt_valid_to` on the old row to the new `updated_at` value
2. Inserts a new row with `dbt_valid_from = updated_at` and `dbt_valid_to = null`

The `is_current` flag (`dbt_valid_to is null`) identifies the current policy version. The full history allows you to reconstruct what premium a customer was paying at any point in time.

```sql
-- Verify SCD Type 2 is working: policy_numbers with renewal history should have 2 rows
select
    policy_number,
    policy_id,
    annual_premium,
    no_claims_discount,
    dbt_valid_from,
    dbt_valid_to
from snapshots.scd_policies
where policy_number in (
    select policy_number
    from snapshots.scd_policies
    group by policy_number
    having count(*) > 1
)
order by policy_number, dbt_valid_from
```

---

## Data contracts

All gold mart models have enforced dbt contracts. A contract declares every expected column name and its data type. The dbt build fails if:
- A model produces a column not declared in the contract
- A declared column is missing from the model output
- A column's data type does not match the declaration

This prevents schema drift from breaking downstream BI tools or data consumers without warning.

Example contract block in `models/marts/schema.yml`:

```yaml
models:
  - name: mart_customer_risk
    config:
      contract:
        enforced: true
    columns:
      - name: customer_id
        data_type: varchar
        constraints:
          - type: not_null
      - name: risk_band
        data_type: varchar
```

---

## Custom tests

### assert_no_overlapping_scd_policy_dates

Tests the SCD Type 2 snapshot. A correct SCD Type 2 implementation should never have two rows for the same `policy_number` where the date ranges overlap. The test self-joins `scd_policies` and checks for any row pair where the first row's `dbt_valid_to` is later than the second row's `dbt_valid_from`. Zero rows returned means the test passes.

### assert_claim_amount_within_vehicle_value

Tests business logic. A settled claim cannot exceed the insured vehicle value. If this test fails, it indicates either bad source data or a join error in the intermediate layer that has matched a claim to the wrong policy.

---

## CI/CD

### Pull request CI (ci.yml)

Triggered on every pull request to `main`. Runs:
1. Install dependencies
2. Generate synthetic data
3. `dbt seed`
4. `dbt compile` (catches syntax errors before any model runs)
5. `dbt build` for staging and intermediate layers only
6. `dbt test` for singular tests only

### Merge to main: docs deploy (docs.yml)

Triggered on every merge to `main`. Runs the full pipeline (`seed → snapshot → build → test`) and then `dbt docs generate`. The generated docs site is published to GitHub Pages via `peaceiris/actions-gh-pages`.

**To enable GitHub Pages:**
1. Repo Settings → Pages → Source: Deploy from branch
2. Branch: `gh-pages`, Folder: `/` (root)
3. Save — the URL appears at the top of the Pages settings page

---

## Airflow orchestration

The `datavault_pipeline` DAG runs daily at 06:00 UTC. Task dependency chain:

```
dbt_seed → dbt_snapshot → dbt_build_staging → dbt_build_intermediate → dbt_build_marts → dbt_test_singular
```

Each task is a `BashOperator` running a scoped dbt command. On failure, the `on_failure_callback` sends a Slack message via a webhook stored in the `datavault_slack` Airflow connection.

**To configure Slack alerts**: See [SLACK_SETUP.md](SLACK_SETUP.md).

---

## dbt project variables

Configurable in `dbt_project.yml` without touching any model SQL:

| Variable | Default | Used in |
|---|---|---|
| `renewal_lookahead_days` | 30 | `mart_policy_renewals` WHERE clause |
| `risk_high_claim_threshold` | 3 | `risk_band` macro |
| `risk_high_value_threshold` | 10000 | `risk_band` macro |

To run the pipeline with a 60-day renewal window:

```bash
dbt build --vars '{"renewal_lookahead_days": 60}' --profiles-dir .
```

---

## Macros

### risk_band(claim_count_col, claim_value_col)

Classifies a customer into low, medium, or high risk. Thresholds are driven by project vars.

```sql
{{ risk_band('lifetime_claim_count', 'lifetime_claim_value') }} as risk_band
```

Output: `'high'` if `lifetime_claim_count >= 3` or `lifetime_claim_value >= 10000`. `'medium'` if at least one claim. `'low'` otherwise.

### generate_schema_name(custom_schema_name, node)

Overrides the default dbt schema naming behaviour. Produces clean schema names: `raw`, `staging`, `intermediate`, `marts`, `snapshots`.

---

## Key design decisions

**Why DuckDB instead of Postgres or Snowflake?**
DuckDB runs in-process with no infrastructure required. Any reviewer can clone this repo and run the full pipeline in under 5 minutes with a single `make full-run` command. Swapping DuckDB for Snowflake or BigQuery requires only a change to `profiles.yml` and the dbt adapter package.

**Why seeds instead of a proper ingestion layer?**
Seeds serve the same purpose as an ingestion layer for a portfolio project: they define the shape and content of raw source data and let you focus on the transformation layer. `generate_data.py` doubles as documentation of the source schema.

**Why SCD Type 1 on customers and SCD Type 2 on policies?**
Customer contact details are operational data — you need the current address to send documents. SCD Type 1 is correct. Policy premium history is financial and regulatory data — an insurer needs to know the exact premium at the time of a claim. SCD Type 2 is correct.

**Why dbt contracts on mart models but not staging or intermediate?**
Contracts are for consumer-facing output. If a mart column is renamed, a BI dashboard breaks silently. Contracts make that failure immediate and loud.

**Why the singular SCD overlap test?**
dbt's built-in `unique` test on `dbt_scd_id` catches duplicate snapshot rows but not overlapping date ranges. A date range overlap can happen if source `updated_at` values are not monotonically increasing. The singular test catches this class of bug directly.

---

## Running specific parts

```bash
# Run only staging models
dbt build --select staging --profiles-dir .

# Run a single model and all its upstream dependencies
dbt build --select +mart_customer_risk --profiles-dir .

# Run only modified models (requires saved state manifest)
dbt build --select state:modified+ --defer --state ./prod_state --profiles-dir .

# Run all singular tests only
dbt test --select test_type:singular --profiles-dir .

# Run all tests for a specific model
dbt test --select mart_customer_risk --profiles-dir .

# Compile without running (useful for checking SQL before executing)
dbt compile --select mart_policy_renewals --profiles-dir .

# Run with a variable override
dbt build --vars '{"renewal_lookahead_days": 60}' --profiles-dir .
```

---

## Tech stack

| Tool | Version | Purpose |
|---|---|---|
| dbt Core | 1.8.7 | Transformation framework |
| dbt-duckdb | 1.8.4 | DuckDB adapter |
| DuckDB | 1.0.0 | In-process analytical database |
| dbt_utils | 1.2.0 | Utility macros |
| dbt_expectations | 0.10.3 | Extended test library |
| Apache Airflow | 2.9.1 | Pipeline orchestration |
| GitHub Actions | latest | CI/CD |
| Python | 3.11 | Data generation and Airflow DAG |
| Faker | 26.0.0 | Synthetic data generation |
| Docker Compose | 2.x | Local Airflow environment |

---

## Author

Saurabh Kabadi
Data Scientist / ML Engineer — Liverpool, UK
[linkedin.com/in/saurabhkabadi](https://linkedin.com/in/saurabhkabadi)
[github.com/Saurabh-DS](https://github.com/Saurabh-DS)
