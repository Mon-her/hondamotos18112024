public class GTAO_ResetSendERPorder implements Database.Batchable<sObject>{

   public final String query = ' SELECT Id,GTAO_PedidoEnviadoSAP__c FROM Opportunity WHERE GTAO_PedidoEnviadoSAP__c = true ';

   public Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }

   public void execute(Database.BatchableContext BC, List<sObject> scope){
    list< Opportunity > lstOpp = scope;
     for(Opportunity opp : lstOpp ){
         opp.GTAO_PedidoEnviadoSAP__c = false; 
     }
     update lstOpp ;
    }

   public void finish(Database.BatchableContext BC){
   }
}