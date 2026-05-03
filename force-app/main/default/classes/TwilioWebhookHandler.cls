/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : TwilioWebhookHandler
* Author          : <YourName>
* Created Date    : May 01, 2026
* Description     : Handles incoming WhatsApp messages from Twilio webhook
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/
@RestResource(urlMapping='/twilio/whatsapp/*')
global without sharing class TwilioWebhookHandler {
    
    @HttpPost
    global static void handleIncoming() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Parse Twilio webhook parameters
            String requestBody = req.requestBody.toString();
            Map<String, String> params = parseFormData(requestBody);
            
            String messageSid = params.get('MessageSid');
            String fromNumber = params.get('From'); // whatsapp:+1234567890
            String toNumber = params.get('To');
            String body = params.get('Body');
            String numMedia = params.get('NumMedia');
            
            // Clean phone number
            String phoneNumber = fromNumber != null ? fromNumber.replace('whatsapp:', '').replace('+', '') : '';
            
            System.debug('Incoming WhatsApp message from: ' + phoneNumber);
            System.debug('Message body: ' + body);
            System.debug('Number of media: ' + numMedia);
            
            // Check for media attachments
            List<MediaAttachment> mediaList = new List<MediaAttachment>();
            if (String.isNotBlank(numMedia) && Integer.valueOf(numMedia) > 0) {
                for (Integer i = 0; i < Integer.valueOf(numMedia); i++) {
                    MediaAttachment media = new MediaAttachment();
                    media.url = params.get('MediaUrl' + i);
                    media.contentType = params.get('MediaContentType' + i);
                    mediaList.add(media);
                }
            }
            
            // Process the message
            String response = processWhatsAppMessage(phoneNumber, body, mediaList);
            
            // Send response back to user
            sendWhatsAppMessage(phoneNumber, response);
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('<?xml version="1.0" encoding="UTF-8"?><Response></Response>');
            
        } catch (Exception e) {
            System.debug('Error in webhook: ' + e.getMessage());
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
    
    private static String processWhatsAppMessage(String phone, String message, List<MediaAttachment> media) {
        
        // Create or get session
        WhatsApp_Session__c session = getOrCreateSession(phone);
        
        // Log the message
        logMessage(session.Id, phone, message, 'Incoming', media);
        
        // Check if has media
        if (!media.isEmpty()) {
            return handleMediaMessage(phone, message, media, session);
        } else {
            return handleTextMessage(phone, message, session);
        }
    }
    
    private static String handleTextMessage(String phone, String message, WhatsApp_Session__c session) {
        // For now, return a simple response
        // Later, this will call Agentforce API
        return 'Thank you for your message: "' + message + '". Our team will respond shortly.';
    }
    
    private static String handleMediaMessage(String phone, String message, List<MediaAttachment> media, WhatsApp_Session__c session) {
        
        String response = 'Thank you for sharing ';
        
        for (MediaAttachment m : media) {
            // Download and store media
            String contentDocId = downloadAndStoreMedia(m.url, m.contentType, phone);
            
            if (String.isNotBlank(contentDocId)) {
                response += 'the document. ';
            }
        }
        
        response += 'We have received your attachment and will review it shortly.';
        return response;
    }
    
    private static WhatsApp_Session__c getOrCreateSession(String phone) {
        
        List<WhatsApp_Session__c> sessions = [
            SELECT Id, Session_ID__c, Phone__c, Is_Active__c, Is_Verified__c
            FROM WhatsApp_Session__c
            WHERE Phone__c = :phone
            AND Is_Active__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!sessions.isEmpty()) {
            return sessions[0];
        }
        
        // Create new session
        WhatsApp_Session__c newSession = new WhatsApp_Session__c();
        newSession.Phone__c = phone;
        newSession.Session_ID__c = 'WA_' + phone + '_' + System.now().getTime();
        newSession.Is_Active__c = true;
        newSession.Is_Verified__c = false;
        newSession.Start_Time__c = System.now();
        newSession.Session_Status__c = 'Active';
        insert newSession;
        
        return newSession;
    }
    
    private static void logMessage(Id sessionId, String phone, String message, String direction, List<MediaAttachment> media) {
        
        WhatsApp_Message__c msg = new WhatsApp_Message__c();
        msg.Session__c = sessionId;
        msg.Phone__c = phone;
        msg.Message_Body__c = message;
        msg.Direction__c = direction;
        msg.Timestamp__c = System.now();
        msg.Has_Media__c = !media.isEmpty();
        msg.Media_Count__c = media.size();
        msg.Status__c = 'Delivered';
        
        insert msg;
    }
    
    private static String downloadAndStoreMedia(String mediaUrl, String contentType, String phone) {
        
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(mediaUrl);
            req.setMethod('GET');
            
            // Get Twilio credentials
            List<Twilio_Configuration__mdt> configs = [
                SELECT Account_SID__c, Auth_Token__c 
                FROM Twilio_Configuration__mdt 
                WHERE DeveloperName = 'Production' 
                LIMIT 1
            ];
            
            if (configs.isEmpty()) {
                System.debug('Twilio configuration not found');
                return null;
            }
            
            Twilio_Configuration__mdt config = configs[0];
            
            // Add Twilio authentication
            Blob headerValue = Blob.valueOf(config.Account_SID__c + ':' + config.Auth_Token__c);
            String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authHeader);
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                
                // Create ContentVersion
                ContentVersion cv = new ContentVersion();
                cv.Title = 'WhatsApp_' + phone + '_' + System.now().format('yyyyMMddHHmmss');
                cv.PathOnClient = cv.Title + getFileExtension(contentType);
                cv.VersionData = res.getBodyAsBlob();
                cv.IsMajorVersion = true;
                
                // Link to Account if exists
                Id accountId = getAccountIdByPhone(phone);
                if (accountId != null) {
                    cv.FirstPublishLocationId = accountId;
                }
                
                insert cv;
                
                // Get ContentDocumentId
                cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                return cv.ContentDocumentId;
            }
            
        } catch (Exception e) {
            System.debug('Error downloading media: ' + e.getMessage());
        }
        
        return null;
    }
    
    private static Id getAccountIdByPhone(String phone) {
        String cleanPhone = phone.replaceAll('[^0-9]', '');
        if (cleanPhone.length() > 10) {
            cleanPhone = cleanPhone.substring(cleanPhone.length() - 10);
        }
        
        List<Account> accounts = [
            SELECT Id 
            FROM Account 
            WHERE Phone LIKE :('%' + cleanPhone) 
               OR PersonMobilePhone LIKE :('%' + cleanPhone)
            LIMIT 1
        ];
        
        return !accounts.isEmpty() ? accounts[0].Id : null;
    }
    
    private static String getFileExtension(String contentType) {
        if (contentType == null) return '.file';
        
        if (contentType.contains('jpeg') || contentType.contains('jpg')) return '.jpg';
        if (contentType.contains('png')) return '.png';
        if (contentType.contains('pdf')) return '.pdf';
        if (contentType.contains('gif')) return '.gif';
        if (contentType.contains('mp4')) return '.mp4';
        
        return '.file';
    }
    
    private static void sendWhatsAppMessage(String toPhone, String messageBody) {
        
        // Get Twilio configuration
        List<Twilio_Configuration__mdt> configs = [
            SELECT Account_SID__c, Auth_Token__c, WhatsApp_Number__c
            FROM Twilio_Configuration__mdt 
            WHERE DeveloperName = 'Production' 
            LIMIT 1
        ];
        
        if (configs.isEmpty()) {
            System.debug('Twilio configuration not found');
            return;
        }
        
        Twilio_Configuration__mdt config = configs[0];
        
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
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('Twilio response: ' + res.getStatusCode());
            System.debug('Twilio body: ' + res.getBody());
            
            // Log outgoing message
            if (res.getStatusCode() == 201) {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String messageSid = (String) responseData.get('sid');
            logOutgoingMessage(toPhone, messageBody, messageSid);
        }
    } catch (Exception e) {
        System.debug('Error sending message: ' + e.getMessage());
    }
}
    
    private static void logOutgoingMessage(String phone, String message, String messageSid) {
    
    List<WhatsApp_Session__c> sessions = [
        SELECT Id 
        FROM WhatsApp_Session__c 
        WHERE Phone__c = :phone 
        AND Is_Active__c = true 
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];
    
    if (!sessions.isEmpty()) {
        WhatsApp_Message__c msg = new WhatsApp_Message__c();
        msg.Session__c = sessions[0].Id;
        msg.Phone__c = phone;
        msg.Message_Body__c = message;
        msg.Direction__c = 'Outgoing';
        msg.Timestamp__c = System.now();
        msg.Status__c = 'Queued';
        msg.Message_SID__c = messageSid;
        insert msg;
    }
}
    
    // Inner class for media handling
    private class MediaAttachment {
        String url;
        String contentType;
    }
}