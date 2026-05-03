/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : TwilioStatusCallbackHandler
* Author          : <YourName>
* Created Date    : May 01, 2026
* Description     : Handles message status updates from Twilio
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
@RestResource(urlMapping='/twilio/status/*')
global without sharing class TwilioStatusCallbackHandler {
    
    @HttpPost
    global static void handleStatusCallback() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Parse Twilio status callback parameters
            String requestBody = req.requestBody.toString();
            Map<String, String> params = parseFormData(requestBody);
            
            String messageSid = params.get('MessageSid');
            String messageStatus = params.get('MessageStatus');
            String toNumber = params.get('To'); // whatsapp:+1234567890
            String errorCode = params.get('ErrorCode');
            String errorMessage = params.get('ErrorMessage');
            
            // Clean phone number
            String phoneNumber = toNumber != null ? toNumber.replace('whatsapp:', '').replace('+', '') : '';
            
            System.debug('Status callback for MessageSid: ' + messageSid);
            System.debug('Status: ' + messageStatus);
            System.debug('Phone: ' + phoneNumber);
            
            // Update message status in Salesforce
            updateMessageStatus(messageSid, phoneNumber, messageStatus, errorCode, errorMessage);
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('OK');
            
        } catch (Exception e) {
            System.debug('Error in status callback: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error: ' + e.getMessage());
        }
    }
    
    private static Map<String, String> parseFormData(String formData) {
        Map<String, String> params = new Map<String, String>();
        
        if (String.isBlank(formData)) {
            return params;
        }
        
        for (String param : formData.split('&')) {
            List<String> keyValue = param.split('=', 2);
            if (keyValue.size() == 2) {
                params.put(
                    EncodingUtil.urlDecode(keyValue[0], 'UTF-8'),
                    EncodingUtil.urlDecode(keyValue[1], 'UTF-8')
                );
            }
        }
        
        return params;
    }
    
    private static void updateMessageStatus(String messageSid, String phone, String status, String errorCode, String errorMsg) {
        
        // Find the message by MessageSid or phone + recent timestamp
        List<WhatsApp_Message__c> messages = [
            SELECT Id, Status__c, Error_Message__c, Message_SID__c
            FROM WhatsApp_Message__c
            WHERE (Message_SID__c = :messageSid OR Phone__c = :phone)
            AND Direction__c = 'Outgoing'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!messages.isEmpty()) {
            WhatsApp_Message__c msg = messages[0];
            
            // Update status based on Twilio status
            if (status == 'sent') {
                msg.Status__c = 'Sent';
            } else if (status == 'delivered') {
                msg.Status__c = 'Delivered';
            } else if (status == 'read') {
                msg.Status__c = 'Read';
            } else if (status == 'failed' || status == 'undelivered') {
                msg.Status__c = 'Failed';
                msg.Error_Message__c = 'Error Code: ' + errorCode + ' - ' + errorMsg;
            }
            
            // Store MessageSid if not already stored
            if (String.isBlank(msg.Message_SID__c)) {
                msg.Message_SID__c = messageSid;
            }
            
            update msg;
            
            System.debug('Updated message status to: ' + msg.Status__c);
        } else {
            System.debug('No matching message found for MessageSid: ' + messageSid);
        }
    }
}