public class OAuthService {

    public class AuthResponse {
        public String accessToken;
        public String instanceUrl;
    }

    public static AuthResponse getAccessToken() {

        String clientId = '3MVG91oqviqJKoEFUzlFVLDhS81u7nQKcYK26y0B6B2hiBUhBLCyb0LZTeQ0KwbZOTixNTBtM9RE5dykOs3Vw';
        String clientSecret = '641263D0F4CFDF53B812A7185F9CE5D9A86955964B24D5A8E853E19AB1BF4723';
        String username = 'epic.a4e543bfd7d1@orgfarm.salesforce.com';
        String password = 'orgfarm1234'; // + token if needed

        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://login.salesforce.com/services/oauth2/token'); // FIXED
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body = 'grant_type=password'
            + '&client_id=' + EncodingUtil.urlEncode(clientId, 'UTF-8')
            + '&client_secret=' + EncodingUtil.urlEncode(clientSecret, 'UTF-8')
            + '&username=' + EncodingUtil.urlEncode(username, 'UTF-8')
            + '&password=' + EncodingUtil.urlEncode(password, 'UTF-8');

        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> result =
                (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            AuthResponse auth = new AuthResponse();
            auth.accessToken = (String) result.get('access_token');
            auth.instanceUrl = (String) result.get('instance_url');

            return auth;
        } else {
            throw new AuraHandledException('OAuth failed: ' + res.getBody());
        }
    }
}