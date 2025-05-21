@isTest
public class PostCopyWebhookQueueableTest {
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testQueueableWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        String sandboxName = 'TestSandbox';
        String orgId = '00Dxx0000001gPFEAY';
        String orgName = 'Test Org';

        Test.startTest();
        System.enqueueJob(new PostCopyWebhookQueueable(sandboxName, orgId, orgName));
        Test.stopTest();
        // No exception means success, but you could add more asserts if you capture the payload
    }
}
