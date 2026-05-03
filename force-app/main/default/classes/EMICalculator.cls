public class EMICalculator {
    public class EMIRequest {
        @InvocableVariable(
            label='Loan Id'
            description='Salesforce ID of the specific loan FinancialAccount to calculate EMI options'
            required=true)
        public String loanId;
    }
    
    public class EMIResult {
        @InvocableVariable(
            label='Financial Account Id'
            description='Salesforce ID of customers active home loan record')
        public String financialAccountId;
        
        @InvocableVariable(
            label='Loan Name'
            description='Name of the loan account')
        public String loanName;
        
        @InvocableVariable(
            label='Loan Type'
            description='Type/subtype of the loan')
        public String loanType;
        
        @InvocableVariable(
            label='Current Outstanding'
            description='Current outstanding principal amount')
        public Decimal currentOutstanding;
        
        @InvocableVariable(
            label='Interest Rate'
            description='Annual interest rate percentage')
        public Decimal interestRate;
        
        @InvocableVariable(
            label='Current Tenure Remaining'
            description='Current remaining tenure in months')
        public Integer currentTenureRemaining;
        
        @InvocableVariable(
            label='Old EMI'
            description='Current monthly EMI amount being paid')
        public Decimal oldEMI;
        
        @InvocableVariable(
            label='Old Total Interest'
            description='Total interest user is currently paying over remaining tenure')
        public Decimal oldTotalInterest;
        
        @InvocableVariable(
            label='Old Total Repayment'
            description='Total amount user will pay with current plan')
        public Decimal oldTotalRepayment;
        
        // OPTION A - Extend by 1 Year
        @InvocableVariable(
            label='Option A Old EMI'
            description='Current EMI before restructuring')
        public Decimal optionAOldEMI;
        
        @InvocableVariable(
            label='Option A New EMI'
            description='New EMI if tenure extended by 1 year')
        public Decimal optionAEMI;
        
        @InvocableVariable(
            label='Option A Monthly Savings'
            description='Amount saved per month with Option A')
        public Decimal optionASavings;
        
        @InvocableVariable(
            label='Option A Old Total Interest'
            description='Total interest with current plan')
        public Decimal optionAOldTotalInterest;
        
        @InvocableVariable(
            label='Option A New Total Interest'
            description='Total interest with Option A')
        public Decimal optionATotalInterest;
        
        @InvocableVariable(
            label='Option A Additional Interest'
            description='Additional interest compared to current plan')
        public Decimal optionAAdditionalInterest;
        
        @InvocableVariable(
            label='Option A New Tenure'
            description='New tenure in months for Option A')
        public Integer optionANewTenure;
        
        @InvocableVariable(
            label='Option A New Tenure Years'
            description='New tenure in years for Option A')
        public Decimal optionANewTenureYears;
        
        @InvocableVariable(
            label='Option A Total Repayment'
            description='Total amount to be repaid with Option A')
        public Decimal optionANewOutstanding;
        
        // OPTION B - Extend by 2 Years
        @InvocableVariable(
            label='Option B Old EMI'
            description='Current EMI before restructuring')
        public Decimal optionBOldEMI;
        
        @InvocableVariable(
            label='Option B New EMI'
            description='New EMI if tenure extended by 2 years')
        public Decimal optionBEMI;
        
        @InvocableVariable(
            label='Option B Monthly Savings'
            description='Amount saved per month with Option B')
        public Decimal optionBSavings;
        
        @InvocableVariable(
            label='Option B Old Total Interest'
            description='Total interest with current plan')
        public Decimal optionBOldTotalInterest;
        
        @InvocableVariable(
            label='Option B New Total Interest'
            description='Total interest with Option B')
        public Decimal optionBTotalInterest;
        
        @InvocableVariable(
            label='Option B Additional Interest'
            description='Additional interest compared to current plan')
        public Decimal optionBAdditionalInterest;
        
        @InvocableVariable(
            label='Option B New Tenure'
            description='New tenure in months for Option B')
        public Integer optionBNewTenure;
        
        @InvocableVariable(
            label='Option B New Tenure Years'
            description='New tenure in years for Option B')
        public Decimal optionBNewTenureYears;
        
        @InvocableVariable(
            label='Option B Total Repayment'
            description='Total amount to be repaid with Option B')
        public Decimal optionBNewOutstanding;
        
        // OPTION C - 3 Month Moratorium
        @InvocableVariable(
            label='Option C Old EMI'
            description='Current EMI before restructuring')
        public Decimal optionCOldEMI;
        
        @InvocableVariable(
            label='Option C New EMI'
            description='New EMI after 3 month moratorium')
        public Decimal optionCEMI;
        
        @InvocableVariable(
            label='Option C EMI Increase'
            description='EMI increase amount for Option C')
        public Decimal optionCEMIIncrease;
        
        @InvocableVariable(
            label='Option C Old Total Interest'
            description='Total interest with current plan')
        public Decimal optionCOldTotalInterest;
        
        @InvocableVariable(
            label='Option C New Total Interest'
            description='Total interest with Option C')
        public Decimal optionCNewTotalInterest;
        
        @InvocableVariable(
            label='Option C Additional Interest'
            description='Additional interest compared to current plan')
        public Decimal optionCAdditionalInterest;
        
        @InvocableVariable(
            label='Option C New Outstanding'
            description='New outstanding after 3 month moratorium')
        public Decimal optionCNewOutstanding;
        
        @InvocableVariable(
            label='Option C Interest Added'
            description='Interest amount added to principal during moratorium')
        public Decimal optionCInterestAdded;
        
        @InvocableVariable(
            label='Option C Tenure'
            description='Tenure remains same for Option C')
        public Integer optionCTenure;
        
        @InvocableVariable(
            label='Option C Moratorium Period'
            description='Number of months with no EMI payment')
        public Integer optionCMoratoriumMonths;
        
        @InvocableVariable(
            label='Error Message'
            description='Error if loan not found')
        public String errorMessage;
    }
    
    @InvocableMethod(
        label='Calculate EMI Restructuring Options'
        description='Fetches loan details and calculates 3 EMI restructuring options for the customer.')
    public static List<EMIResult> calculateEMIOptions(List<EMIRequest> requests) {
        List<EMIResult> results = new List<EMIResult>();
        
        String loanId = requests.isEmpty() ? null : requests[0].loanId;
        
        List<FinancialAccount> loans = new List<FinancialAccount>();
        
        if(loanId != null && loanId != '') {
            loans = [
                SELECT Id, Name, Sub_Type__c, TotalOutstandingAmount, 
                       InterestRate, Term, Original_Term__c, EMI_Per_Month__c
                FROM FinancialAccount
                WHERE Id = :loanId
                AND Type = 'Loan'
                AND Status = 'Active'
                LIMIT 1
            ];
        }
        
        for(EMIRequest req : requests) {
            EMIResult result = new EMIResult();
            
            try {
                if(loans.isEmpty()) {
                    result.errorMessage = 'No active loan record found for the given Loan ID';
                    results.add(result);
                    continue;
                }
                
                FinancialAccount loan = loans[0];
                
                // Basic loan details
                result.financialAccountId = loan.Id;
                result.loanName = loan.Name;
                result.loanType = loan.Sub_Type__c != null ? loan.Sub_Type__c : 'Loan';
                result.currentOutstanding = loan.TotalOutstandingAmount;
                result.interestRate = loan.InterestRate;
                
                Decimal principal = loan.TotalOutstandingAmount;
                Decimal annualRate = loan.InterestRate;
                Integer months = loan.Original_Term__c != null 
                    ? Integer.valueOf(loan.Original_Term__c) 
                    : Integer.valueOf(loan.Term);
                
                result.currentTenureRemaining = months;
                
                Decimal monthlyRate = annualRate / 12 / 100;
                
                // Get old EMI from record or calculate it
                Decimal oldEMI = loan.EMI_Per_Month__c != null && loan.EMI_Per_Month__c > 0 
                    ? loan.EMI_Per_Month__c 
                    : calculateEMI(principal, monthlyRate, months);
                
                result.oldEMI = oldEMI;
                
                // Calculate old total interest and repayment
                result.oldTotalRepayment = (oldEMI * months).setScale(2, RoundingMode.HALF_UP);
                result.oldTotalInterest = (result.oldTotalRepayment - principal).setScale(2, RoundingMode.HALF_UP);
                
                // OPTION A: Extend by 1 year (12 months)
                Integer optionAMonths = months + 12;
                result.optionANewTenure = optionAMonths;
                result.optionANewTenureYears = Decimal.valueOf(optionAMonths).divide(12, 1, RoundingMode.HALF_UP);
                
                result.optionAOldEMI = oldEMI;
                result.optionAEMI = calculateEMI(principal, monthlyRate, optionAMonths);
                result.optionASavings = (oldEMI - result.optionAEMI).setScale(2, RoundingMode.HALF_UP);
                
                result.optionANewOutstanding = (result.optionAEMI * optionAMonths).setScale(2, RoundingMode.HALF_UP);
                result.optionAOldTotalInterest = result.oldTotalInterest;
                result.optionATotalInterest = (result.optionANewOutstanding - principal).setScale(2, RoundingMode.HALF_UP);
                result.optionAAdditionalInterest = (result.optionATotalInterest - result.oldTotalInterest).setScale(2, RoundingMode.HALF_UP);
                
                // OPTION B: Extend by 2 years (24 months)
                Integer optionBMonths = months + 24;
                result.optionBNewTenure = optionBMonths;
                result.optionBNewTenureYears = Decimal.valueOf(optionBMonths).divide(12, 1, RoundingMode.HALF_UP);
                
                result.optionBOldEMI = oldEMI;
                result.optionBEMI = calculateEMI(principal, monthlyRate, optionBMonths);
                result.optionBSavings = (oldEMI - result.optionBEMI).setScale(2, RoundingMode.HALF_UP);
                
                result.optionBNewOutstanding = (result.optionBEMI * optionBMonths).setScale(2, RoundingMode.HALF_UP);
                result.optionBOldTotalInterest = result.oldTotalInterest;
                result.optionBTotalInterest = (result.optionBNewOutstanding - principal).setScale(2, RoundingMode.HALF_UP);
                result.optionBAdditionalInterest = (result.optionBTotalInterest - result.oldTotalInterest).setScale(2, RoundingMode.HALF_UP);
                
                // OPTION C: 3 month moratorium (interest added to principal)
                Decimal interest3Months = principal * monthlyRate * 3;
                Decimal newPrincipal = principal + interest3Months;
                
                result.optionCOldEMI = oldEMI;
                result.optionCEMI = calculateEMI(newPrincipal, monthlyRate, months);
                result.optionCEMIIncrease = (result.optionCEMI - oldEMI).setScale(2, RoundingMode.HALF_UP);
                
                result.optionCNewOutstanding = newPrincipal.setScale(2, RoundingMode.HALF_UP);
                result.optionCInterestAdded = interest3Months.setScale(2, RoundingMode.HALF_UP);
                result.optionCTenure = months;
                result.optionCMoratoriumMonths = 3;
                
                Decimal optionCTotalRepayment = (result.optionCEMI * months).setScale(2, RoundingMode.HALF_UP);
                result.optionCOldTotalInterest = result.oldTotalInterest;
                result.optionCNewTotalInterest = (optionCTotalRepayment - principal).setScale(2, RoundingMode.HALF_UP);
                result.optionCAdditionalInterest = (result.optionCNewTotalInterest - result.oldTotalInterest).setScale(2, RoundingMode.HALF_UP);
                
            } catch(Exception e) {
                result.errorMessage = e.getMessage();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    private static Decimal calculateEMI(Decimal principal, Decimal monthlyRate, Integer months) {
        if(monthlyRate == 0) {
            return principal / months;
        }
        Double powerValue = Math.pow((Double)(1 + monthlyRate), (Double)months);
        Decimal emi = principal * monthlyRate * (Decimal)powerValue / ((Decimal)powerValue - 1);
        return emi.setScale(2, RoundingMode.HALF_UP);
    }
}