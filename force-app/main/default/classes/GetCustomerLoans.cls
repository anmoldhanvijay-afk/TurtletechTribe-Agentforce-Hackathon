public class GetCustomerLoans {

    public class Request {
        @InvocableVariable(
            label='Phone Number'
            description='Customer WhatsApp phone number to find their loans'
            )
        public String phone;
    }

    public class LoanDetail {
        @InvocableVariable(
            label='Loan Id'
            description='Salesforce ID of the loan record')
        public String loanId;

        @InvocableVariable(
            label='Loan Name'
            description='Name of the loan')
        public String loanName;

        @InvocableVariable(
            label='Loan Sub Type'
            description='Type of loan - Home Loan, Car Loan or Personal Loan')
        public String loanSubType;

        @InvocableVariable(
            label='Loan Amount'
            description='Total loan amount')
        public Decimal outstandingAmount;
    }

    public class Response {
        @InvocableVariable(
            label='Loans'
            description='List of all active loans for customer')
        public List<LoanDetail> loans;

        @InvocableVariable(
            label='Loan Count'
            description='Number of active loans found')
        public Integer loanCount;

        @InvocableVariable(
            label='Message'
            description='Message about loans found')
        public String message;

        @InvocableVariable(
            label='Single Loan Id'
            description='If only one loan exists return its ID')
        public String singleLoanId;
    }

    @InvocableMethod(
        label='Get Customer Loans'
        description='Fetches all active loans for customer based on their phone number.Returns list of loans with names and subtypes so customer can select which loan EMI to reduce.')
    public static List<Response> getLoans(
        List<Request> requests) {

        List<Response> responses = 
            new List<Response>();

        for(Request req : requests) {
            Response res = new Response();
            res.loans = new List<LoanDetail>();

            try {
                // Clean phone number
                String cleaned = 
                    req.phone.replaceAll(
                        '[^0-9]', '');
                if(cleaned.length() > 10) {
                    cleaned = cleaned.substring(
                        cleaned.length() - 10);
                }

                // Find Account by phone
                List<Account> accounts = [
                    SELECT Id
                    FROM Account
                    WHERE Phone LIKE 
                        :('%' + cleaned)
                    OR PersonMobilePhone LIKE 
                        :('%' + cleaned)
                    LIMIT 1
                ];

                if(accounts.isEmpty()) {
                    res.message = 
                        'No account found';
                    res.loanCount = 0;
                    responses.add(res);
                    continue;
                }

                Id accountId = accounts[0].Id;

                // Find all active loans
                List<FinancialAccount> loans = [
                    SELECT Id, Name, 
                           Sub_Type__c,
                           TotalOutstandingAmount
                    FROM FinancialAccount
                    WHERE Id IN (
                        SELECT FinancialAccountId
                        FROM FinancialAccountParty
                        WHERE AccountId = :accountId
                    )
                    AND Type = 'Loan'
                    AND Status = 'Active'
                ];

                if(loans.isEmpty()) {
                    res.message = 
                        'No active loans found';
                    res.loanCount = 0;
                    responses.add(res);
                    continue;
                }

                // Build loan details
                for(FinancialAccount fa : loans) {
                    LoanDetail detail = 
                        new LoanDetail();
                    detail.loanId = fa.Id;
                    detail.loanName = fa.Name;
                    detail.loanSubType = 
                        fa.Sub_Type__c != null 
                        ? fa.Sub_Type__c 
                        : 'Loan';
                    detail.outstandingAmount = 
                        fa.TotalOutstandingAmount;
                    res.loans.add(detail);
                }

                res.loanCount = loans.size();

                // If only one loan
                if(loans.size() == 1) {
                    res.singleLoanId = 
                        loans[0].Id;
                    res.message = 
                        'One active loan found';
                } else {
                    res.message = 
                        loans.size() + 
                        ' active loans found';
                }

            } catch(Exception e) {
                res.message = 
                    'Error: ' + e.getMessage();
                res.loanCount = 0;
            }

            responses.add(res);
        }

        return responses;
    }
}