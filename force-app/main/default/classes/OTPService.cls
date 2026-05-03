/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : BalanceService
 * Author          : Anmol Dhanvijay
 * Created Date    : Apr 17, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 17, 2026
 * Description     : This class is used for scnario 1 of Hackthon as when user 
					ask for balance check then this invoke to OTP send, verify, and show result
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 17, 2026  │ <YourName>   │ Initial version 1.0
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

global class OTPService {

    //  Request Wrapper
    global class Request {
        @InvocableVariable
        public String phone;
    }

    
    global class Response {
        @InvocableVariable
        public String message;

		@InvocableVariable
        public String Otp;

		@InvocableVariable
        public String emailId;

        @InvocableVariable
        public String accountId;        

    }

    
    @InvocableMethod(label='Process OTP Request')
	global static List<Response> processOTPRequest(List<Request> requests) {

		List<Response> responses = new List<Response>();

		for (Request req : requests) {

			Response res;

			String phone = req.phone;

            
            if(String.isBlank(phone)){
                phone = sessionManager.getLatestPhone();
            }

            Account acc = getAccountByPhone(phone);

			if (acc == null) {
				res = new Response();
				res.message = 'No account found with this number';
				responses.add(res);
				continue;
			}

			FinancialAccount fa = getActiveSavingAccount(acc.Id);

			if (fa == null) {
				res = new Response();
				res.message = 'No active savings account found';
				responses.add(res);
				continue;
			}

			// Now returning full response
			res = generateAndSendOTP(acc.Id);

			responses.add(res);
		}

		return responses;
	}

    public static Account getAccountByPhone(String phone) {

        if (String.isBlank(phone)) return null;

        String cleaned = phone.replaceAll('[^0-9]', '');

        if (cleaned.length() > 10) {
            cleaned = cleaned.substring(cleaned.length() - 10);
        }

        List<Account> accList = [
            SELECT Id, PersonEmail, Phone, PersonMobilePhone
            FROM Account
            WHERE 
                Phone LIKE :('%' + cleaned)
                OR PersonMobilePhone LIKE :('%' + cleaned)
            LIMIT 1
        ];

        return accList.isEmpty() ? null : accList[0];
    }

   
    public static FinancialAccount getActiveSavingAccount(Id accountId) {

        List<FinancialAccount> faList = [
            SELECT Id, Name, Type, Status
            FROM FinancialAccount
            WHERE Id IN (
                SELECT FinancialAccountId
                FROM FinancialAccountParty
                WHERE AccountId = :accountId
            )
            
            AND Status = 'Active'
            LIMIT 1
        ];

        return faList.isEmpty() ? null : faList[0];
    }

    
    public static Response  generateAndSendOTP(String accountId) {
		Response res = new Response();

        //  Null check
        if (accountId == null) {
            res.message = 'Invalid account ID';
        	return res;
        }

        //  Fetch Account
        List<Account> accList = [
            SELECT Id, PersonEmail, Phone, PersonMobilePhone
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (accList.isEmpty()) {
            res.message = 'Account not found';
			return res;
        }

        Account acc = accList[0];
		String maskedEmail = maskEmail(acc.PersonEmail);

        if (String.isBlank(acc.PersonEmail)) {
            res.message =  'Registered email not available';
			return res;
        }

        //  Check for existing active OTP
        List<OTP__c> oldOtps = [
            SELECT Id, Is_Used__c
            FROM OTP__c
            WHERE Account__c = :accountId
            AND Is_Used__c = false
        ];

        for (OTP__c oldOtp : oldOtps) {
            oldOtp.Is_Used__c = true;
        }

        if (!oldOtps.isEmpty()) {
            update oldOtps;
        }
        //  Generate OTP (guaranteed 6-digit: 100000–999999)
         Integer otpInt = Math.mod(Math.abs(Crypto.getRandomInteger()), 1000000);
    	String otpStr = String.valueOf(otpInt).leftPad(6, '0');

        //  Normalize phone
        String phone = acc.PersonMobilePhone != null
            ? acc.PersonMobilePhone
            : acc.Phone;

        //  Build and insert OTP record
        OTP__c otpRec = new OTP__c();
        otpRec.Account__c     = accountId;
        otpRec.OTP_Code__c = Decimal.valueOf(otpStr);
        otpRec.Name           = 'OTP-' + accountId;
        otpRec.Phone__c       = phone;
        otpRec.Email__c       = acc.PersonEmail;
        otpRec.Expiry_Time__c = System.now().addMinutes(5);

        try {
            insert otpRec;
        } catch (DmlException e) {
            System.debug('OTP insert failed: ' + e.getMessage());
             res.message = 'Failed to generate OTP. Please try again.';
            return res;
        }
		Id orgWideEmailId = [
			SELECT Id FROM OrgWideEmailAddress 
			WHERE Address = 'anmol.dhanvijay@turtletechtribe.com'
			LIMIT 1
		].Id;
        //  Send Email inline
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { acc.PersonEmail });
			mail.setOrgWideEmailAddressId(orgWideEmailId);
            mail.setSubject('Your OTP Verification Code');
            mail.setPlainTextBody(
                ' OTP Verification\n\n' +
                'OTP: ' + otpStr + '\n' +
                'Valid for 5 minutes\n\n' +
                'Do not share this OTP with anyone.\n\n' +
                'Regards,\nBank Team'
            );

            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[] { mail },
                false  // allOrNone = false
            );

			 res.message = 'OTP sent successfully';
			res.otp = otpStr;              
			res.emailId = acc.PersonEmail;
            res.accountId = accountId;
            

        } catch (Exception e) {
           
            res.message = 'OTP generated but email delivery failed';
			return res;
        }

        //return 'OTP has been sent to your registered email (' + maskedEmail + ')';
		res.message = 'OTP has been sent to your registered email';
		return res;
    }

	public static String maskEmail(String email) {

		if (String.isBlank(email) || !email.contains('@')) {
			return 'your registered email';
		}

		String[] parts = email.split('@');

		String name = parts[0];
		String domain = parts[1];

		// Mask name
		String maskedName;
		if (name.length() <= 2) {
			maskedName = name.substring(0, 1) + '*';
		} else {
			maskedName = name.substring(0, 1) + '****' + name.substring(name.length() - 1);
		}

		return maskedName + '@' + domain;
	}

}