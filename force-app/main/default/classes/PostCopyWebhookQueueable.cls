public class PostCopyWebhookQueueable implements Queueable, Database.AllowsCallouts {
    private String sandboxName;
    private String orgId;
    private String orgName;

    public PostCopyWebhookQueueable(String sandboxName, String orgId, String orgName) {
        this.sandboxName = sandboxName;
        this.orgId = orgId;
        this.orgName = orgName;
    }

    public void execute(QueueableContext context) {
        System.debug('PostCopyWebhookQueueable: Started with sandboxName=' + sandboxName + ', orgId=' + orgId + ', orgName=' + orgName);
        postCopyWebhook.sendWebhook(sandboxName, orgId, orgName);
        System.debug('PostCopyWebhookQueueable: sendWebhook finished');
    }
}
