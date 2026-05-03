/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : VerifyOTPService
 * Author          : <YourName>
 * Created Date    : Apr 20, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 20, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 20, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

global class VerifyOTPService {

    global class Request {
        @InvocableVariable(required=true)
        public String phone;

        @InvocableVariable(required=true)
        public Decimal enteredOtp;
    }

    global class Response {
        @InvocableVariable
        public Boolean isValid;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(label='Verify OTP')
    global static List<Response> verifyOtp(List<Request> requests) {

        List<Response> responses = new List<Response>();

        for (Request req : requests) {

            Response res = new Response();
            res.isValid = false;

            List<OTP__c> otpList = [
                SELECT Id, OTP_Code__c, Is_Used__c
                FROM OTP__c
                WHERE Phone__c = :req.phone
                AND Is_Used__c = false
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (otpList.isEmpty()) {
                res.message = 'No OTP found';
                responses.add(res);
                continue;
            }

            OTP__c otpRec = otpList[0];

            if (otpRec.OTP_Code__c == req.enteredOtp) {
                otpRec.Is_Used__c = true;
                update otpRec;

                List<WhatsApp_Session__c> sessions = [
                    SELECT Id, Is_Verified__c
                    FROM WhatsApp_Session__c
                    WHERE Phone__c = :req.phone
                    AND Is_Active__c = true
                    LIMIT 1
                ];

                if (!sessions.isEmpty()) {
                    WhatsApp_Session__c s = sessions[0];
                    s.Is_Verified__c = true;
                    update s;
                }


                res.isValid = true;
                res.message = 'OTP verified successfully';


            } else {
                res.message = 'Invalid OTP';
            } 

            responses.add(res);
        }

        return responses;
    }
}