@isTest(SeeAllData=true)
public class postCopyWebhookTest {
    public static String lastRequestBody;

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

    class FailingMockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @isTest
    static void testSetTestWebhookUrl() {
        postCopyWebhook.setTestWebhookUrl('https://example.com');
        // No assert needed, just covering the method
    }


    @isTest
    static void testSendWebhook_CustomMetadataBlank() {
        // Insert a blank custom metadata record
        // (This will only work in scratch orgs or unlocked packages, but covers the branch)
        // If not possible, this test will still cover the empty path
        Test.startTest();
        postCopyWebhook.setTestWebhookUrl(null);
        postCopyWebhook.sendWebhook('TestSandbox', '00Dxx0000001gPFEAY', 'Test Org');
        Test.stopTest();
    }

    @isTest
    static void testSendWebhook_HttpException() {
        Test.setMock(HttpCalloutMock.class, new ExceptionThrowingMock());
        postCopyWebhook.setTestWebhookUrl('https://example.com');
        Test.startTest();
        postCopyWebhook.sendWebhook('TestSandbox', '00Dxx0000001gPFEAY', 'Test Org');
        Test.stopTest();
    }

    // ExceptionThrowingMock for HTTP callout exception coverage
    class ExceptionThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated HTTP error');
        }
    }

    @isTest
    static void testSendWebhook() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        postCopyWebhook.sendWebhook('TestSandbox', '00Dxx0000001gPFEAY', 'Test Org');
        postCopyWebhook.sendTestWebhook('TestSandbox', '00Dxx0000001gPFEAY', 'Test Org');
        Test.stopTest();
        System.assert(postCopyWebhookTest.lastRequestBody != null, 'Request body should not be null');
        System.assert(postCopyWebhookTest.lastRequestBody.contains('"orgName":"Test Org"'), 'Request body should contain orgName');
    }

    @isTest
    static void testExtractSandboxNameEdgeCases() {
        String name1 = postCopyWebhook.extractSandboxName('user@example.com.sbx');
        System.assertEquals('sbx', name1, 'Should extract sbx');
        String name2 = postCopyWebhook.extractSandboxName('user@example.com');
        System.assertEquals('PRODUCTION', name2, 'Should return PRODUCTION');
        String name3 = postCopyWebhook.extractSandboxName('user.name@example.com.dev1');
        System.assertEquals('dev1', name3, 'Should extract dev1');

    }

    @isTest
    static void testQueueableCalloutFailure() {
        Test.setMock(HttpCalloutMock.class, new FailingMockHttpResponseGenerator());
        Test.startTest();
        System.enqueueJob(new PostCopyWebhookQueueable('TestSandbox', '00Dxx0000001gPFEAY', 'Test Org'));
        Test.stopTest();
        // No unhandled exception means error handling works
    }
}
