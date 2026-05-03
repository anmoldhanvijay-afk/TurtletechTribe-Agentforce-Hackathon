/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : TwilioService
* Author          : <YourName>
* Created Date    : May 01, 2026
* Description     : Service class for sending WhatsApp messages via Twilio
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
public class TwilioService {
    
    public static void sendWhatsAppMessage(String toPhone, String messageBody) {
        
        // Get Twilio configuration
        Twilio_Configuration__mdt config = [
            SELECT Account_SID__c, Auth_Token__c, WhatsApp_Number__c
            FROM Twilio_Configuration__mdt 
            WHERE DeveloperName = 'Production' 
            LIMIT 1
        ];
        
        String endpoint = 'https://api.twilio.com/2010-04-01/Accounts/' + 
                         config.Account_SID__c + '/Messages.json';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        
        // Add authentication
        Blob headerValue = Blob.valueOf(config.Account_SID__c + ':' + config.Auth_Token__c);
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authHeader);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        // Build request body
        String body = 'From=' + EncodingUtil.urlEncode(config.WhatsApp_Number__c, 'UTF-8') +
                     '&To=' + EncodingUtil.urlEncode('whatsapp:+' + toPhone, 'UTF-8') +
                     '&Body=' + EncodingUtil.urlEncode(messageBody, 'UTF-8');
        
        req.setBody(body);
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('Twilio response: ' + res.getStatusCode());
        System.debug('Twilio body: ' + res.getBody());
        
        // Log outgoing message
        if (res.getStatusCode() == 201) {
            logOutgoingMessage(toPhone, messageBody);
        }
    }
    
    private static void logOutgoingMessage(String phone, String message) {
        
        List<WhatsApp_Session__c> sessions = [
            SELECT Id 
            FROM WhatsApp_Session__c 
            WHERE Phone__c = :phone 
            AND Is_Active__c = true 
            LIMIT 1
        ];
        
        if (!sessions.isEmpty()) {
            WhatsApp_Message__c msg = new WhatsApp_Message__c();
            msg.Session__c = sessions[0].Id;
            msg.Phone__c = phone;
            msg.Message_Body__c = message;
            msg.Direction__c = 'Outgoing';
            msg.Timestamp__c = System.now();
            insert msg;
        }
    }
}