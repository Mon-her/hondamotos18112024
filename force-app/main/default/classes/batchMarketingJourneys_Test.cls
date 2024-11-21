@isTest
public class batchMarketingJourneys_Test {
    private static testmethod void testear(){
        Triggerhandler.bypass('AccountTriggerHandler');
      	Triggerhandler.bypass('TaskTriggerHandler');
        
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearOportunidadAutos(1); //Se crea en P3
        //system.debug([select Id,StageName,RecordType.Name from Opportunity]);
        
        Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 2';
      op.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
      op.Tipo_de_cliente__c = 'Cliente Honda';
      op.CloseDate = system.today();
      op.Tipo_de_Pago__c = '101';
      op.Temperatura_de_la_Compra__c = 'Media';
      op.StageName = 'P1';
      op.RecordTypeId =  Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Oportunidad Autos').getRecordTypeId();
      op.CloseDate = Date.newInstance(2010, 12, 30);
      op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
      op.Fecha_de_validez__c = Date.today() + 10;
      op.Tipo_de_Pago__c = '101';
      op.OwnerId = Userinfo.getUserId();
      op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
      op.Averigu_sobre_otras_marcas__c = 'No';
      op.Tipo_de_cliente__c = 'Cliente Honda';
      op.Temperatura_de_la_Compra__c = 'Media';
      op.Amount = 1.1;
      op.Tipo_de_Oportunidad__c = 'Nuevos';
      op.Order_Generated__c = false;
      op.Concesionario__c = TestDataUtilityClass.mapConcesionarios.get(1).Id;
      op.AutoNumber__c = '1232';
        insert op;
        
        //opp.StageName='P4';
        //update opp; it's not necessary because I must create manually the opportunityfieldhistory
        
        OpportunityFieldHistory ofh = new OpportunityFieldHistory(Field='StageName',OpportunityId=opp.Id);
        insert ofh;
        
        OpportunityFieldHistory ofh2 = new OpportunityFieldHistory(Field='StageName',OpportunityId=op.Id);
        insert ofh2;
        
        //system.debug([select Id,StageName,RecordType.Name from Opportunity]);
        //system.debug([select OpportunityId,CreatedDate,Field,oldValue,NewValue from OpportunityFieldHistory]);
        
        Test.startTest();
        
        batchMarketingJourneys batchable = new batchMarketingJourneys();
		Database.executebatch(batchable);  
        
        Test.stopTest();
        
        batchMarketingJourneys batchable2 = new batchMarketingJourneys();
		Database.executebatch(batchable2);
    }
}