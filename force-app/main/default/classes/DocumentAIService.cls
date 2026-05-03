public without sharing class DocumentAIService {

    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
    }

    @InvocableMethod(label='Process Document AI')
    public static List<String> process(List<Request> requests) {

        List<String> results = new List<String>();
        if (requests.isEmpty()) return results;

        Id caseId = requests[0].recordId;

        try {
            // Step 1: Get Case
            Case caseRecord = [
                SELECT Id, Document_Type__c
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];

            // Step 2: Get File
            ContentDocumentLink cdl = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseRecord.Id
                LIMIT 1
            ];

            ContentVersion file = [
                SELECT VersionData, FileType
                FROM ContentVersion
                WHERE ContentDocumentId = :cdl.ContentDocumentId
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];

            String base64File = EncodingUtil.base64Encode(file.VersionData);

            // Step 3: Auth
            OAuthService.AuthResponse auth = OAuthService.getAccessToken();

            // Step 4: Determine MIME
            String mimeType = getMimeType(file.FileType);

            // Step 5: Call Document AI
            HttpRequest req = new HttpRequest();
            req.setEndpoint(auth.instanceUrl +
                '/services/data/v64.0/ssot/document-processing/actions/extract-data');

            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + auth.accessToken);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);

            String configName = caseRecord.Document_Type__c == 'Aadhaar Card'
                ? 'Aadhaar_Card'
                : caseRecord.Document_Type__c;

            Map<String, Object> body = new Map<String, Object>{
                'idpConfigurationIdOrName' => configName,
                'files' => new List<Object>{
                    new Map<String, Object>{
                        'mimeType' => mimeType,
                        'data' => base64File
                    }
                }
            };

            req.setBody(JSON.serialize(body));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {

                Map<String, Object> parsed =
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                String encoded =
                    (String)((Map<String, Object>)
                    ((List<Object>)parsed.get('data'))[0]).get('data');

                String cleanJson = cleanResponse(encoded);

                update new Case(
                    Id = caseRecord.Id,
                    Document_AI_Response__c = cleanJson
                );

                results.add(cleanJson);

            } else {
                throw new AuraHandledException(res.getBody());
            }

        } catch (Exception e) {
    System.debug('===== REAL ERROR =====');
    System.debug('Message: ' + e.getMessage());
    System.debug('Stack: ' + e.getStackTraceString());

    throw e; // 🔴 VERY IMPORTANT (rethrow)
}

        return results;
    }

    // 🔧 Helper: MIME
    private static String getMimeType(String type) {
        if (type == 'PDF') return 'application/pdf';
        if (type == 'JPG' || type == 'JPEG') return 'image/jpeg';
        if (type == 'PNG') return 'image/png';
        throw new AuraHandledException('Unsupported file: ' + type);
    }

    // 🔧 Helper: Clean response
    private static String cleanResponse(String encodedJson) {

        String decoded = encodedJson
            .replace('&quot;', '"')
            .replace('&amp;', '&')
            .replace('&lt;', '<')
            .replace('&gt;', '>')
            .replace('&apos;', '\'');

        Map<String, Object> original =
            (Map<String, Object>) JSON.deserializeUntyped(decoded);

        Map<String, Object> simple = new Map<String, Object>();

        for (String key : original.keySet()) {
            Object val = original.get(key);

            if (val instanceof Map<String, Object> &&
                ((Map<String, Object>)val).containsKey('value')) {

                simple.put(key, ((Map<String, Object>)val).get('value'));
            }
        }

        return JSON.serialize(simple);
    }
}