# Salesforce Post-Copy Webhook Automation

This Salesforce DX project provides an automated solution for sending webhook notifications after a sandbox is created or refreshed. It is designed to run in the post-copy context, extract key sandbox details, and notify external systems (such as Zapier or custom endpoints) with relevant information.

---

## Features

- **Automated Webhook Trigger:**
  - Fires automatically after a sandbox is created or refreshed via the `SandboxPostCopy` interface.
- **Robust Sandbox Name Extraction:**
  - Extracts the sandbox name from a regular System Administrator user's username for reliability.
- **Queueable Callout Architecture:**
  - Uses a `Queueable` Apex job to perform HTTP callouts, ensuring compatibility with Salesforce platform restrictions.
- **Custom Metadata for Webhook URL:**
  - Easily manage and update the webhook endpoint via custom metadata (`PostCopyWebhookUrl__mdt`).
- **Extensive Debug Logging:**
  - Logs every step of the process for easy troubleshooting and auditability.
- **Test Coverage:**
  - Includes test classes for both the main logic and the queueable job, with HTTP callout mocking.

---

## How It Works
1. **Sandbox Creation/Refresh:**
   - Salesforce triggers the `postCopyWebhook` class after a sandbox is created or refreshed.
2. **Information Gathering:**
   - The class queries an active System Administrator user to extract the sandbox name, and collects org ID and org name.
3. **Queueable Enqueue:**
   - A `Queueable` Apex job (`PostCopyWebhookQueueable`) is enqueued with the extracted data.
4. **Webhook Callout:**
   - The queueable job retrieves the webhook URL from custom metadata and sends a POST request with the org and sandbox details in JSON format.
5. **Debug Logging:**
   - All steps and variable states are logged for transparency and debugging.

---

## Usage Instructions

### 1. **Deployment**
Deploy all classes and metadata to your Salesforce org:

```sh
sf project deploy start \
  -d force-app/main/default/classes/postCopyWebhook.cls \
  -d force-app/main/default/classes/postCopyWebhook.cls-meta.xml \
  -d force-app/main/default/classes/PostCopyWebhookQueueable.cls \
  -d force-app/main/default/classes/PostCopyWebhookQueueable.cls-meta.xml \
  -d force-app/main/default/classes/PostCopyWebhookQueueableTest.cls \
  -d force-app/main/default/classes/PostCopyWebhookQueueableTest.cls-meta.xml
```

### 2. **Configure Webhook URL**
- Add or update a `PostCopyWebhookUrl__mdt` custom metadata record with your desired webhook endpoint.

### 3. **Testing**
- Run all tests to ensure coverage and correct behavior:

```sh
sf apex test run --classnames PostCopyWebhookQueueableTest,postCopyWebhookTest --result-format human --target-org <your-org-alias>
```

### 4. **Monitor Execution**
- Use Salesforce debug logs to monitor post-copy execution and webhook delivery.

---

## Example Payload Sent to Webhook
```json
{
  "orgName": "Your Org Name",
  "orgId": "00Dxxxxxxxxxxxx",
  "sandboxName": "mysandbox"
}
```

---

## Troubleshooting & Support
- All errors and variable values are logged via `System.debug` for easy troubleshooting.
- If HTTP callouts are blocked, ensure the queueable job is being enqueued and executed properly.
- For questions or enhancements, open an issue or contact the project maintainer.
