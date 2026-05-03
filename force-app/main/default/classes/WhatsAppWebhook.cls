@RestResource(urlMapping='/whatsapp/webhook')
global class WhatsAppWebhook {

    @HttpGet
    global static void verifyWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String mode = req.params.get('hub.mode');
        String token = req.params.get('hub.verify_token');
        String challenge = req.params.get('hub.challenge');

        String VERIFY_TOKEN = 'myverify123';

        if (mode == 'subscribe' && token == VERIFY_TOKEN) {
            res.responseBody = Blob.valueOf(challenge);
            res.statusCode = 200;
        } else {
            res.statusCode = 403;
        }
    }

    @HttpPost
    global static void receiveMessageTwilio() {
        String agentApiName = 'New_Bank_Sathi_Service_Agent';
        RestRequest req = RestContext.request;
        String userMessage = req.params.get('Body');
        String fromNumber = req.params.get('From');
        String numMediaStr = req.params.get('NumMedia');

        if (String.isNotBlank(fromNumber)) {
            if (fromNumber.startsWith('whatsapp:')) {
                fromNumber = fromNumber.replace('whatsapp:', '');
            }
        }
        
        Integer mediaCount = (numMediaStr != null) 
            ? Integer.valueOf(numMediaStr) : 0;

        // =========================
        //  MEDIA FLOW
        // =========================
        if (mediaCount > 0) {

            String mediaUrl = req.params.get('MediaUrl0');
            String mediaType = req.params.get('MediaContentType0');
            String extension = '';

            if (mediaType != null && mediaType.contains('/')) {
                extension = mediaType.split('/')[1];
            }

            String filename = 'WhatsApp_' + Datetime.now().getTime() + '.' + extension;

            String sessionId = SessionManager.getActiveSession(fromNumber);
            Id sessionRecordId = SessionManager.getSessionRecordId(fromNumber);
            
            String caseId = null;

            if (sessionRecordId != null) {
                caseId = SessionManager.saveFileFromTwilio(
                    mediaUrl, mediaType, sessionRecordId, 
                    extension, fromNumber, filename
                );
            } 
            
            else {
                            System.debug('Session record not found!');
                        }
            

            
            SessionManager.DisputeData disputeData =
                SessionManager.getDisputeData(fromNumber);

            String transactionId = (disputeData != null) 
                ? disputeData.transactionId : null;

            Decimal amount = (disputeData != null) 
                ? disputeData.amount : null;

            
            if (transactionId == null || amount == null) {
                System.debug('Missing dispute data');

                sendReplyToTwilio(
                    'Your document has been received. Please provide the disputed amount.'
                );
                return;
            }
        }

        // =========================
        //  TEXT FLOW (no file)
        // =========================
        String sessionId = SessionManager.getActiveSession(fromNumber);
        System.debug('Existing sessionId from DB: ' + sessionId);

        if (!String.isBlank(userMessage)) {
            String trimmed = userMessage.trim();
            if (trimmed.length() == 6 && 
                trimmed.replaceAll('[0-9]', '') == '') {
                userMessage = 'OTP:' + trimmed;
            }
        }

       
        System.debug('userMessage: ' + userMessage +
             ', agentApiName: ' + agentApiName +
             ', sessionId: ' + sessionId +
             ', fromNumber: ' + fromNumber + ' Check param');
             
       AgentforceApexService.AgentResponse response= AgentforceApexService.callAgent(
                userMessage,
                agentApiName,
                sessionId,
                null, 
                fromNumber
            ); 
        
        
        String agentforceSessionId = (response.sessionId != null)
            ? response.sessionId
            : sessionId;

        
        if (agentforceSessionId != null) {
            SessionManager.upsertSession(fromNumber, agentforceSessionId, userMessage);
        } else {
            System.debug('WARNING: No sessionId received from Agentforce!');
        }

        sendReplyToTwilio(response.reply);
    }

    public static void sendReplyToTwilio(String message) {
        RestResponse res = RestContext.response;
        String twiml =
            '<?xml version="1.0" encoding="UTF-8"?>' +
            '<Response>' +
            '<Message>' + message + '</Message>' +
            '</Response>';
        res.addHeader('Content-Type', 'text/xml');
        res.responseBody = Blob.valueOf(twiml);
    }

    
}