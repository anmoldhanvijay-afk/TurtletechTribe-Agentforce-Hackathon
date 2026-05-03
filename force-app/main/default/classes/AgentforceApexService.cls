/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : AgentforceApexService
 * Author          : Anmol Dhanvijay
 * Created Date    : Apr 15, 2026
 * Last Modified By: Anmol Dhanvijay
 * Last Modified On: Apr 15, 2026
 * Description     : Used to invoke agent from apex and handle response.
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Apr 15, 2026  │ Anmol Dhanvijay   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public class AgentforceApexService {

    public class AgentResponse {
        public String reply;
        public String sessionId;
    }

    public static AgentResponse callAgent(
        String userMessage,
        String agentApiName,
        String sessionId,
        String caseId,
        String fromNumber
    ) {

        AgentResponse agentResponse = new AgentResponse();

        try {

            

             String cleanedNumber;          
            if (String.isNotBlank(sessionId)) {
                cleanedNumber = SessionManager.getPhoneBySession(sessionId);
            }

            
            if (String.isBlank(cleanedNumber)) {
                cleanedNumber = normalizePhoneE164(fromNumber);
            }

            Invocable.Action action = Invocable.Action.createCustomAction(
                'generateAiAgentResponse',
                agentApiName
            );

            
            action.setInvocationParameter('userMessage', userMessage);

            
            if (String.isNotBlank(sessionId)) {
                action.setInvocationParameter('sessionId', sessionId);
            }

            
                action.setInvocationParameter('whatsappMobNumber', cleanedNumber);
                //action.setInvocationParameter('phone', cleanedNumber);
            

            
            if (String.isNotBlank(caseId)) {
                action.setInvocationParameter('caseId', caseId);
            }

            List<Invocable.Action.Result> results = action.invoke();

            if (results == null || results.isEmpty()) {
                agentResponse.reply = 'No response from agent';
                return agentResponse;
            }

            Invocable.Action.Result result = results[0];

            if (!result.isSuccess()) {
                System.debug('Agent Error: ' + result.getErrors());
                agentResponse.reply = 'Sorry, something went wrong. Please try again.';
                return agentResponse;
            }

            Map<String, Object> output = result.getOutputParameters();
           
            if (output == null || output.isEmpty()) {
                agentResponse.reply = 'Agent response not found';
                return agentResponse;
            }

            //  SESSION HANDLING (CRITICAL)
            if (output.containsKey('sessionId') && output.get('sessionId') != null) {
                agentResponse.sessionId = (String) output.get('sessionId');
            } else {
                // fallback to previous session
                agentResponse.sessionId = sessionId;
            }

            System.debug('Returned SessionId: ' + agentResponse.sessionId);

            //  RESPONSE HANDLING
            String rawReply = (String) output.get('agentResponse');

            if (String.isBlank(rawReply)) {
                agentResponse.reply = 'Sorry, I could not understand that.';
                return agentResponse;
            }

            rawReply = rawReply.trim();

            // Handle JSON formatted responses
            if (rawReply.startsWith('{')) {
                try {
                    Map<String, Object> parsed =
                        (Map<String, Object>) JSON.deserializeUntyped(rawReply);

                    if (parsed.containsKey('value')) {
                        rawReply = (String) parsed.get('value');
                    }
                } catch (Exception e) {
                    System.debug('JSON parsing failed: ' + e.getMessage());
                }
            }

            agentResponse.reply = rawReply;

        } catch (Exception e) {
            System.debug('Agent call failed: ' + e.getMessage());
            agentResponse.reply = 'Unexpected error occurred.';
        }

        return agentResponse;
    }

    
    public static String normalizePhoneE164(String fromNumber) {

    if (String.isBlank(fromNumber)) return null;

    
    if (fromNumber.equalsIgnoreCase('null')) return null;

    
    fromNumber = fromNumber.replaceAll('(?i)whatsapp:', '').trim();

    if (String.isBlank(fromNumber)) return null;

    
    String cleaned;
    if (fromNumber.startsWith('+')) {
        cleaned = '+' + fromNumber.substring(1).replaceAll('[^0-9]', '');
        } else {
            cleaned = fromNumber.replaceAll('[^0-9]', '');
            if (String.isNotBlank(cleaned)) {
                cleaned = '+' + cleaned;
            }
        }

        if (String.isBlank(cleaned) || cleaned == '+') return null;

        
        if (!Pattern.matches('\\+[1-9][0-9]{6,14}', cleaned)) {
            
            return null; 
        }

       
        return cleaned;
    }

}