public class RunDocumentAIFromCase {

    public static void run(String orgDomain, Id caseId) {

        try {
            //  GET ACCESS TOKEN
            String clientId = '3MVG91oqviqJKoEFUzlFVLDhS81u7nQKcYK26y0B6B2hiBUhBLCyb0LZTeQ0KwbZOTixNTBtM9RE5dykOs3Vw';
            String clientSecret = '641263D0F4CFDF53B812A7185F9CE5D9A86955964B24D5A8E853E19AB1BF4723';

            HttpRequest authReq = new HttpRequest();
            authReq.setEndpoint(orgDomain + '/services/oauth2/token');
            authReq.setMethod('POST');
            authReq.setHeader('Content-Type','application/x-www-form-urlencoded');
            authReq.setBody(
                'grant_type=client_credentials' +
                '&client_id=' + clientId +
                '&client_secret=' + clientSecret
            );

            Http http = new Http();
            HttpResponse authRes = http.send(authReq);

            System.debug('Auth Response: ' + authRes.getBody());

            if (authRes.getStatusCode() != 200) {
                //throw new Exception('Auth Failed: ' + authRes.getBody());
            }

            String accessToken =
                (String)((Map<String,Object>)JSON.deserializeUntyped(authRes.getBody()))
                .get('access_token');

            //  GET FILE FROM CASE
            ContentDocumentLink cdl = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseId
                LIMIT 1
            ];

            ContentVersion cv = [
                SELECT Id
                FROM ContentVersion
                WHERE ContentDocumentId = :cdl.ContentDocumentId
                ORDER BY VersionNumber DESC
                LIMIT 1
            ];

            String fileId = cv.Id;
            System.debug('FileId: ' + fileId);

            // CALL DOCUMENT AI
            HttpRequest req = new HttpRequest();
            req.setEndpoint(orgDomain +
                '/services/data/v63.0/ssot/document-processing/actions/extract-data');

            req.setMethod('POST');
            req.setHeader('Authorization','Bearer ' + accessToken);
            req.setHeader('Content-Type','application/json');
            req.setTimeout(120000);

            //  CHANGE THIS CONFIG NAME IF NEEDED
            String configName = 'Hotel_Bills';

            Map<String,Object> body = new Map<String,Object>{
                'idpConfigurationIdOrName' => configName,
                'files' => new List<Object>{
                    new Map<String,Object>{ 'fileId' => fileId }
                }
            };

            req.setBody(JSON.serialize(body));

            HttpResponse res = http.send(req);

            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                System.debug(' SUCCESS');
            } else {
                //throw new Exception(' API Error: ' + res.getBody());
            }

        } catch (Exception e) {
            System.debug(' ERROR: ' + e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
}