global class FinancialStatement {

    global class Request {
        @InvocableVariable(required=true label='Phone Number' description='Customer phone number associated with the financial account')
        public String phone;

        @InvocableVariable(label='Account Type' description='Type of account: Credit Card or Savings')
        public String accountType;

        @InvocableVariable(label='Last Digits' description='Last 4 digits of the account number for verification')
        public String lastDigits;
    }

    global class TransactionWrapper {
        @InvocableVariable(label='Transaction ID' description='Unique Salesforce ID of the transaction record (internal use only, not shown to user)')
        public String transactionId;

        @InvocableVariable(label='Transaction Date' description='Date of the transaction in DD-MM-YYYY format')
        public String transactionDate;

        @InvocableVariable(label='Description' description='Description of the transaction')
        public String description;

        @InvocableVariable(label='Type' description='Transaction type: Debit or Credit')
        public String type;

        @InvocableVariable(label='Amount' description='Transaction amount with currency symbol')
        public String amount;

        @InvocableVariable(label='Balance' description='Account balance after this transaction')
        public String balance;
    }

    global class Response {
        @InvocableVariable(label='Message' description='Detailed statement message with account summary and transaction details')
        public String message;

        @InvocableVariable(label='Account Type' description='Type of the matched financial account')
        public String accountType;

        @InvocableVariable(label='Latest Balance' description='Most recent account balance')
        public String latestBalance;

        @InvocableVariable(label='Transactions' description='List of recent transactions (up to 5)')
        public List<TransactionWrapper> transactions;
    }

    @InvocableMethod(label='Get Mini Statement New' description='Retrieves mini statement for a financial account including balance and recent transactions')
    global static List<Response> getMiniStatement(List<Request> requests) {
        List<Response> responses = new List<Response>();

        Set<String> phones = new Set<String>();
        for (Request req : requests) {
            if (!String.isBlank(req.phone)) {
                phones.add(req.phone);
            }
        }

        List<FinancialAccount> faList = [
            SELECT Id, Type, FinancialAccountNumber, Phone__c,
                   CreditLimit,
                   Total_Available_Amount__c,
                   Current_Outstanding__c,
                   Billing_Cycle_Date__c,
                   PaymentDueDate,
                   AmountDue,
                   Last_Payment_Amount__c,
                   Last_Payment_Date__c
            FROM FinancialAccount
            WHERE Phone__c IN :phones
            AND Status = 'Active'
        ];

        Map<Id, List<FinancialAccountTransaction>> faToTxn = new Map<Id, List<FinancialAccountTransaction>>();
        if (!faList.isEmpty()) {
            Set<Id> faIds = new Set<Id>();
            for (FinancialAccount fa : faList) faIds.add(fa.Id);

            for (FinancialAccountTransaction txn : [
                SELECT Id, TransactionDate, Amount, DebitCreditIndicator, Description, FinancialAccountId
                FROM FinancialAccountTransaction
                WHERE FinancialAccountId IN :faIds
                ORDER BY TransactionDate DESC
            ]) {
                if (!faToTxn.containsKey(txn.FinancialAccountId)) {
                    faToTxn.put(txn.FinancialAccountId, new List<FinancialAccountTransaction>());
                }
                if (faToTxn.get(txn.FinancialAccountId).size() < 5) {
                    faToTxn.get(txn.FinancialAccountId).add(txn);
                }
            }
        }

        Map<Id, Map<Date, Decimal>> faToDateBalance = new Map<Id, Map<Date, Decimal>>();
        for (FinancialAccountBalance fab : [
            SELECT FinancialAccountId, Amount, BalanceAsOfDate
            FROM FinancialAccountBalance
            WHERE FinancialAccountId IN :faList
            AND Type = 'Available Balance'
        ]) {
            if (!faToDateBalance.containsKey(fab.FinancialAccountId)) {
                faToDateBalance.put(fab.FinancialAccountId, new Map<Date, Decimal>());
            }
            faToDateBalance.get(fab.FinancialAccountId).put(fab.BalanceAsOfDate.date(), fab.Amount);
        }

        for (Request req : requests) {
            Response res = new Response();
            res.transactions = new List<TransactionWrapper>();

            FinancialAccount matchedFA;
            for (FinancialAccount fa : faList) {
                if (fa.Phone__c != req.phone) continue;

                Boolean typeMatch = (String.isBlank(req.accountType) || fa.Type == req.accountType);
                Boolean numberMatch = true;

                if (!String.isBlank(req.lastDigits) && fa.FinancialAccountNumber != null) {
                    String accNum = fa.FinancialAccountNumber.replaceAll('[^0-9]', '');
                    numberMatch = accNum.endsWith(req.lastDigits);
                }

                if (typeMatch && numberMatch) {
                    matchedFA = fa;
                    break;
                }
            }

            if (matchedFA == null) {
                res.message = 'Account not found. Please verify the phone number and account details.';
                res.accountType = 'Not Found';
                responses.add(res);
                continue;
            }

            res.accountType = matchedFA.Type;

            if (matchedFA.Type == 'Credit Card') {
                res.message = buildCreditCardMessage(matchedFA);
                responses.add(res);
                continue;
            }

            Map<Date, Decimal> dateToBalance = faToDateBalance.get(matchedFA.Id);
            if (dateToBalance != null && !dateToBalance.isEmpty()) {
                List<Date> dateList = new List<Date>(dateToBalance.keySet());
                dateList.sort();
                Date latestDate = dateList[dateList.size() - 1];
                res.latestBalance = '₹' + String.valueOf(dateToBalance.get(latestDate).setScale(2));
            }

            List<FinancialAccountTransaction> txnList = faToTxn.get(matchedFA.Id);
            if (txnList != null && !txnList.isEmpty()) {
                for (FinancialAccountTransaction txn : txnList) {
                    TransactionWrapper tw = new TransactionWrapper();

                    tw.transactionId   = txn.Id;  // Internal use only — not surfaced in message

                    Date txnDate = txn.TransactionDate.date();
                    String day   = String.valueOf(txnDate.day()).leftPad(2, '0');
                    String month = String.valueOf(txnDate.month()).leftPad(2, '0');

                    tw.transactionDate = day + '-' + month + '-' + txnDate.year();
                    tw.description     = txn.Description;
                    tw.amount          = '₹' + String.valueOf(txn.Amount.setScale(2));
                    tw.type            = txn.DebitCreditIndicator;

                    if (dateToBalance != null && dateToBalance.containsKey(txnDate)) {
                        tw.balance = '₹' + String.valueOf(dateToBalance.get(txnDate).setScale(2));
                    } else {
                        tw.balance = 'N/A';
                    }

                    res.transactions.add(tw);
                }
                res.message = buildSavingsMessage(matchedFA, res.latestBalance, res.transactions);
            } else {
                res.message = 'Account Type: ' + matchedFA.Type + '\nCurrent Balance: ' + res.latestBalance + '\n\nNo recent transactions found.';
            }

            responses.add(res);
        }

        return responses;
    }

    private static String buildCreditCardMessage(FinancialAccount fa) {
        Decimal limits      = fa.CreditLimit == null ? 0 : fa.CreditLimit;
        Decimal outstanding = fa.Current_Outstanding__c == null ? 0 : fa.Current_Outstanding__c;
        Decimal available   = fa.Total_Available_Amount__c != null ? fa.Total_Available_Amount__c : (limits - outstanding);

        String msg = 'CREDIT CARD SUMMARY\n\n';
        msg += 'Total Credit Limit: ₹' + String.valueOf(limits.setScale(2)) + '\n';
        msg += 'Available Credit: ₹ '  + String.valueOf(available.setScale(2)) + '\n';
        msg += 'Current Outstanding: ₹ ' + String.valueOf(outstanding.setScale(2)) + '\n';

        if (fa.Billing_Cycle_Date__c == null) {
            msg += '\nNo bill generated yet. Your current usage will be billed after the cycle ends.';
        } else {
            msg += '\n\nBILL DETAILS\n';
            msg += 'Statement Date: '    + String.valueOf(fa.Billing_Cycle_Date__c) + '\n';
            msg += 'Amount Due: ₹ '      + String.valueOf(fa.AmountDue == null ? 0 : fa.AmountDue.setScale(2)) + '\n';
            msg += 'Payment Due Date: '  + String.valueOf(fa.PaymentDueDate) + '\n';

            if (fa.Last_Payment_Amount__c != null) {
                msg += '\nLAST PAYMENT\n';
                msg += 'Amount: ₹ ' + String.valueOf(fa.Last_Payment_Amount__c.setScale(2)) + '\n';
                msg += 'Date: '     + String.valueOf(fa.Last_Payment_Date__c) + '\n';
            }
        }

        return msg;
    }

    private static String buildSavingsMessage(FinancialAccount fa, String balance, List<TransactionWrapper> txns) {
        String msg = 'SAVINGS ACCOUNT STATEMENT\n\n';
        msg += 'Current Balance: ' + balance + '\n';
        msg += '\nRECENT TRANSACTIONS\n\n';

        for (TransactionWrapper txn : txns) {
            msg += txn.transactionDate + ' | ' + txn.type + ' | ' + txn.amount + '\n';
            msg += txn.description + '\n';
            msg += 'Balance: ' + txn.balance + '\n\n';
            // Note: txn.transactionId intentionally excluded from user-facing output
        }

        return msg;
    }
}