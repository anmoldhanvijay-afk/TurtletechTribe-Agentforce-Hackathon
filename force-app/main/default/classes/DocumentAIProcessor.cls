public without sharing class DocumentAIProcessor {
    
    // Input wrapper
    public class Request {
        @InvocableVariable(required=true label='Case ID' description='The ID of the Case record containing the document to process')
        public String caseId;
    }
    
    // Output wrapper with all the fields
    public class Response {
        @InvocableVariable(label='Success' description='Indicates if the document processing was successful')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Error Message' description='Error message if processing failed')
        public String errorMessage;
        
        @InvocableVariable(label='GST Registration Number' description='GST Registration Number of the hotel')
        public String gstRegNo;
        
        @InvocableVariable(label='PAN Number Hotel' description='PAN Number of the hotel')
        public String panNoHotel;
        
        @InvocableVariable(label='User ID' description='User ID from the document')
        public String userId;
        
        @InvocableVariable(label='CIN Number' description='Corporate Identification Number')
        public String cinNo;
        
        @InvocableVariable(label='Invoice Number' description='Invoice number from the document')
        public String invoiceNo;
        
        @InvocableVariable(label='Invoice Date' description='Date of the invoice')
        public String invoiceDate;
        
        @InvocableVariable(label='Trip ID' description='Trip identification number')
        public String tripId;
        
        @InvocableVariable(label='Travel Request Number' description='Travel request or booking reference number')
        public String travelRequestNo;
        
        @InvocableVariable(label='Cost Centre' description='Cost centre code for accounting')
        public String costCentre;
        
        @InvocableVariable(label='Hotel Name' description='Name of the hotel')
        public String hotelName;
        
        @InvocableVariable(label='GST Registration Number Client' description='GST Registration Number of the client')
        public String gstRegNoClient;
        
        @InvocableVariable(label='PAN Number Client' description='PAN Number of the client')
        public String panNoClient;
        
        @InvocableVariable(label='Place of Supply' description='Place of supply for GST purposes')
        public String placeOfSupply;
        
        @InvocableVariable(label='HSN Code' description='HSN/SAC code for the service')
        public String hsnCode;
        
        @InvocableVariable(label='Tax Payable on Reverse Charge' description='Indicates if reverse charge is applicable')
        public String taxPayableOnReverseCharge;
        
        @InvocableVariable(label='IRN Number' description='Invoice Reference Number for e-invoicing')
        public String irnNo;
        
        @InvocableVariable(label='Total Amount in Words' description='Total invoice amount in words')
        public String totalAmountInWords;
        
        @InvocableVariable(label='Bank Info' description='Bank account details for payment')
        public String bankInfo;
        
        @InvocableVariable(label='Notes' description='Additional notes or terms from the invoice')
        public String notes;
        
        // Product Details - First Product (most common use case)
        @InvocableVariable(label='Product Type' description='Type of product/service (e.g., Hotel-Int)')
        public String productType;
        
        @InvocableVariable(label='Guest Name' description='Name of the guest')
        public String guestName;
        
        @InvocableVariable(label='Gender' description='Gender or guest type (e.g., ADULT)')
        public String gender;
        
        @InvocableVariable(label='Product Hotel Name' description='Hotel name from product details')
        public String productHotelName;
        
        @InvocableVariable(label='Confirmation Number' description='Booking confirmation number')
        public String confNo;
        
        @InvocableVariable(label='Check-in Date' description='Check-in date for the hotel stay')
        public String checkInDate;
        
        @InvocableVariable(label='Check-out Date' description='Check-out date for the hotel stay')
        public String checkOutDate;
        
        // Fare Details - First Fare (most common use case)
        @InvocableVariable(label='Document Number' description='Document or booking reference number')
        public String documentNumber;
        
        @InvocableVariable(label='Fare' description='Base fare amount')
        public Decimal fare;
        
        @InvocableVariable(label='Tax' description='Tax amount')
        public Decimal tax;
        
        @InvocableVariable(label='SSR' description='Special Service Request charges')
        public Decimal ssr;
        
        @InvocableVariable(label='Discount' description='Discount amount applied')
        public Decimal discount;
        
        @InvocableVariable(label='Surcharge' description='Additional surcharge amount')
        public Decimal surcharge;
        
        @InvocableVariable(label='Management Fee' description='Management fee charged')
        public Decimal managementFee;
        
        @InvocableVariable(label='Service Fee' description='Service fee charged')
        public Decimal serviceFee;
        
        @InvocableVariable(label='Total Fare' description='Total fare including all charges')
        public Decimal totalFare;
        
        // GST Details - First GST (most common use case)
        @InvocableVariable(label='GST Description' description='Description of the GST line item')
        public String gstDescription;
        
        @InvocableVariable(label='HSN/SAC' description='HSN/SAC code for GST calculation')
        public String hsnSac;
        
        @InvocableVariable(label='Taxable Value' description='Taxable value for GST calculation')
        public Decimal taxableValue;
        
        @InvocableVariable(label='CGST Percent' description='Central GST percentage')
        public Decimal cgstPercent;
        
        @InvocableVariable(label='CGST Amount' description='Central GST amount')
        public Decimal cgstAmount;
        
        @InvocableVariable(label='SGST/UGST Percent' description='State/Union Territory GST percentage')
        public Decimal sgstUgstPercent;
        
        @InvocableVariable(label='SGST/UGST Amount' description='State/Union Territory GST amount')
        public Decimal sgstUgstAmount;
        
        @InvocableVariable(label='IGST Percent' description='Integrated GST percentage')
        public Decimal igstPercent;
        
        @InvocableVariable(label='IGST Amount' description='Integrated GST amount')
        public Decimal igstAmount;
        
        @InvocableVariable(label='Total GST Amount' description='Total GST amount (CGST + SGST + IGST)')
        public Decimal totalGstAmount;
        
        // All details as JSON strings (for complex scenarios)
        @InvocableVariable(label='All Product Details JSON' description='Complete product details in JSON format for multiple products')
        public String allProductDetailsJson;
        
        @InvocableVariable(label='All Fare Details JSON' description='Complete fare details in JSON format for multiple fare lines')
        public String allFareDetailsJson;
        
        @InvocableVariable(label='All GST Details JSON' description='Complete GST details in JSON format for multiple GST lines')
        public String allGstDetailsJson;
    }
    
    @InvocableMethod(label='Process Document AI' description='Processes document and returns extracted data')
    public static List<Response> processDocument(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        if (requests == null || requests.isEmpty()) {
            Response errorResponse = new Response();
            errorResponse.isSuccess = false;
            errorResponse.errorMessage = 'No request provided';
            responses.add(errorResponse);
            return responses;
        }
        
        Request req = requests[0];
        Response response = new Response();
        
        try {
            
            // Query the Case record
            Case caseRecord = [
                SELECT Id, Document_Type__c, Document_AI_Response__c
                FROM Case
                WHERE Id = :req.caseId
                LIMIT 1
            ];
            
            if (caseRecord == null) {
                throw new AuraHandledException('Case record not found.');
            }
            
            String typeOfDoc = caseRecord.Document_Type__c;
            
            // Get ContentDocumentLink associated with the Case
            List<ContentDocumentLink> cdlList = [
                SELECT ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :caseRecord.Id
                LIMIT 1
            ];
            
            if (cdlList.isEmpty()) {
                throw new AuraHandledException('No document found attached to this Case.');
            }
            
            ContentVersion fileToProcess = [
                SELECT VersionData, FileType, Title, ContentDocumentId
                FROM ContentVersion
                WHERE ContentDocumentId = :cdlList[0].ContentDocumentId
                AND IsLatest = true
                LIMIT 1
            ];
            
            String base64File = EncodingUtil.base64Encode(fileToProcess.VersionData);
            
            
            String accessToken = sfAuthService.getAccessToken();
            System.debug('Access Token Retrieved');
            
            HttpRequest httpReq = new HttpRequest();
            
           
            String orgDomain = System.Url.getOrgDomainUrl().toExternalForm();
            
           
            if (orgDomain.endsWith('/')) {
                orgDomain = orgDomain.substring(0, orgDomain.length() - 1);
            }
            
            String endpoint = orgDomain + '/services/data/v64.0/ssot/document-processing/actions/extract-data';
            
            System.debug('Endpoint: ' + endpoint);
            
            httpReq.setEndpoint(endpoint);
            httpReq.setMethod('POST');
            httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setTimeout(120000); // 2 minutes
            
            
            String mimeType;
            if (fileToProcess.FileType == 'PDF') {
                mimeType = 'application/pdf';
            } else if (fileToProcess.FileType == 'JPG' || fileToProcess.FileType == 'JPEG') {
                mimeType = 'image/jpeg';
            } else if (fileToProcess.FileType == 'PNG') {
                mimeType = 'image/png';
            } else if (fileToProcess.FileType == 'TIFF' || fileToProcess.FileType == 'TIF') {
                mimeType = 'image/tiff';
            } else {
                throw new AuraHandledException('Unsupported file type: ' + fileToProcess.FileType);
            }
            
           
String documentAiName;

if (typeOfDoc != null && typeOfDoc.trim().length() > 0) {
    String trimmedType = typeOfDoc.trim();
    
    
    if (trimmedType.equalsIgnoreCase('Hotel Bill') ||      // Your new field value
        trimmedType.equalsIgnoreCase('Hotel Bills') || 
        trimmedType.equalsIgnoreCase('Hotel_Bills') ||     // Old field value
        trimmedType.equalsIgnoreCase('Hotel_Bill') ||
        trimmedType.equalsIgnoreCase('HotelBills') ||
        trimmedType.equalsIgnoreCase('Hotel bills') ||
        trimmedType == 'Hotel Bills ' ||                   // with trailing space
        trimmedType == 'Hotesl_Bills ') {                   // with trailing space
        documentAiName = 'Hotel_bills';  
    } 
    
    else {
        documentAiName = trimmedType;  
    }
} else {
   
    documentAiName = 'Hotel_bills';
}

            
            // CORRECTED REQUEST BODY - Direct structure without "inputs"
            Map<String, Object> requestBodyMap = new Map<String, Object>{
                'idpConfigurationIdOrName' => documentAiName,
                'files' => new List<Object>{
                    new Map<String, Object>{
                        'mimeType' => mimeType,
                        'data' => base64File
                    }
                }
            };
            
            String requestBody = JSON.serialize(requestBodyMap);
            
            
            httpReq.setBody(requestBody);
            
            Http http = new Http();
            HttpResponse res = http.send(httpReq);
            
           
            if (res.getStatusCode() >= 200 && res.getStatusCode() <= 202) {
                Map<String, Object> outerJson = 
                    (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                
                // Check if data exists
                if (!outerJson.containsKey('data') || outerJson.get('data') == null) {
                    System.debug('Full Response: ' + JSON.serializePretty(outerJson));
                    throw new AuraHandledException('No data in response. Check debug logs.');
                }
                
                List<Object> dataList = (List<Object>) outerJson.get('data');
                
                if (dataList == null || dataList.isEmpty()) {
                    throw new AuraHandledException('Empty data array returned from Document AI');
                }
                
                Map<String, Object> dataItem = (Map<String, Object>) dataList[0];
                
                String encodedJson = (String) dataItem.get('data');
                
                if (encodedJson == null || encodedJson.trim().length() == 0) {
                    System.debug('No encoded data found. Full data item: ' + JSON.serializePretty(dataItem));
                    throw new AuraHandledException('No extracted data in response');
                }
                
                
                // Decode HTML entities
                String decodedJson = encodedJson
                    .replace('&quot;', '"')
                    .replace('&amp;', '&')
                    .replace('&lt;', '<')
                    .replace('&gt;', '>')
                    .replace('&apos;', '\'');
                
                System.debug('Decoded JSON (first 1000 chars): ' + 
                    (decodedJson.length() > 1000 ? decodedJson.substring(0, 1000) : decodedJson));
                
                // Simplify the JSON structure
                String simplifiedJson = simplifyJson(decodedJson);
                
                System.debug('Simplified JSON (first 1000 chars): ' + 
                    (simplifiedJson.length() > 1000 ? simplifiedJson.substring(0, 1000) : simplifiedJson));
                
                // Update Case with response
                caseRecord.Document_AI_Response__c = simplifiedJson;
                update caseRecord;
                
                // Parse and populate response
                Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(simplifiedJson);
                response = parseResponse(dataMap);
                response.isSuccess = true;
                
                
                
            } else {
                String errorMsg = 'API call failed with status: ' + res.getStatusCode() + 
                                 '. Response: ' + res.getBody();
                System.debug('ERROR: ' + errorMsg);
                throw new AuraHandledException(errorMsg);
            }
            
        } catch (Exception e) {
            System.debug('ERROR: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            System.debug('Line Number: ' + e.getLineNumber());
            System.debug('Exception Type: ' + e.getTypeName());
            response.isSuccess = false;
            response.errorMessage = e.getMessage() + ' (Line: ' + e.getLineNumber() + ')';
        }
        
        responses.add(response);
        
        return responses;
    }
    
    private static Response parseResponse(Map<String, Object> dataMap) {
        Response response = new Response();
        
        try {
            
            // Parse simple fields
            response.gstRegNo = (String) dataMap.get('gst_reg_no');
            response.panNoHotel = (String) dataMap.get('pan_no_hotel');
            response.userId = (String) dataMap.get('user_id');
            response.cinNo = (String) dataMap.get('cin_no');
            response.invoiceNo = (String) dataMap.get('invoice_no');
            response.invoiceDate = (String) dataMap.get('invoice_date');
            response.tripId = (String) dataMap.get('trip_id');
            response.travelRequestNo = (String) dataMap.get('travel_request_no');
            response.costCentre = (String) dataMap.get('cost_centre');
            response.hotelName = (String) dataMap.get('hotel_name');
            response.gstRegNoClient = (String) dataMap.get('gst_reg_no_client');
            response.panNoClient = (String) dataMap.get('pan_no_client');
            response.placeOfSupply = (String) dataMap.get('place_of_supply');
            response.hsnCode = (String) dataMap.get('hsn_code');
            response.taxPayableOnReverseCharge = (String) dataMap.get('tax_payable_on_reverse_charge');
            response.irnNo = (String) dataMap.get('irn_no');
            response.totalAmountInWords = (String) dataMap.get('total_amount_in_words');
            response.bankInfo = (String) dataMap.get('bank_info');
            response.notes = (String) dataMap.get('notes');
            
           
            List<Object> productDetailsList = (List<Object>) dataMap.get('product_details');
            if (productDetailsList != null && !productDetailsList.isEmpty()) {
                System.debug('Parsing product details...');
                Map<String, Object> firstProduct = (Map<String, Object>) productDetailsList[0];
                Map<String, Object> productValue = (Map<String, Object>) firstProduct.get('value');
                
                response.productType = getStringValue(productValue, 'product_type');
                response.guestName = getStringValue(productValue, 'guest_name');
                response.gender = getStringValue(productValue, 'gender');
                response.productHotelName = getStringValue(productValue, 'hotel_name');
                response.confNo = getStringValue(productValue, 'conf_no');
                response.checkInDate = getStringValue(productValue, 'check_in_date');
                response.checkOutDate = getStringValue(productValue, 'check_out_date');
                
                response.allProductDetailsJson = JSON.serialize(productDetailsList);
            }
            
            // Parse Fare Details
            List<Object> fareDetailsList = (List<Object>) dataMap.get('fare_details');
            if (fareDetailsList != null && !fareDetailsList.isEmpty()) {
                System.debug('Parsing fare details...');
                Map<String, Object> firstFare = (Map<String, Object>) fareDetailsList[0];
                Map<String, Object> fareValue = (Map<String, Object>) firstFare.get('value');
                
                response.documentNumber = getStringValue(fareValue, 'document_number');
                response.fare = getDecimalValue(fareValue, 'fare');
                response.tax = getDecimalValue(fareValue, 'tax');
                response.ssr = getDecimalValue(fareValue, 'ssr');
                response.discount = getDecimalValue(fareValue, 'discount');
                response.surcharge = getDecimalValue(fareValue, 'surcharge');
                response.managementFee = getDecimalValue(fareValue, 'management_fee');
                response.serviceFee = getDecimalValue(fareValue, 'service_fee');
                response.totalFare = getDecimalValue(fareValue, 'total');
                
                response.allFareDetailsJson = JSON.serialize(fareDetailsList);
            }
            
            // Parse GST Details
            List<Object> gstDetailsList = (List<Object>) dataMap.get('gst_details');
            if (gstDetailsList != null && !gstDetailsList.isEmpty()) {
                System.debug('Parsing GST details...');
                Map<String, Object> firstGst = (Map<String, Object>) gstDetailsList[0];
                Map<String, Object> gstValue = (Map<String, Object>) firstGst.get('value');
                
                response.gstDescription = getStringValue(gstValue, 'description');
                response.hsnSac = getStringValue(gstValue, 'hsn_sac');
                response.taxableValue = getDecimalValue(gstValue, 'taxable_value');
                response.cgstPercent = getDecimalValue(gstValue, 'cgst_percent');
                response.cgstAmount = getDecimalValue(gstValue, 'cgst_amount');
                response.sgstUgstPercent = getDecimalValue(gstValue, 'sgst_ugst_percent');
                response.sgstUgstAmount = getDecimalValue(gstValue, 'sgst_ugst_amount');
                response.igstPercent = getDecimalValue(gstValue, 'igst_percent');
                response.igstAmount = getDecimalValue(gstValue, 'igst_amount');
                response.totalGstAmount = getDecimalValue(gstValue, 'total_gst_amount');
                
                response.allGstDetailsJson = JSON.serialize(gstDetailsList);
            }
            
            System.debug('Parsing completed successfully');
            
        } catch (Exception e) {
            System.debug('Error parsing response: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
        
        return response;
    }
    
    private static String simplifyJson(String jsonInput) {
        try {
            Map<String, Object> originalMap = 
                (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
            Map<String, Object> simpleMap = new Map<String, Object>();
            
            for (String key : originalMap.keySet()) {
                Object val = originalMap.get(key);
                
                if (val instanceof Map<String, Object> && 
                    ((Map<String, Object>)val).containsKey('value')) {
                    simpleMap.put(key, ((Map<String, Object>)val).get('value'));
                } else {
                    simpleMap.put(key, val);
                }
            }
            
            return JSON.serialize(simpleMap);
        } catch (Exception e) {
            System.debug('Error simplifying JSON: ' + e.getMessage());
            return jsonInput;
        }
    }
    
    private static String getStringValue(Map<String, Object> parentMap, String key) {
        if (parentMap != null && parentMap.containsKey(key)) {
            Object obj = parentMap.get(key);
            if (obj instanceof Map<String, Object>) {
                Map<String, Object> nestedMap = (Map<String, Object>) obj;
                return (String) nestedMap.get('value');
            }
            return (String) obj;
        }
        return null;
    }
    
    private static Decimal getDecimalValue(Map<String, Object> parentMap, String key) {
        if (parentMap != null && parentMap.containsKey(key)) {
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