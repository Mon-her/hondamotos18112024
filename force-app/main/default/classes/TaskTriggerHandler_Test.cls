@isTest
public class TaskTriggerHandler_Test {
  @TestSetup
  static void makeData() {
  /*  List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account account = accounts[0];
*/
    //List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    // Opportunity opp = opps[0];

    // RecordType recordTypeOppMoto = [
    //   SELECT Id, DeveloperName
    //   FROM RecordType
    //   WHERE DeveloperName = :Label.RTOportunidadMotos
    // ];
    // Opportunity opportunity = new Opportunity();
    // opportunity.Name = 'Test Opportunity 1';
    // opportunity.AccountId = account.Id;
    // opportunity.Tipo_de_cliente__c = 'Cliente Honda';
    // opportunity.CloseDate = System.today();
    // opportunity.Tipo_de_Pago__c = '101 - Contado';
    // opportunity.Temperatura_de_la_Compra__c = 'Media';
    // opportunity.StageName = '-P0';
    // opportunity.RecordTypeId = recordTypeOppMoto.Id;
    // insert opportunity;
  }

  @isTest
  static void taskTriggerHandler() {
    Profile p = [SELECT Id FROM Profile WHERE Name='Gerente de ventas (Motos)']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Integraciones', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.fanalcaSandbox');
    
      System.runAs(u)  {
        List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
              Label.MotosRecordTypeDevNameAccountNatural,
              1
            );
        Account account = accounts[0];
        List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
/*
        Opportunity opportunity = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Task task = new Task();
        task.Description = 'Task description 1';
        task.WhatId = opportunity.Id;
        task.Status = 'Programada';
        task.Priority = 'Normal';
        task.ActivityDate = System.today();
    
        insert task;
    
        task.Description = 'Task description 2';
        update task;
*/
          Task task = [select Id from task where WhatId=:opps[0].Id];
              task.Description = 'Task description 2';
              update task;
      }
    
  }
}