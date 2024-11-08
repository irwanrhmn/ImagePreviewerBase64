/*

Author : Irwan Rahman Sunarto
Last Update : 08/11/2024

Unit Test for GetImagesBase64
Currently use Your_Object__c for the Salesforce Object
Please replace the logic in setupTestData to match with your Object

*/

@isTest
private class GetImagesBase64_UnitTest implements HttpCalloutMock {
    
    private static HttpResponse response;
    
    public HTTPResponse respond(HTTPRequest req) {
        return response;
    }
    
    private static void setMockResponse(Integer statusCode, String body) {
        response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setBody(body);
    }
    
    @TestSetup
    static void setupTestData() {
        Your_Object__c testUser1 = new Your_Object__c(
            Name = 'Nawri',
            Service_Territory__c = '0Hh5g000000Q5U3CAK'
        );
        Your_Object__c testUser2 = new Your_Object__c(
            Name = 'Test User 2',
            Service_Territory__c = '0Hh5g000000Q5U3CAK'
        );
        insert new List<Your_Object__c>{testUser1, testUser2};
        
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 3; i++) {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document ' + i;
            cv.PathOnClient = 'TestDocument' + i + '.jpg';
            cv.VersionData = Blob.valueOf('Test Content ' + i);
            cv.IsMajorVersion = true;
            contentVersions.add(cv);
        }
        insert contentVersions;
        
        List<Id> contentDocumentIds = new List<Id>();
        for (ContentVersion cv : [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersions]) {
            contentDocumentIds.add(cv.ContentDocumentId);
        }
        
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        for (Id docId : contentDocumentIds) {
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = testUser1.Id;
            link.ContentDocumentId = docId;
            link.ShareType = 'V';
            links.add(link);
        }
        insert links;
    }
    
    @isTest
    static void testGetFilesAsBase64() {
        Your_Object__c testUser = [SELECT Id FROM Your_Object__c WHERE Name = 'Nawri' LIMIT 1];
        
        setMockResponse(200, '["VGVzdCBDb250ZW50IDA=", "VGVzdCBDb250ZW50IDE=", "VGVzdCBDb250ZW50IDI="]');
        
        Test.setMock(HttpCalloutMock.class, new FTTH_Get_Images_From_Record_Test());
        
        GetImagesBase64.FileRequest request = new GetImagesBase64.FileRequest();
        request.recordId = testUser.Id;
        
        Test.startTest();
        List<List<String>> result = GetImagesBase64.getFilesAsBase64(new List<GetImagesBase64.FileRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return a list with one element');
        System.assertEquals(3, result[0].size(), 'Should return 3 base64 encoded files');
        
        for (String base64File : result[0]) {
            System.assert(base64File.startsWith('VGVzdCBDb250ZW50'), 'Base64 string should start with the encoded "Test Content"');
        }
    }
    
    @isTest
    static void testGetFilesAsBase64NoFiles() {
        Your_Object__c testUser = [SELECT Id FROM Your_Object__c WHERE Name = 'Test User 2' LIMIT 1];
        
        setMockResponse(200, '[]');
        
        Test.setMock(HttpCalloutMock.class, new FTTH_Get_Images_From_Record_Test());
        
        GetImagesBase64.FileRequest request = new GetImagesBase64.FileRequest();
        request.recordId = testUser.Id;
        
        Test.startTest();
        List<List<String>> result = GetImagesBase64.getFilesAsBase64(new List<GetImagesBase64.FileRequest>{request});
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Should return a list with one element');
        System.assertEquals(0, result[0].size(), 'Should return an empty list when no files are found');
    }
    
    @isTest
    static void testGetFilesAsBase64MultipleRequests() {
        Your_Object__c testUser1 = [SELECT Id FROM Your_Object__c WHERE Name = 'Nawri' LIMIT 1];
        Your_Object__c testUser2 = [SELECT Id FROM Your_Object__c WHERE Name = 'Test User 2' LIMIT 1];
        
        setMockResponse(200, '[["VGVzdCBDb250ZW50IDA=", "VGVzdCBDb250ZW50IDE=", "VGVzdCBDb250ZW50IDI="], []]');
        
        Test.setMock(HttpCalloutMock.class, new FTTH_Get_Images_From_Record_Test());
        
        GetImagesBase64.FileRequest request1 = new GetImagesBase64.FileRequest();
        request1.recordId = testUser1.Id;
        GetImagesBase64.FileRequest request2 = new GetImagesBase64.FileRequest();
        request2.recordId = testUser2.Id;
        
        Test.startTest();
        List<List<String>> result = GetImagesBase64.getFilesAsBase64(new List<GetImagesBase64.FileRequest>{request1, request2});
        Test.stopTest();
        
        System.assertEquals(2, result.size(), 'Should return a list with two elements');
        System.assertEquals(3, result[0].size(), 'First user should have 3 files');
        System.assertEquals(0, result[1].size(), 'Second user should have 0 files');
        System.assert(result[0][0].startsWith('VGVzdCBDb250ZW50'), 'Base64 string should start with the encoded "Test Content"');
    }
}