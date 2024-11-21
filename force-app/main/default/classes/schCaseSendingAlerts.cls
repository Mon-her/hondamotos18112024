//Created by Me, On 20220110
//To send email alerts to users
//tested by CaseTriggerHandler_Test
public class schCaseSendingAlerts implements Schedulable {
    public Id caseId;
    public String recipientEmail;
    public String msg;
    public String subject;
    
    public schCaseSendingAlerts(Id idCaso, String recipiente, String asunto, String mensaje){
        this.caseId = idCaso;
        this.recipientEmail = recipiente;
        this.msg = mensaje;
        this.subject = asunto;
    }
    
    public void execute(SchedulableContext ctx) {
        // Send an email to the specified user
    	Case caso = [select Id, isClosed from Case where Id=:caseId];
        if (caso.isClosed==false){
            sendEmail(recipientEmail,subject, msg);
        }
    }
    
    public static void sendEmail(String recipiente, String asunto, String mensaje){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new String[] { recipiente,'jparrales@fastcloudconsulting.com' }; //new String[] { 'jparrales@fastcloudconsulting.com' };
        message.optOutPolicy = 'FILTER';
        message.subject = asunto;
        message.plainTextBody = mensaje; //+ '<br /> El recipiente era: ' + recipiente;
        message.htmlBody = mensaje; //+ '<br /> El recipiente era: ' + recipiente;
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) 
        {
            System.debug('The email was sent successfully.');
        } else 
        {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
        }
    }
        

}