/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : SessionManager
 * Author          : Anmol Dhanvijay
 * Created Date    : Apr 15, 2026
 * Last Modified By: 
 * Last Modified On: Apr 15, 2026
 * Description     : To handle agent session for whatsapp integration as we cant work with messaging sesion
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 15, 2026  │ Anmol Dhanvijay   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class SessionManager {

    //  1. Get active session (NO DML)
    public static String getActiveSession(String phoneNumber) {

        List<WhatsApp_Session__c> sessions = [
            SELECT Id, Session_Id__c
            FROM WhatsApp_Session__c
            WHERE Phone__c = :phoneNumber
            AND Is_Active__c = true
            LIMIT 1
        ];

        if (!sessions.isEmpty()) {
            return sessions[0].Session_Id__c;
        }

        return null;
    }

    //  2. Generate new session id
    public static String generateSessionId() {
        return String.valueOf(Crypto.getRandomLong()) + '_' + DateTime.now().getTime();
    }

    //  3. Update or create session (DML AFTER callout)
    public static void upsertSession(String phoneNumber, String sessionId, String userMessage) {

        List<WhatsApp_Session__c> sessions = [
            SELECT Id, Session_Id__c, Message_Count__c
            FROM WhatsApp_Session__c
            WHERE Phone__c = :phoneNumber
            AND Is_Active__c = true
            LIMIT 1
        ];

       
        String msg = userMessage != null ? userMessage.toLowerCase() : '';

        if (msg.contains('end') || msg.contains('stop') || msg.contains('unsubscribe')) {

            if (!sessions.isEmpty()) {
                WhatsApp_Session__c s = sessions[0];
                s.Is_Active__c = false;
                s.Last_Used__c = System.now();
                update s;
            }

            return;
        }

        
        if (!sessions.isEmpty()) {

            WhatsApp_Session__c s = sessions[0];
            s.Last_Used__c = System.now();
            s.Message_Count__c = (s.Message_Count__c == null ? 1 : s.Message_Count__c + 1);

            update s;
        }
        else {
           
            insert new WhatsApp_Session__c(
                Phone__c = phoneNumber,
                Session_Id__c = sessionId,
                Is_Active__c = true,
                Last_Used__c = System.now(),
                Message_Count__c = 1
            );
        }
    }

    public static String saveFileFromTwilio(String mediaUrl, String mediaType, Id recordId, String extension, string fromNumber, string fileName) {

        System.debug('mediaUrl  '+mediaUrl+ 'mediaType ' +mediaType+ 'recordId ' +recordId);
        String caseId = null ;
        Account accId = [
            SELECT Id from Account
            WHERE Phone = :fromNumber
            LIMIT 1
        ];
       // This is main one for testing the document only
        WhatsApp_Config__mdt config = [
            SELECT Id, Access_Token__c 
            FROM WhatsApp_Config__mdt where DeveloperName = 'Access_Token'
            LIMIT 1
        ]; 
        try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(mediaUrl);
        req.setMethod('GET');

       
        String auth = 'Basic ' + EncodingUtil.base64Encode(
            Blob.valueOf(config.Access_Token__c)
        );

        req.setHeader('Authorization', auth);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('res.getStatusCode()  ' +res.getStatusCode());

        if (res.getStatusCode() == 302 || res.getStatusCode() == 307) {

            String redirectUrl = res.getHeader('Location');
            System.debug('Redirect URL: ' + redirectUrl);

            HttpRequest redirectReq = new HttpRequest();
            redirectReq.setEndpoint(redirectUrl);
            redirectReq.setMethod('GET');
            redirectReq.setHeader('Authorization', auth);

            res = http.send(redirectReq);
        }

        if (res.getStatusCode() == 200) {

            Blob fileBody = res.getBodyAsBlob();

            //  Upload file
            ContentVersion cv = new ContentVersion();
            String finalFileName = fileName;            
            // Ensure extension exists
            if (!finalFileName.contains('.')) {
                finalFileName += '.' + extension;
            }            
            cv.Title = finalFileName;
            cv.PathOnClient = finalFileName;
            cv.VersionData = fileBody;            
            insert cv;

            //  Get ContentDocumentId (IMPORTANT)
            Id contentDocId = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :cv.Id
            ].ContentDocumentId;

            //  Create Case
            Case cs = new Case();
            cs.Subject = 'Dispute for customer';
            cs.Description = 'Attachment received via WhatsApp';
            cs.Origin = 'WhatsApp';
            cs.AccountId = accId.Id;
            cs.SuppliedPhone = '+918527650722';
            insert cs;
            caseId = cs.Id;

            
            List<ContentDocumentLink> links = new List<ContentDocumentLink>();

            // Link to Session (your recordId)
            links.add(new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = recordId,
                ShareType = 'V'
            ));

            //  Link to Case
            links.add(new ContentDocumentLink(
                ContentDocumentId = contentDocId,
                LinkedEntityId = cs.Id,
                ShareType = 'V'
            ));

            
            insert links;
           
        } else {
            System.debug('Failed to download file: ' + res.getStatus());
        }

        } catch (Exception e) {
            System.debug('File save error: ' + e.getMessage());
        }
        return caseId;
    }

    //this is used to get session record for notes and attachment
    public static Id getSessionRecordId(String phoneNumber) {

        List<WhatsApp_Session__c> sessions = [
            SELECT Id
            FROM WhatsApp_Session__c
            WHERE Phone__c = :phoneNumber
            AND Is_Active__c = true
            LIMIT 1
        ];

        if (!sessions.isEmpty()) {
            return sessions[0].Id;
        }

        return null;
    }
    public static String getPhoneBySession(String sessionId) {

            if (String.isBlank(sessionId)) return null;

            List<WhatsApp_Session__c> sessions = [
                SELECT Phone__c
                FROM WhatsApp_Session__c
                WHERE Session_Id__c = :sessionId
                
                LIMIT 1
            ];

            if (!sessions.isEmpty()) {
               
                return sessions[0].Phone__c;
            }

            System.debug('No session record found for sessionId: ' + sessionId);
            return null;
    }
    public static String getLatestPhone() {

    List<WhatsApp_Session__c> sessions = [
        SELECT Phone__c
        FROM WhatsApp_Session__c
        WHERE Phone__c != null and is_verified__c = false
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    return sessions.isEmpty() ? null : sessions[0].Phone__c;
    }

        public class DisputeData {
            public String transactionId;
            public Decimal amount;

            public DisputeData(String transactionId, Decimal amount) {
                this.transactionId = transactionId;
                this.amount = amount;
            }
        }

       
        private static Map<String, DisputeData> disputeStore = new Map<String, DisputeData>();

        public static void storeDisputeData(String fromNumber, String transactionId, Decimal amount) {
            disputeStore.put(fromNumber, new DisputeData(transactionId, amount));
        }

        public static DisputeData getDisputeData(String fromNumber) {
            return disputeStore.get(fromNumber);
        }

        public static void clearDisputeData(String fromNumber) {
            disputeStore.remove(fromNumber);
        }
}