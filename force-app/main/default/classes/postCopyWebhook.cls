public class postCopyWebhook implements SandboxPostCopy {

    @TestVisible private static String testWebhookUrl;

    @TestVisible
    public static void setTestWebhookUrl(String url) {
        testWebhookUrl = url;
    }

    public void runApexClass(SandboxContext context) {
        System.debug('postCopyWebhook: runApexClass started');
        try {
            String sandboxName = System.Domain.current().getSandboxName();
            System.debug('postCopyWebhook: Detected sandboxName = ' + sandboxName);
            System.debug('postCopyWebhook: About to call sendWebhook');
            sendWebhook(sandboxName, UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
            System.debug('postCopyWebhook: sendWebhook called successfully');
        } catch (Exception e) {
            System.debug('postCopyWebhook: Exception: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
        System.debug('postCopyWebhook: runApexClass finished');
    }

    public static void sendWebhook(String sandboxName, String orgId, String orgName) {
        System.debug('postCopyWebhook: sendWebhook called with values:');
        System.debug('  sandboxName: ' + sandboxName);
        System.debug('  orgId: ' + orgId);
        System.debug('  orgName: ' + orgName);
        String webhookUrl;
        if (Test.isRunningTest() && testWebhookUrl != null) {
            webhookUrl = testWebhookUrl;
        } else {
            List<PostCopyWebhookUrl__mdt> urls = [
                SELECT Url__c FROM PostCopyWebhookUrl__mdt ORDER BY SystemModStamp DESC LIMIT 1
            ];
            if (!urls.isEmpty() && String.isNotBlank(urls[0].Url__c)) {
                webhookUrl = urls[0].Url__c;
            } else {
                System.debug('Webhook URL not found in custom metadata or is blank.');
                return;
            }
        }

        Map<String, String> payload = new Map<String, String>{
            'sandboxName' => sandboxName,
            'orgId' => orgId,
            'orgName' => orgName
        };
        String jsonBody = JSON.serialize(payload);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(webhookUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Webhook response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Error sending webhook: ' + e.getMessage());
        }
    }

    public static void sendTestWebhook(String sandboxName, String orgId, String orgName) {
        sendWebhook(sandboxName, orgId, orgName);
    }
}
