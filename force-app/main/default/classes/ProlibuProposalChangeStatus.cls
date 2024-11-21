//Made by me, June 2021
public class ProlibuProposalChangeStatus {
    
    @future(callout=true)
    public static void sendOppStatusFuture (Id idOpp,Id idQuote, boolean isWon){
        try{
            ProposalChangeStatusBody quoteEstado = new ProposalChangeStatusBody();
            quoteEstado.id = [select QuoteNumber from Quote where Id=:idQuote limit 1].QuoteNumber;//idQuote;
            quoteEstado.referenceNumber = idOpp;
            quoteEstado.status = isWon ? 'Approved' : 'Denied';
            
            String respuesta = sendThisProposalStatus(quoteEstado);
            system.debug(respuesta);
        }catch(Exception ex){
            Log__c log = new Log__c();
            log.Response__c = ex.getMessage();
            log.Web_Service__c = 'ProlibuProposalChangeStatus';
            insert log;
        }
    }
    
    /*
    @future(callout=true)
    public static void sendAllProposalStatusFuture(Id idOpp){
        sendAllProposalStatus(idOpp);
    }
    public static void sendAllProposalStatus (Id idOpp){
        //Enviar todas las cotizaciones, una por una a Prolibu
        for (Quote q: [select Id, Opportunity.StageName,OpportunityId, Opportunity.isClosed, Opportunity.isWon, IsSyncing from Quote where OpportunityId=:idOpp and Opportunity.isClosed=true and Creado_Prolibu__c=true]){
            ProposalChangeStatusBody quoteEstado = new ProposalChangeStatusBody();
            quoteEstado.id = q.Id;
            quoteEstado.referenceNumber = q.OpportunityId;
            
            //if (q.Opportunity.isWon) quoteEstado.status = 'Approved';
            //else quoteEstado.status = 'Denied';
            
            if (q.IsSyncing && q.Opportunity.isWon) quoteEstado.status = 'Approved';
            else quoteEstado.status = 'Denied';
            
			String respuesta = sendThisProposalStatus(quoteEstado);
            system.debug(respuesta);
        }
    }
    
	*/
    //Envía una Propostal Status to Prolibu
    public static String sendThisProposalStatus (ProposalChangeStatusBody quote){
        try{
            // HTTP Request
            HttpRequest req = new HttpRequest();
            // Callout extended by /changeStatus
            req.setEndpoint('callout:Prolibu/changeStatus');
            req.setMethod('PUT');
            req.setTimeout(120000);  
            req.setHeader('Content-Type', 'application/json');
            // Authentication
            req.setHeader('Authorization', 'Bearer {!$Credential.Password}');
            req.setBody(JSON.serialize(quote));
            // send request
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Cuerpo de la respuesta...' + res.getBody());
            system.debug('El codigo de respuesta es:'+res.getStatusCode());
            
            Log__c log = new Log__c();
            log.Body__c = req.getBody();
            log.Response__c =res.getBody();
            log.Web_Service__c = 'ProlibuProposalChangeStatus';
            insert log;
            
            return res.getBody();
        }catch(Exception ex){
            return ex.getMessage();
        }
       
    }
    
    //Class to use to serialize it and send to prolibu
    public class ProposalChangeStatusBody {
        public String id;
        public string referenceNumber;
        public String status;
    }
    
    //public static ProposalChangeStatusBody parse(String json) {
    //    return (ProposalChangeStatusBody) System.JSON.deserialize(json, ProposalChangeStatusBody.class);
    //}
    
}