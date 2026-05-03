/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : TypeOfAccount
 * Author          : <YourName>
 * Created Date    : Apr 23, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Apr 23, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 23, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class TypeOfAccount {

	public class Request {
        @InvocableVariable(required=true)
        public String mobileNumber;
    }

	public class Response {
        @InvocableVariable
        public Integer savingsCount;

        @InvocableVariable
        public Integer creditCardCount;

        @InvocableVariable
        public List<String> savingsAccounts;

        @InvocableVariable
        public List<String> creditCardAccounts;

		@InvocableVariable
        public Boolean isSuccess;
    }

	@InvocableMethod(label='Get Type Of Accounts by Mobile Number')
    public static List<Response> doSomething(List<Request> requests) {

        List<Response> responses = new List<Response>();

        Set<String> mobileSet = new Set<String>();
        for (Request req : requests) {
            if (req.mobileNumber != null) {
                mobileSet.add(req.mobileNumber);
            }
        }

        
        List<FinancialAccount> faList = [
            SELECT Id, Type, Status, FinancialAccountNumber, Phone__c
            FROM FinancialAccount
            WHERE Phone__c IN :mobileSet
            AND Status = 'Active'
        ];

        for (Request req : requests) {

            Response res = new Response();
            res.savingsCount = 0;
            res.creditCardCount = 0;
            res.savingsAccounts = new List<String>();
            res.creditCardAccounts = new List<String>();
			res.isSuccess = true;

            for (FinancialAccount fa : faList) {

                if (fa.Phone__c == req.mobileNumber) {

                    String last3 = '';

                    if (fa.FinancialAccountNumber != null && fa.FinancialAccountNumber.length() >= 3) {
                        last3 = fa.FinancialAccountNumber.substring(
                            fa.FinancialAccountNumber.length() - 3
                        );
                    }

                   
                    if (fa.Type == 'Savings') {
                        res.savingsCount++;
                        res.savingsAccounts.add(last3);
                    }

                    
                    else if (fa.Type == 'Credit Card') {
                        res.creditCardCount++;
                        res.creditCardAccounts.add(last3);
                    }
                }
            }

            responses.add(res);
        }

        return responses;
    }

}