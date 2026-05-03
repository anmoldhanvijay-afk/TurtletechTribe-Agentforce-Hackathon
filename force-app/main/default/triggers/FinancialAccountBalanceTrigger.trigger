trigger FinancialAccountBalanceTrigger on FinancialAccountBalance(after insert) {
	
	if (Trigger.isAfter && Trigger.isInsert) {
		map<Id, Decimal> mapParentId  = new map<Id, Decimal>();
		List<FinancialAccount> faListToUpdate = new List<FinancialAccount> ();
       for(FinancialAccountBalance fab : trigger.new){
		if(fab.Type == 'Available Balance' && fab.Amount > 0 && fab.FinancialAccountId != null){
			mapParentId.put(fab.FinancialAccountId, fab.Amount);
		}
	   }

	   if(!mapParentId.isEmpty()){
			for(FinancialAccount faList : [Select Id, Total_Available_Amount__c, type, TotalOutstandingAmount from FinancialAccount WHERE Id IN: mapParentId.KeySet() ] ){
				
				Decimal newAmount        = mapParentId.get(faList.Id) != null ? mapParentId.get(faList.Id) : 0;
    			Decimal currentAvailable = faList.Total_Available_Amount__c != null ? faList.Total_Available_Amount__c : 0;

				if (faList.Type == 'Credit Card') {
					faList.TotalOutstandingAmount    = faList.TotalOutstandingAmount = (faList.TotalOutstandingAmount != null ? faList.TotalOutstandingAmount : 0) 
                                + (currentAvailable - newAmount);
					faList.Total_Available_Amount__c = newAmount;
					faListToUpdate.add(faList);
				}
				else if(faList.type == 'Savings'){
					faList.Total_Available_Amount__c = mapParentId.get(faList.Id);
                	faListToUpdate.add(faList);
				}
				
			} 
	   }

	   if (!faListToUpdate.isEmpty()) {
                update faListToUpdate;
            }	
    }
}