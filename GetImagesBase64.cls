/*

Author : Irwan Rahman Sunarto
Last Update : 08/11/2024

Main class for GetImagesBase64
Please use GetImagesBase64_UnitTest for the Unit Test

*/

public class GetImagesBase64 {
    public class FileRequest {
        @InvocableVariable(label='Record Id' required=true)
        public Id recordId;
    }

    @InvocableMethod(label='Get Files as Base64')
    public static List<List<String>> getFilesAsBase64(List<FileRequest> requests) {
        List<List<String>> allBase64Files = new List<List<String>>();
        
        for (FileRequest request : requests) {
            List<String> base64Files = new List<String>();

            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :request.recordId
            ];
            
            for (ContentDocumentLink link : links) {
                ContentVersion version = [
                    SELECT VersionData 
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :link.ContentDocumentId 
                    ORDER BY VersionNumber DESC 
                    LIMIT 1
                ];
                base64Files.add(EncodingUtil.base64Encode(version.VersionData));
            }
            
            allBase64Files.add(base64Files);
        }
        
        return allBase64Files;
    }
}