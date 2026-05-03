public class sfAuthService {


   public static String getAccessToken() {
   		 // Fetch config from Custom Metadata
		Default_Creds__mdt config = [
            SELECT Client_Id__c,
                   Client_Secret__c,
                   Token_Endpoint__c
            FROM Default_Creds__mdt
            WHERE DeveloperName = 'Default_Config'
            LIMIT 1
        ];
		HttpRequest req = new HttpRequest();
		req.setEndpoint(config.Token_Endpoint__c);
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

		String body = 'grant_type=client_credentials'
			+ '&client_id=' + EncodingUtil.urlEncode(config.Client_Id__c, 'UTF-8')
			+ '&client_secret=' + EncodingUtil.urlEncode(config.Client_Secret__c, 'UTF-8');

		req.setBody(body);

		Http http = new Http();
		HttpResponse res = http.send(req);

		
		Map<String, Object> result =
			(Map<String, Object>) JSON.deserializeUntyped(res.getBody());

		if (result.containsKey('access_token')) {
			String token = (String) result.get('access_token');
			
			return token;
		} else {
			
			return null;
		}
   }
}