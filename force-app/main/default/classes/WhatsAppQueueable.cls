/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : WhatsAppQueueable
 * Author          : Anmol Dhanvijay//  * Last Modified By: Anmol Dhanvijay
 * Created Date    : Apr 14, 2026
 * Last Modified By: Anmol Dhanvijay
 * Last Modified On: Apr 14, 2026
 * Description     : This class implements for to create case
 * When user upload any file from whatsapp
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 14, 2026  │Anmol Dhanvijay   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class WhatsAppQueueable implements Queueable, Database.AllowsCallouts {

    private String userMessage;
    private String agentApiName;
    private String sessionId;
    private String caseId;
    private String fromNumber;

    public WhatsAppQueueable(String userMessage, String agentApiName, String sessionId, String caseId, String fromNumber) {
        this.userMessage = userMessage;
        this.agentApiName = agentApiName;
        this.sessionId = sessionId;
        this.caseId = caseId;
        this.fromNumber = '+917008850654';
    }

    public void execute(QueueableContext context) {

        try {
            
            
            String cleanPhone = fromNumber != null
                ? fromNumber.replace('whatsapp:', '')
                : null;

            
            WhatsApp_Session__c session = [
                SELECT Id, Transaction_Id__c, Amount__c
                FROM WhatsApp_Session__c
                WHERE Phone__c = :fromNumber
                AND Is_Active__c = true
                LIMIT 1
            ];

            String transactionId = session.Transaction_Id__c;
            Decimal amount = session.Amount__c;

            
            AgentforceApexService.AgentResponse response =
                AgentforceApexService.callAgent(
                    userMessage,
                    agentApiName,
                    sessionId,
                    caseId,
                    fromNumber
                );
			
            if (response == null) {
                System.debug('Agent response is null');
                return;
            }

            
            
            if (caseId != null) {

                Case c = new Case(
                    Id = caseId,
                    SuppliedPhone = fromNumber,
                    CurrencyIsoCode = 'INR'
                );

                
                if (transactionId != null) {
                    c.Financial_Account_Transaction__c = transactionId;
                }

                if (amount != null) {
                    c.Disputed_Amount__c = amount;
                }

              
                if (String.isNotBlank(response.reply)) {
                    c.Description = 'Agent Response:\n' + response.reply;
                }

                update c;

               

            } else {
                
            }

        } catch (Exception e) {
            System.debug('Queueable Error: ' + e.getMessage());
        }
    }
}