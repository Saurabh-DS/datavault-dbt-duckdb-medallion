# Slack Webhook Setup for DataVault Airflow Alerts

This guide walks you through creating a Slack app, getting a webhook URL,
and wiring it into the DataVault Airflow stack so the DAG sends alerts on failure.

---

## Step 1 — Create a Slack App

1. Go to [https://api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App**
3. Choose **From scratch**
4. Give it a name: `DataVault Alerts`
5. Select your Slack workspace
6. Click **Create App**

---

## Step 2 — Enable Incoming Webhooks

1. In the left sidebar, click **Incoming Webhooks**
2. Toggle **Activate Incoming Webhooks** → On
3. Click **Add New Webhook to Workspace**
4. Select the channel where you want alerts (e.g. `#data-alerts` or `#general`)
5. Click **Allow**
6. Copy the **Webhook URL** — it looks like:

```
https://hooks.slack.com/services/YOUR_WORKSPACE_ID/YOUR_CHANNEL_ID/YOUR_TOKEN_HERE
```

Keep this URL safe. Anyone with it can post to your Slack channel.

---

## Step 3 — Add the Connection in Airflow

1. Open Airflow at [http://localhost:8080](http://localhost:8080)
   - Username: `admin`
   - Password: `admin`

2. Go to **Admin → Connections** (top menu bar)

3. Click **+** (Add a new connection)

4. Fill in exactly:

   | Field       | Value                                                   |
   |-------------|--------------------------------------------------------|
   | **Conn Id** | `datavault_slack`                                      |
   | **Conn Type** | `HTTP`                                               |
   | **Host**    | `https://hooks.slack.com`                              |
   | **Password**| Paste your full webhook URL here (the entire URL)      |
   | **Schema**  | `https`                                                |

   > **Important**: The `datavault_slack` Conn Id must match exactly —
   > the DAG code looks up this specific ID.

5. Click **Save**

---

## Step 4 — Test the Alert

You can trigger a test alert directly from the Airflow UI:

1. Go to **DAGs** → `datavault_pipeline`
2. Click **Trigger DAG** (▶ button)
3. If you want to test the failure path, temporarily break a task:
   - Edit `dags/datavault_dag.py`
   - Change one BashOperator command to something that will fail,
     e.g. `bash_command="exit 1"`
   - Save the file — Airflow picks up DAG changes automatically
4. Trigger the DAG and watch the Slack channel for the alert

Restore the original command after testing.

---

## What the Alert Looks Like

```
🔴 DataVault pipeline failure
DAG:   datavault_pipeline
Task:  dbt_build_marts
Run:   2024-03-15 06:00:00+00:00
View task logs
```

The "View task logs" link opens the Airflow task log directly,
so you can diagnose the failure without leaving Slack.

---

## Troubleshooting

**No alert received after a task failure:**
- Check that the Conn Id is exactly `datavault_slack` (case-sensitive)
- Verify the webhook URL is in the **Password** field, not Host
- Check the Airflow scheduler logs: `make airflow-logs`
- Check the Slack app is still installed in your workspace:
  [https://api.slack.com/apps](https://api.slack.com/apps)

**"Connection not found" error in Airflow logs:**
- The `datavault_slack` connection was not saved — repeat Step 3

**Webhook returns HTTP 400:**
- The JSON payload format is wrong — check the `send_slack_failure_alert`
  function in `dags/datavault_dag.py`

**Webhook returns HTTP 403:**
- The webhook URL has been revoked — regenerate it in Step 2

---

## Rotating the Webhook URL

If the webhook URL is compromised:
1. Go to [https://api.slack.com/apps](https://api.slack.com/apps) → DataVault Alerts
2. Incoming Webhooks → Revoke the old URL → Add New Webhook
3. Update the Airflow connection Password with the new URL (Admin → Connections)
