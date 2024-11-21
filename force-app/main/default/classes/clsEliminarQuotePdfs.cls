public class clsEliminarQuotePdfs implements Database.Batchable<sObject>{
 //call this way: Id batchInstanceId = Database.executeBatch(new clsEliminarQuotePdfs());
    public final datetime startTime;
    public clsEliminarQuotePdfs(){
        startTime=system.now();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'select Id from QuoteDocument where CreatedDate != LAST_N_DAYS:' + Label.BatchEliminarQuotePdfNDays;//THIS_MONTH';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
        	delete scope;    
        }catch(Exception e) {
            System.debug(e);
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
        system.debug('The Process Started at ' + startTime + ' finished at ' + system.now());
        
        //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        AsyncApexJob a = [SELECT Id, Status, CompletedDate,NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id=:BC.getJobId()];
        if(a.Status=='Failed'){system.abortJob(a.Id);}
        
        system.debug('Job: ' + a);
        //string email=Label.EmailReceiverQuoteHistoryMessages;
        
        //mail.setToAddresses(new String[] {email});
        
        //mail.setReplyTo(Label.EmailReceiverQuoteHistoryMessages);
        //mail.setSenderDisplayName('Delete of Quote Pdfs ');
        //mail.setSubject('Delete of Quote Pdfs.');
        //mail.setHtmlBody('<b> The job that deletes Quote Pdfs has finished. </b><br/><b> Batches processed : </b> ' + a.JobItemsProcessed + ' . <br/><b>Errors : </b> ' + a.NumberOfErrors + '. <br/><b>Start Time : </b>' + startTime + '. <br/><b>End Time : </d> '+ a.CompletedDate +'');
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
        
    }
}