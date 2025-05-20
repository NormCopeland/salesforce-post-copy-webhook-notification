@isTest(SeeAllData=true)
public class postCopyWebhookTest {
    public static String lastRequestBody;
    // Mock class for HTTP callout
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            postCopyWebhookTest.lastRequestBody = req.getBody();
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testSendWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        String sandboxName = 'TestSandbox';
        String orgId = '00Dxx0000001gPFEAY';
        String orgName = 'TestOrgName';

        Test.startTest();
        postCopyWebhook.sendWebhook(sandboxName, orgId, orgName);
        Test.stopTest();

        // Verify the request body contains orgName
        System.assert(postCopyWebhookTest.lastRequestBody != null, 'Request body should not be null');
        System.assert(postCopyWebhookTest.lastRequestBody.contains('"orgName":"' + orgName + '"'), 'Request body should contain orgName');
    }
}