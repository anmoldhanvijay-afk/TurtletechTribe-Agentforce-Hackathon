public class VerifyAadhaarService {

    public class Request {
        @InvocableVariable(
            label='Phone Number'
            description='Customer phone number to find their account'
            required=true)
        public String phone;

        @InvocableVariable(
            label='Entered Last Four Digits'
            description='Last 4 digits of Aadhaar entered by customer'
            required=true)
        public String enteredDigits;
    }

    public class Response {
        @InvocableVariable(
            label='Is Valid'
            description='True if Aadhaar verified successfully')
        public Boolean isValid;

        @InvocableVariable(
            label='Message'
            description='Verification result message')
        public String message;
    }

    @InvocableMethod(
        label='Verify Aadhaar'
        description='Verifies last 4 digits of customer Aadhaar card against stored encrypted Aadhaar number')
    public static List<Response> verifyAadhaar(
        List<Request> requests) {

        List<Response> responses = 
            new List<Response>();

        for(Request req : requests) {
            Response res = new Response();
            res.isValid = false;

            try {
                // Find Account by phone
                String cleaned = 
                    req.phone.replaceAll(
                        '[^0-9]', '');
                if(cleaned.length() > 10) {
                    cleaned = cleaned.substring(
                        cleaned.length() - 10);
                }

                List<Account> accounts = [
                    SELECT Id, 
                           Aadhaar_Number__c
                    FROM Account
                    WHERE Phone LIKE 
                        :('%' + cleaned)
                    OR PersonMobilePhone LIKE 
                        :('%' + cleaned)
                    LIMIT 1
                ];

                if(accounts.isEmpty()) {
                    res.message = 
                        'Account not found';
                    responses.add(res);
                    continue;
                }

                Account acc = accounts[0];

                if(String.isBlank(
                    acc.Aadhaar_Number__c)) {
                    res.message = 
                        'Aadhaar not found on file';
                    responses.add(res);
                    continue;
                }

                // Get last 4 digits of 
                // stored Aadhaar
                String storedAadhaar = 
                    acc.Aadhaar_Number__c;
                String storedLastFour = 
                    storedAadhaar.substring(
                        storedAadhaar.length() - 4);

                // Compare with entered digits
                if(storedLastFour.equals(
                    req.enteredDigits.trim())) {
                    res.isValid = true;
                    res.message = 
                        'Aadhaar verified successfully';
                } else {
                    res.isValid = false;
                    res.message = 
                        'Invalid Aadhaar digits. Please try again.';
                }

            } catch(Exception e) {
                res.message = 
                    'Error: ' + e.getMessage();
            }

            responses.add(res);
        }

        return responses;
    }
}