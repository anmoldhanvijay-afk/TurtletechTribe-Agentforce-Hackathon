public class DocumentAIResponse {
    
    @InvocableVariable(label='GST Registration Number')
    public String gstRegNo;
    
    @InvocableVariable(label='PAN Number Hotel')
    public String panNoHotel;
    
    @InvocableVariable(label='User ID')
    public String userId;
    
    @InvocableVariable(label='CIN Number')
    public String cinNo;
    
    @InvocableVariable(label='Invoice Number')
    public String invoiceNo;
    
    @InvocableVariable(label='Invoice Date')
    public String invoiceDate;
    
    @InvocableVariable(label='Trip ID')
    public String tripId;
    
    @InvocableVariable(label='Travel Request Number')
    public String travelRequestNo;
    
    @InvocableVariable(label='Cost Centre')
    public String costCentre;
    
    @InvocableVariable(label='Hotel Name')
    public String hotelName;
    
    @InvocableVariable(label='GST Registration Number Client')
    public String gstRegNoClient;
    
    @InvocableVariable(label='PAN Number Client')
    public String panNoClient;
    
    @InvocableVariable(label='Place of Supply')
    public String placeOfSupply;
    
    @InvocableVariable(label='HSN Code')
    public String hsnCode;
    
    @InvocableVariable(label='Tax Payable on Reverse Charge')
    public String taxPayableOnReverseCharge;
    
    @InvocableVariable(label='IRN Number')
    public String irnNo;
    
    @InvocableVariable(label='Total Amount in Words')
    public String totalAmountInWords;
    
    @InvocableVariable(label='Bank Info')
    public String bankInfo;
    
    @InvocableVariable(label='Notes')
    public String notes;
    
    @InvocableVariable(label='Product Details')
    public List<ProductDetail> productDetails;
    
    @InvocableVariable(label='Fare Details')
    public List<FareDetail> fareDetails;
    
    @InvocableVariable(label='GST Details')
    public List<GSTDetail> gstDetails;
    
    // Inner class for Product Details
    public class ProductDetail {
        @InvocableVariable(label='Product Type')
        public String productType;
        
        @InvocableVariable(label='Guest Name')
        public String guestName;
        
        @InvocableVariable(label='Gender')
        public String gender;
        
        @InvocableVariable(label='Hotel Name')
        public String hotelName;
        
        @InvocableVariable(label='Confirmation Number')
        public String confNo;
        
        @InvocableVariable(label='Check-in Date')
        public String checkInDate;
        
        @InvocableVariable(label='Check-out Date')
        public String checkOutDate;
    }
    
    // Inner class for Fare Details
    public class FareDetail {
        @InvocableVariable(label='Document Number')
        public String documentNumber;
        
        @InvocableVariable(label='Fare')
        public Decimal fare;
        
        @InvocableVariable(label='Tax')
        public Decimal tax;
        
        @InvocableVariable(label='SSR')
        public Decimal ssr;
        
        @InvocableVariable(label='Discount')
        public Decimal discount;
        
        @InvocableVariable(label='Surcharge')
        public Decimal surcharge;
        
        @InvocableVariable(label='Management Fee')
        public Decimal managementFee;
        
        @InvocableVariable(label='Service Fee')
        public Decimal serviceFee;
        
        @InvocableVariable(label='Total')
        public Decimal total;
    }
    
    // Inner class for GST Details
    public class GSTDetail {
        @InvocableVariable(label='Description')
        public String description;
        
        @InvocableVariable(label='HSN/SAC')
        public String hsnSac;
        
        @InvocableVariable(label='Taxable Value')
        public Decimal taxableValue;
        
        @InvocableVariable(label='CGST Percent')
        public Decimal cgstPercent;
        
        @InvocableVariable(label='CGST Amount')
        public Decimal cgstAmount;
        
        @InvocableVariable(label='SGST/UGST Percent')
        public Decimal sgstUgstPercent;
        
        @InvocableVariable(label='SGST/UGST Amount')
        public Decimal sgstUgstAmount;
        
        @InvocableVariable(label='IGST Percent')
        public Decimal igstPercent;
        
        @InvocableVariable(label='IGST Amount')
        public Decimal igstAmount;
        
        @InvocableVariable(label='Total GST Amount')
        public Decimal totalGstAmount;
    }
}