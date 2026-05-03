public class ConfirmLoanRestructuringInvoker {

    public class Request {

        @InvocableVariable
        public String financialAccountId;

        @InvocableVariable
        public String selectedOption;

        @InvocableVariable
        public Decimal optionAEMI;

        @InvocableVariable
        public Decimal optionBEMI;

        @InvocableVariable
        public Decimal optionCEMI;

        @InvocableVariable
        public Decimal optionANewOutstanding;

        @InvocableVariable
        public Decimal optionBNewOutstanding;

        @InvocableVariable
        public Decimal optionCNewOutstanding;
    }

   
    public class Response {

        @InvocableVariable
        public String caseNumber;

        @InvocableVariable
        public Decimal newEMI;

        @InvocableVariable
        public String selectedOption;

        @InvocableVariable
        public String message;
    }

   
    @InvocableMethod(label='Confirm Loan Restructurings')
    public static List<Response> process(List<Request> requests) {

        List<Response> responses = new List<Response>();

       
        Set<String> faIds = new Set<String>();
        for (Request req : requests) {
            if (req.financialAccountId != null) {
                faIds.add(req.financialAccountId);
            }
        }

        
        Map<String, FinancialAccountParty> faToPartyMap = new Map<String, FinancialAccountParty>();

        for (FinancialAccountParty fap : [
            SELECT FinancialAccountId, AccountId
            FROM FinancialAccountParty
            WHERE FinancialAccountId IN :faIds
        ]) {
            faToPartyMap.put(fap.FinancialAccountId, fap);
        }

        
        Set<Id> accountIds = new Set<Id>();
        for (FinancialAccountParty fap : faToPartyMap.values()) {
            if (fap.AccountId != null) {
                accountIds.add(fap.AccountId);
            }
        }

        
        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Name, Relationship_Manager__c FROM Account WHERE Id IN :accountIds]
        );

        
        List<Case> casesToInsert = new List<Case>();
        Map<Integer, Decimal> indexToEMI = new Map<Integer, Decimal>();
        Map<Integer, String> indexToOption = new Map<Integer, String>();
        Map<Integer, Id> indexToAccountId = new Map<Integer, Id>();

        Integer i = 0;

        for (Request req : requests) {

            FinancialAccountParty fap = faToPartyMap.get(req.financialAccountId);
            if (fap == null) continue;

            Account acc = accountMap.get(fap.AccountId);
            if (acc == null) continue;

            Decimal finalEMI;
            Decimal finalOutstanding;
            String optionDesc;

            if (req.selectedOption == 'A') {
                finalEMI = req.optionAEMI;
                finalOutstanding = req.optionANewOutstanding;
                optionDesc = 'Tenure Increased by 1 Year';
            } else if (req.selectedOption == 'B') {
                finalEMI = req.optionBEMI;
                finalOutstanding = req.optionBNewOutstanding;
                optionDesc = 'Tenure Increased by 2 Years';
            } else {
                finalEMI = req.optionCEMI;
                finalOutstanding = req.optionCNewOutstanding;
                optionDesc = '3 Month Moratorium Applied';
            }

            Case c = new Case(
                AccountId = acc.Id,
                Status = 'New',
                Origin = 'WhatsApp',
                Priority = 'High',
                Financial_Account__c = req.financialAccountId,
                Selected_Option__c = req.selectedOption,
                New_EMI__c = finalEMI,
                New_Outstanding_Amount__c = finalOutstanding,
                Subject = 'Loan Restructuring Request - ' + optionDesc,
                Description = 'Customer requested restructuring. ' + optionDesc +
                              '. New EMI: ' + finalEMI
            );

            casesToInsert.add(c);

            indexToEMI.put(i, finalEMI);
            indexToOption.put(i, req.selectedOption);
            indexToAccountId.put(i, acc.Id);

            i++;
        }

        
        insert casesToInsert;

        
        List<Task> tasksToInsert = new List<Task>();

        for (Integer idx = 0; idx < casesToInsert.size(); idx++) {

            Case c = casesToInsert[idx];
            Account acc = accountMap.get(indexToAccountId.get(idx));

            Task t = new Task(
                WhatId = c.Id,
                OwnerId = acc.Relationship_Manager__c,
                Subject = 'RM Callback - Loan Restructuring',
                Status = 'Not Started',
                Priority = 'High',
                ActivityDate = Date.today()
            );

            tasksToInsert.add(t);
        }

        insert tasksToInsert;

       
        for (Integer idx = 0; idx < casesToInsert.size(); idx++) {

            Case c = casesToInsert[idx];

            Response res = new Response();
            res.caseNumber = c.CaseNumber;
            res.newEMI = indexToEMI.get(idx);
            res.selectedOption = indexToOption.get(idx);
            res.message = 'Loan restructuring request submitted successfully';

            responses.add(res);
        }

        return responses;
    }
}