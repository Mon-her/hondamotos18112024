/**
 * Fanalca
 * @author           Juan Ansaldi
 * Description:      Test class para DatosReporteForecastVentas
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     20/01/2021      Juan Ansaldi            Class definition.
 *********************************************************************************************************/
@isTest
private class DatosReporteForecastVentas_Test {
    public static User u; 
    public static User u1; 
    public static User u2; 
    
    public static void dataMethod() {
    
    Account account = new Account();
    Id recordTypeAccountPersonaJuridicaMoto = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Persona Juridica').getRecordTypeId();
    account.RecordTypeId = recordTypeAccountPersonaJuridicaMoto;
    //account.salutation = 'Sr.';
    account.AccountSource = 'Web';
    account.BillingCountry = 'Nicaragua';
    account.BillingStreet = 'Billing st';
    account.Phone = '8572434';
    account.AM_Numero_de_documento__c = '259741510';
    account.AM_Tipo_de_documento__c = 'NIT';
    account.Name = 'Empresa1';
    account.MC_Correo_electronico_Empresa__c = 'email1@email.com';
    insert account;
    
    User thisUser = [ select Id from User where Id = :UserInfo.getUserId()]; 

    System.runAs ( thisUser ) { 
        Contact userContact = new Contact(
            AccountId = account.Id,
            FirstName = 'Test',
            Lastname = 'McTesty',
            Email = System.now().millisecond() + 'test@test.com'
        );
        insert userContact;
		String orgId = UserInfo.getOrganizationId();   
        List<Profile> lstProfiles = [Select Id, name from Profile where name in ('Gerente de ventas (Motos)','Asesores motos','Integraciones')];
        Profile p1,p2,p; 
        for(Profile pItem: lstProfiles){
            if(pItem.name == 'Gerente de ventas (Motos)'){
                p1 = pItem;
            }
            if(pItem.name == 'Integraciones'){
                p2 = pItem;
            }
            if(pItem.name == 'Asesores motos'){
                p = pItem;
            }
        }
        u1 = new User(alias = 'standt', email='standarduser123@testorg123456.com', emailencodingkey='UTF-8', lastname='Testing1', 
                     languagelocalekey='en_US', localesidkey='en_US', profileid = p1.Id,
                     timezonesidkey='America/Los_Angeles', username='uniqueUser@'+ orgId + 'test.com', managerId=thisUser.Id);
        insert u1;
        
        u = new User(alias = 'standt', email='standarduser@testorg123456.com', emailencodingkey='UTF-8', lastname='Testing', 
                     languagelocalekey='en_US', localesidkey='en_US', profileid = p.Id,
                     timezonesidkey='America/Los_Angeles', username='unique@'+ orgId + 'test.com', contactId=userContact.Id, managerId=u1.Id);
        insert u;
        
        u2 = new User(alias = 'standt', email='standarduser@testorg1234567.com', emailencodingkey='UTF-8', lastname='Testing', 
                     languagelocalekey='en_US', localesidkey='en_US', profileid = p2.Id,
                     timezonesidkey='America/Los_Angeles', username='unique77@'+ orgId + 'test.com');
        insert u2;
    }
    
    String hoy = String.valueOf(date.today());
    String traerAnio = hoy.left(4);
    String traerMes = '';
	switch on hoy.left(7).right(2) {
      when '01' {
        traerMes = 'Enero';
      }
      when '02' {
        traerMes = 'Febrero';
      }
      when '03' {
        traerMes = 'Marzo';
      }
      when '04' {
        traerMes = 'Abril';
      }
      when '05' {
        traerMes = 'Mayo';
      }
      when '06' {
        traerMes = 'Junio';
      }
      when '07' {
        traerMes = 'Julio';
      }
      when '08' {
        traerMes = 'Agosto';
      }
      when '09' {
        traerMes = 'Septiembre';
      }
      when '10' {
        traerMes = 'Octubre';
      }
      when '11' {
        traerMes = 'Noviembre';
      }
      when '12' {
        traerMes = 'Diciembre';
      }
    }      
      System.runAs ( u ) {
          Opportunity opportunity = new Opportunity(
              AccountId = account.Id,
              Tipo_de_cliente__c = 'Cliente Honda',
              Temperatura_de_la_Compra__c = 'Media',
              StageName = '-P0',
              CloseDate = System.today(),
              Amount = 1.1,
              OwnerId = u.Id,
              Name = 'test value'
          );
          insert opportunity;
          Meta_de_Venta__c m = new Meta_de_Venta__c();
          m.Mes__c = traerMes;
          m.Anio__c = traerAnio;
          m.Asesor__c = u.Id;
          m.Cuota__c = 10;
          insert m;
      }
        System.runAs ( u1 ) {
          Opportunity opportunity = new Opportunity(
              AccountId = account.Id,
              Tipo_de_cliente__c = 'Cliente Honda',
              Temperatura_de_la_Compra__c = 'Media',
              StageName = '-P0',
              CloseDate = System.today(),
              Amount = 1.1,
              OwnerId = u1.Id,
              Name = 'test'
          );
            insert opportunity;
            Meta_de_Venta__c m1 = new Meta_de_Venta__c();
            m1.Mes__c = traerMes;
            m1.Anio__c = traerAnio;
            m1.Asesor__c = u1.Id;
            m1.Cuota__c = 10;
            insert m1;
      }
        System.runAs(u2) {
            List<Opportunity> lstOppty = [select Id from Opportunity];
            List<Opportunity> lstOpptyNew = New List<Opportunity>();
            for (Opportunity opp : lstOppty) {
                opp.StageName = 'Vendida';
                lstOpptyNew.add(opp);
            }
            update lstOpptyNew;
        }
}
    
	@isTest
    static void getDatosForecastOportunidades() {
        
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('CuentaTriggerHandler');
        
        RM_AccountTriggerHandler_cls.blnFirstRun=false;
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        dataMethod();
        test.startTest();
      System.runAs ( u1 ) {
          DatosReporteForecastVentas instance = new DatosReporteForecastVentas();
          List<Decimal> output = instance.output;

      }
      System.runAs ( u ) {
          DatosReporteForecastVentas instance = new DatosReporteForecastVentas();
          List<Decimal> output = instance.output;
      }
        System.runAs ( u1 ) {
            Meta_de_Venta__c m1 = [select Id, Asesor__c, Cuota__c from Meta_de_Venta__c where Asesor__c =:u1.Id];
            m1.Asesor__c = u1.Id;
            m1.Cuota__c = null;
            update m1;
          DatosReporteForecastVentas instance = new DatosReporteForecastVentas();
          List<Decimal> output = instance.output;
      }  
        test.stopTest();
  }
}