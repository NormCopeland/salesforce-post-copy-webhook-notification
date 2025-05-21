public class postCopyWebhook implements SandboxPostCopy {

    @TestVisible private static String testWebhookUrl;

    @TestVisible
    public static void setTestWebhookUrl(String url) {
        testWebhookUrl = url;
    }

    public void runApexClass(SandboxContext context) {
        System.debug('postCopyWebhook: runApexClass started');
        try {
            String orgId = UserInfo.getOrganizationId();
            String orgName = UserInfo.getOrganizationName();
            String userName;
            try {
                // Query for an active System Administrator user
                User u = [SELECT Username FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' LIMIT 1];
                userName = u.Username;
                System.debug('postCopyWebhook: Queried admin userName = ' + userName);
            } catch (Exception e) {
                userName = UserInfo.getUserName();
                System.debug('postCopyWebhook: Failed to query User, defaulting to running user. Error: ' + e.getMessage());
                System.debug('postCopyWebhook: Fallback userName = ' + userName);
            }
            System.debug('postCopyWebhook: orgId = ' + orgId);
            System.debug('postCopyWebhook: orgName = ' + orgName);
            System.debug('postCopyWebhook: userName used for sandbox extraction = ' + userName);
            String sandboxName = extractSandboxName(userName);
            System.debug('postCopyWebhook: Extracted sandboxName = ' + sandboxName);
            System.enqueueJob(new PostCopyWebhookQueueable(sandboxName, orgId, orgName));
            System.debug('postCopyWebhook: PostCopyWebhookQueueable enqueued');
        } catch (Exception e) {
            System.debug('postCopyWebhook: Exception in runApexClass: ' + e.getMessage() + ' | ' + e.getStackTraceString());
        }
        System.debug('postCopyWebhook: runApexClass finished');
    }

    private static String extractSandboxName(String userName) {
        System.debug('postCopyWebhook: extractSandboxName called with userName = ' + userName);
        Integer lastDot = userName.lastIndexOf('.');
        Integer atSign = userName.indexOf('@');
        System.debug('postCopyWebhook: lastDot = ' + lastDot + ', atSign = ' + atSign);
        // If there's a dot after the '@', treat as sandbox username
        if (lastDot > atSign) {
            String sandboxName = userName.substring(lastDot + 1);
            System.debug('postCopyWebhook: Detected sandbox username, returning sandboxName = ' + sandboxName);
            return sandboxName;
        }
        System.debug('postCopyWebhook: No sandbox name detected, returning PRODUCTION');
        return 'PRODUCTION';
    }

    public static void sendWebhook(String sandboxName, String orgId, String orgName) {
        System.debug('postCopyWebhook: sendWebhook called with values: sandboxName=' + sandboxName + ', orgId=' + orgId + ', orgName=' + orgName);
        String webhookUrl;
        if (Test.isRunningTest() && testWebhookUrl != null) {
            System.debug('postCopyWebhook: Using testWebhookUrl for test context');
            webhookUrl = testWebhookUrl;
            System.debug('postCopyWebhook: testWebhookUrl = ' + testWebhookUrl);
        } else {
            System.debug('postCopyWebhook: Retrieving webhook URL from custom metadata');
            List<PostCopyWebhookUrl__mdt> urls = [
                SELECT Url__c FROM PostCopyWebhookUrl__mdt ORDER BY SystemModStamp DESC LIMIT 1
            ];
            System.debug('postCopyWebhook: Retrieved ' + urls.size() + ' URLs from custom metadata');
            if (!urls.isEmpty() && String.isNotBlank(urls[0].Url__c)) {
                webhookUrl = urls[0].Url__c;
                System.debug('postCopyWebhook: webhookUrl = ' + webhookUrl);
            } else {
                System.debug('postCopyWebhook: Webhook URL not found in custom metadata or is blank.');
                return;
            }
        }

        Map<String, String> payload = new Map<String, String>{
            'sandboxName' => sandboxName,
            'orgId' => orgId,
            'orgName' => orgName
        };
        System.debug('postCopyWebhook: payload = ' + payload);
        String jsonBody = JSON.serialize(payload);
        System.debug('postCopyWebhook: jsonBody = ' + jsonBody);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(webhookUrl);
        System.debug('postCopyWebhook: req endpoint = ' + webhookUrl);
        req.setMethod('POST');
        System.debug('postCopyWebhook: req method = POST');
        req.setHeader('Content-Type', 'application/json');
        System.debug('postCopyWebhook: req header = Content-Type: application/json');
        req.setBody(jsonBody);
        System.debug('postCopyWebhook: req body = ' + jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('postCopyWebhook: Webhook response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('postCopyWebhook: Error sending webhook: ' + e.getMessage());
        }
    }

    public static void sendTestWebhook(String sandboxName, String orgId, String orgName) {
        System.debug('postCopyWebhook: sendTestWebhook called with values: sandboxName=' + sandboxName + ', orgId=' + orgId + ', orgName=' + orgName);
        sendWebhook(sandboxName, orgId, orgName);
        System.debug('postCopyWebhook: sendTestWebhook finished');
    }
}
