public without sharing class DocumentAI {  
    
    public class Request {  
        @InvocableVariable(required=true)  
        public Id recordId;  
    }  
    
    @InvocableMethod(label='Document AI' description='Document AI')  
    public static List<String> requestDocumentAI(List<Request> requests) {  
        
        List<String> results = new List<String>();  
        if (requests == null || requests.isEmpty()) {
           
            return results;  
        }
        Id recordId = requests[0].recordId;  
       
        Map<String, Object> finalResponse = new Map<String, Object>();  
        List<Case> casesToUpdate = new List<Case>();  
        try {  
            // Query the Case record
            Case caseRecord = [
                SELECT Id, Document_Type__c
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            if (caseRecord == null) {  
                throw new AuraHandledException('Case record not found.');  
            }  
            String accessToken = sfAuthService.getAccessToken();  
             String typeOfDoc = caseRecord.Document_Type__c;  
            // Get ContentDocumentLink associated with the Case
            ContentDocumentLink cdl = [  
                SELECT ContentDocumentId  
                FROM ContentDocumentLink  
                WHERE LinkedEntityId = :caseRecord.Id  
                LIMIT 1  
            ];  
            
            ContentVersion fileToProcess = [  
                SELECT VersionData, FileType  
                FROM ContentVersion  
                WHERE ContentDocumentId = :cdl.ContentDocumentId  
                ORDER BY VersionNumber DESC  
                LIMIT 1  
            ];  
            
            String base64File =  
                EncodingUtil.base64Encode(fileToProcess.VersionData);  
            HttpRequest httpReq = new HttpRequest();  
            String endpoint = System.Url.getOrgDomainUrl().toExternalForm() +  
                '/services/data/v64.0/ssot/document-processing/actions/extract-data';
            System.debug('Endpoint >>> ' + endpoint);
            httpReq.setEndpoint(endpoint);  
            httpReq.setMethod('POST');  
            httpReq.setHeader('Authorization', 'Bearer ' + accessToken);  
            httpReq.setHeader('Content-Type', 'application/json;charset=UTF-8');  
            String documentAiName = (typeOfDoc == 'Hotel Bills ') ? 'Hotel_Bills ': typeOfDoc;  
            System.debug('Document AI Name >>> ' + documentAiName);
            String mimeType =  
                fileToProcess.FileType == 'PDF' ? 'application/pdf' :  
                (fileToProcess.FileType == 'JPG' || fileToProcess.FileType == 'JPEG') ? 'image/jpeg' :  
                fileToProcess.FileType == 'PNG' ? 'image/png' :  
                null;  
            System.debug('Mime Type >>> ' + mimeType);
            if (mimeType == null) {  
                throw new AuraHandledException('Unsupported file type: ' + fileToProcess.FileType);  
            }  
            String requestBody = JSON.serialize(new Map<String, Object>{  
                'idpConfigurationIdOrName' => documentAiName,  
                'files' => new List<Object>{  
                    new Map<String, Object>{  
                        'mimeType' => mimeType,  
                        'data' => base64File  
                    }  
                }  
            });
            
            httpReq.setBody(requestBody);  
            Http http = new Http();  
            HttpResponse res = http.send(httpReq);  
            if (res.getStatusCode() >= 200 && res.getStatusCode() <= 202) {  
                Map<String, Object> outerJson =  
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());  
                
                List<Object> dataList = (List<Object>) outerJson.get('data');
                
                String encodedJson =  
                    (String)((Map<String, Object>)  
                             ((List<Object>)outerJson.get('data'))[0]).get('data');  
                
                String decodedJson = encodedJson  
                    .replace('&quot;', '"')  
                    .replace('&amp;', '&')  
                    .replace('&lt;', '<')  
                    .replace('&gt;', '>')  
                    .replace('&apos;', '\'');  
                
                String simplifiedJson = simplifyJson(decodedJson);  
                
                casesToUpdate.add(new Case(  
                    Id = caseRecord.Id,  
                    Document_AI_Response__c = simplifiedJson  
                ));  
                finalResponse.put(  
                    typeOfDoc,  
                    JSON.deserializeUntyped(simplifiedJson)  
                );  
            }  
        } catch (Exception e) {  
            System.debug('ERROR >>> ' + e.getMessage());
            finalResponse.put(String.valueOf(recordId), 'ERROR=' + e.getMessage());  
        }  
        if (!casesToUpdate.isEmpty()) {  
            System.debug('Updating Cases >>> ' + casesToUpdate);
            update casesToUpdate;  
        }  
        results.add(JSON.serialize(finalResponse));  
        
        return results;  
    }
    
    public static String simplifyJson(String jsonInput) {  
        
        Map<String, Object> originalMap =  
            (Map<String, Object>) JSON.deserializeUntyped(jsonInput);  
        
        Map<String, Object> simpleMap = new Map<String, Object>();  
        for (String key : originalMap.keySet()) {  
            Object val = originalMap.get(key);  
            if (val instanceof Map<String, Object> &&  
                ((Map<String, Object>)val).containsKey('value')) {  
                simpleMap.put(key, ((Map<String, Object>)val).get('value'));  
            }  
        }  
        
        return JSON.serialize(simpleMap);  
    }
    
    // Changed from private to public
    public static String getStringValue(Map<String, Object> parentMap, String key) {
        if (parentMap.containsKey(key)) {
            Object obj = parentMap.get(key);
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> nestedMap = (Map<String, Object>) obj;
                return (String) nestedMap.get('value');
            }
            return (String) obj;
        }
        return null;
    }

    // Changed from private to public
    public static Decimal getDecimalValue(Map<String, Object> parentMap, String key) {
        if (parentMap.containsKey(key)) {
            Object obj = parentMap.get(key);
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> nestedMap = (Map<String, Object>) obj;
                Object value = nestedMap.get('value');
                if (value != null) {
                    return Decimal.valueOf(String.valueOf(value));
                }
            } else if (obj != null) {
                return Decimal.valueOf(String.valueOf(obj));
            }
        }
        return null;
    }
}