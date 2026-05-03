public class DocumentAIParser {
    
    public static DocumentAIResponse parseDocumentAIResponse(String jsonResponse) {
        DocumentAIResponse response = new DocumentAIResponse();
        
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            
            // Get the Hotel_Bills object (or whatever document type key exists)
            Map<String, Object> hotelBills = null;
            for (String key : responseMap.keySet()) {
                if (responseMap.get(key) instanceof Map<String, Object>) {
                    hotelBills = (Map<String, Object>) responseMap.get(key);
                    break;
                }
            }
            
            if (hotelBills != null) {
                // Parse simple fields
                response.gstRegNo = (String) hotelBills.get('gst_reg_no');
                response.panNoHotel = (String) hotelBills.get('pan_no_hotel');
                response.userId = (String) hotelBills.get('user_id');
                response.cinNo = (String) hotelBills.get('cin_no');
                response.invoiceNo = (String) hotelBills.get('invoice_no');
                response.invoiceDate = (String) hotelBills.get('invoice_date');
                response.tripId = (String) hotelBills.get('trip_id');
                response.travelRequestNo = (String) hotelBills.get('travel_request_no');
                response.costCentre = (String) hotelBills.get('cost_centre');
                response.hotelName = (String) hotelBills.get('hotel_name');
                response.gstRegNoClient = (String) hotelBills.get('gst_reg_no_client');
                response.panNoClient = (String) hotelBills.get('pan_no_client');
                response.placeOfSupply = (String) hotelBills.get('place_of_supply');
                response.hsnCode = (String) hotelBills.get('hsn_code');
                response.taxPayableOnReverseCharge = (String) hotelBills.get('tax_payable_on_reverse_charge');
                response.irnNo = (String) hotelBills.get('irn_no');
                response.totalAmountInWords = (String) hotelBills.get('total_amount_in_words');
                response.bankInfo = (String) hotelBills.get('bank_info');
                response.notes = (String) hotelBills.get('notes');
                
                // Parse Product Details
                response.productDetails = new List<DocumentAIResponse.ProductDetail>();
                List<Object> productDetailsList = (List<Object>) hotelBills.get('product_details');
                if (productDetailsList != null) {
                    for (Object prodObj : productDetailsList) {
                        Map<String, Object> prodMap = (Map<String, Object>) prodObj;
                        Map<String, Object> valueMap = (Map<String, Object>) prodMap.get('value');
                        
                        DocumentAIResponse.ProductDetail pd = new DocumentAIResponse.ProductDetail();
                        pd.productType = getStringValue(valueMap, 'product_type');
                        pd.guestName = getStringValue(valueMap, 'guest_name');
                        pd.gender = getStringValue(valueMap, 'gender');
                        pd.hotelName = getStringValue(valueMap, 'hotel_name');
                        pd.confNo = getStringValue(valueMap, 'conf_no');
                        pd.checkInDate = getStringValue(valueMap, 'check_in_date');
                        pd.checkOutDate = getStringValue(valueMap, 'check_out_date');
                        
                        response.productDetails.add(pd);
                    }
                }
                
                // Parse Fare Details
                response.fareDetails = new List<DocumentAIResponse.FareDetail>();
                List<Object> fareDetailsList = (List<Object>) hotelBills.get('fare_details');
                if (fareDetailsList != null) {
                    for (Object fareObj : fareDetailsList) {
                        Map<String, Object> fareMap = (Map<String, Object>) fareObj;
                        Map<String, Object> valueMap = (Map<String, Object>) fareMap.get('value');
                        
                        DocumentAIResponse.FareDetail fd = new DocumentAIResponse.FareDetail();
                        fd.documentNumber = getStringValue(valueMap, 'document_number');
                        fd.fare = getDecimalValue(valueMap, 'fare');
                        fd.tax = getDecimalValue(valueMap, 'tax');
                        fd.ssr = getDecimalValue(valueMap, 'ssr');
                        fd.discount = getDecimalValue(valueMap, 'discount');
                        fd.surcharge = getDecimalValue(valueMap, 'surcharge');
                        fd.managementFee = getDecimalValue(valueMap, 'management_fee');
                        fd.serviceFee = getDecimalValue(valueMap, 'service_fee');
                        fd.total = getDecimalValue(valueMap, 'total');
                        
                        response.fareDetails.add(fd);
                    }
                }
                
                // Parse GST Details
                response.gstDetails = new List<DocumentAIResponse.GSTDetail>();
                List<Object> gstDetailsList = (List<Object>) hotelBills.get('gst_details');
                if (gstDetailsList != null) {
                    for (Object gstObj : gstDetailsList) {
                        Map<String, Object> gstMap = (Map<String, Object>) gstObj;
                        Map<String, Object> valueMap = (Map<String, Object>) gstMap.get('value');
                        
                        DocumentAIResponse.GSTDetail gd = new DocumentAIResponse.GSTDetail();
                        gd.description = getStringValue(valueMap, 'description');
                        gd.hsnSac = getStringValue(valueMap, 'hsn_sac');
                        gd.taxableValue = getDecimalValue(valueMap, 'taxable_value');
                        gd.cgstPercent = getDecimalValue(valueMap, 'cgst_percent');
                        gd.cgstAmount = getDecimalValue(valueMap, 'cgst_amount');
                        gd.sgstUgstPercent = getDecimalValue(valueMap, 'sgst_ugst_percent');
                        gd.sgstUgstAmount = getDecimalValue(valueMap, 'sgst_ugst_amount');
                        gd.igstPercent = getDecimalValue(valueMap, 'igst_percent');
                        gd.igstAmount = getDecimalValue(valueMap, 'igst_amount');
                        gd.totalGstAmount = getDecimalValue(valueMap, 'total_gst_amount');
                        
                        response.gstDetails.add(gd);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing response: ' + e.getMessage());
        }
        
        return response;
    }
    
    // Helper method to extract string value from nested map
    private static String getStringValue(Map<String, Object> parentMap, String key) {
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

    // Helper method to extract decimal value from nested map
    private static Decimal getDecimalValue(Map<String, Object> parentMap, String key) {
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