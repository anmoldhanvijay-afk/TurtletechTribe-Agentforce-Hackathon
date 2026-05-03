public class CreateEMITransactions {

    public class Request {
        @InvocableVariable(
            label='Financial Account Id'
            description='Salesforce ID of customers active home loan record'
            required=true)
        public String financialAccountId;

        @InvocableVariable(
            label='New EMI Amount'
            description='New monthly EMI amount after restructuring'
            required=true)
        public Decimal newEMI;
    }

    public class Response {
        @InvocableVariable(
            label='Success Message'
            description='Confirmation of transactions created')
        public String successMessage;

        @InvocableVariable(
            label='Transaction Count'
            description='Number of transactions created')
        public Integer transactionCount;
    }

    @InvocableMethod(
        label='Create EMI Transactions'
        description='Creates 10 new EMI transactions for restructured loan')
    public static List<Response> 
        createTransactions(
            List<Request> requests) {

        List<Response> responses = 
            new List<Response>();

        for(Request req : requests) {
            Response res = new Response();
            
            List<FinancialAccountTransaction> existing = [ SELECT Id FROM FinancialAccountTransaction WHERE FinancialAccountId =:req.financialAccountId AND Description LIKE '%Restructured%'LIMIT 1];

if(!existing.isEmpty()) {
    res.successMessage = 
        'Transactions already exist';
    res.transactionCount = 0;
    responses.add(res);
    continue;
}

            try {
                List<FinancialAccountTransaction> 
                    transactions = 
                    new List<FinancialAccountTransaction>();

               
                Date today = Date.today();
                Date startDate = Date.newInstance(
                    today.year(),
                    today.month(),
                    9
                );

                
                if(today.day() >= 9) {
                    startDate = startDate
                        .addMonths(1);
                }

                
                for(Integer i = 0; i < 10; i++) {
                    Date txnDate = 
                        startDate.addMonths(i);

                    // Get month and year 
                    // for description
                    String monthName = 
                        getMonthName(
                            txnDate.month());
                    String year = 
                        String.valueOf(
                            txnDate.year());

                    FinancialAccountTransaction t = 
                        new FinancialAccountTransaction();
                    t.FinancialAccountId = 
                        req.financialAccountId;
                    t.Amount = req.newEMI;
                    t.TransactionDate = 
                        DateTime.newInstance(
                            txnDate, 
                            Time.newInstance(
                                0,0,0,0));
                    t.Description = 
                        'EMI ' + monthName + 
                        ' ' + year + 
                        ' - Restructured';
                    t.DebitCreditIndicator = 'Debit';
                    t.CurrencyIsoCode = 'INR';
                    transactions.add(t);
                }

                // Single DML for all 10
                insert transactions;

                res.successMessage = 
                    '10 EMI transactions created successfully';
                res.transactionCount = 10;

            } catch(Exception e) {
                res.successMessage = 
                    'Error: ' + e.getMessage();
                res.transactionCount = 0;
            }

            responses.add(res);
        }

        return responses;
    }

    // Helper method to get month name
    private static String getMonthName(
        Integer month) {
        Map<Integer, String> months = 
            new Map<Integer, String>{
                1 => 'January',
                2 => 'February',
                3 => 'March',
                4 => 'April',
                5 => 'May',
                6 => 'June',
                7 => 'July',
                8 => 'August',
                9 => 'September',
                10 => 'October',
                11 => 'November',
                12 => 'December'
            };
        return months.get(month);
    }
}