@isTest
public class ProlibuProposalMetricsBatch_Test {
	public static testmethod void testear(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
    	Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearOportunidadAutos(1);
        TestDataUtilityClass.crearQuoteAutos(1);
        
                
        Quote q= TestDataUtilityClass.mapQuotesAutos.get(1);
        q.Creado_Prolibu__c = true;
        update q;
        
        
        Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
               
        Test.startTest();
        opp.SyncedQuoteId = q.Id;
        update opp;
        TEst.stopTest();
        test.setMock(HttpCalloutMock.class, new ProlibuProposalMetrics_Mock(1));
        //ProlibuProposalMetrics.getProposalMetricsFuture();
  		ProlibuProposalMetricsBatch batchable = new ProlibuProposalMetricsBatch();
		Database.executebatch(batchable, 200);   

    }
    
    public static testmethod void testearNoQuotes(){
        test.setMock(HttpCalloutMock.class, new ProlibuProposalMetrics_Mock(1));
        //ProlibuProposalMetrics.getProposalMetrics();
        ProlibuProposalMetricsBatch batchable = new ProlibuProposalMetricsBatch();
		Database.executebatch(batchable, 200);   
    }
    
    
    public static testmethod void testearError300(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
    	Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearOportunidadAutos(1);
        TestDataUtilityClass.crearQuoteAutos(1);
        
                
        Quote q= TestDataUtilityClass.mapQuotesAutos.get(1);
        q.Creado_Prolibu__c = true;
        update q;
        
        
        Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
            
        Test.startTest();
        opp.SyncedQuoteId = q.Id;
        update opp;
        TEst.stopTest();
        
        test.setMock(HttpCalloutMock.class, new ProlibuProposalMetrics_Mock(2300));
        //ProlibuProposalMetrics.getProposalMetrics();
        ProlibuProposalMetricsBatch batchable = new ProlibuProposalMetricsBatch();
		Database.executebatch(batchable, 200);   
    }
    
    public static testmethod void testearError400(){
        try {
            Triggerhandler.bypass('OpportunityTriggerHandler');
            Triggerhandler.bypass('QuoteTriggerHandler');
            Triggerhandler.bypass('AccountTriggerHandler');
            Triggerhandler.bypass('TaskTriggerHandler');
            
            TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
            TestDataUtilityClass.crearConcesionarios(1);
            TestDataUtilityClass.crearMiembroConcesionarios(1);
            TestDataUtilityClass.crearOportunidadAutos(1);
            TestDataUtilityClass.crearQuoteAutos(1);
            
                    
            Quote q= TestDataUtilityClass.mapQuotesAutos.get(1);
            q.Creado_Prolibu__c = true;
            update q;
            
            
            Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
                
            Test.startTest();
            opp.SyncedQuoteId = q.Id;
            update opp;
            TEst.stopTest();
            
            test.setMock(HttpCalloutMock.class, new ProlibuProposalMetrics_Mock(2));
            //ProlibuProposalMetrics.getProposalMetrics();
            ProlibuProposalMetricsBatch batchable = new ProlibuProposalMetricsBatch();
            Database.executebatch(batchable, 200); 
        }catch (Exception ex){
            system.debug(ex.getMessage());
        }
          
    }
    
    
    public static testmethod void testearErrorCallout(){
        try {
            Triggerhandler.bypass('OpportunityTriggerHandler');
            Triggerhandler.bypass('QuoteTriggerHandler');
            Triggerhandler.bypass('AccountTriggerHandler');
            Triggerhandler.bypass('TaskTriggerHandler');
            
            TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
            TestDataUtilityClass.crearConcesionarios(1);
            TestDataUtilityClass.crearMiembroConcesionarios(1);
            TestDataUtilityClass.crearOportunidadAutos(1);
            TestDataUtilityClass.crearQuoteAutos(1);
            
                    
            Quote q= TestDataUtilityClass.mapQuotesAutos.get(1);
            q.Creado_Prolibu__c = true;
            update q;
            
            
            Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
            
            Test.startTest();
            opp.SyncedQuoteId = q.Id;
            update opp;
            TEst.stopTest();
            
            test.setMock(HttpCalloutMock.class, new ProlibuProposalMetrics_Mock(3));
            //ProlibuProposalMetrics.getProposalMetrics();
            ProlibuProposalMetricsBatch batchable = new ProlibuProposalMetricsBatch();
            Database.executebatch(batchable, 200);   
        }catch (Exception ex){
            system.debug(ex.getMessage());
        }
        
    }
    
    
}