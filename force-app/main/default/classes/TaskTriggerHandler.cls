/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Trigger handler class that checks for outdated email of phone number in task related account or opportunity
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/07/2020      Olvin Abarca            Class definition.
 * @version  1.1     12/16/2020      Olvin Abarca            Fix data loader DML limit exception
 * @version  1.2     July/2021       Jonathan Parrales       do not allow create another open task in lead, account, opportunity
 *********************************************************************************************************/
public class TaskTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    checkAccountOutdatedFields(Trigger.new);
      
      //check if are there any open task related to a lead
      String leadPrefix = Schema.SObjectType.Lead.getKeyPrefix();
      String accountPrefix = Schema.SObjectType.Lead.getKeyPrefix();
      String opportunityPrefix = Schema.SObjectType.Lead.getKeyPrefix();
      set<Id> setIdsLeads = new set<Id>();
      set<Id> setIdsAcounts = new set<Id>();
      set<Id> setIdsOpportunities = new set<Id>();
      RecordType rtAutos = [select Id, DeveloperName from RecordType where DeveloperName='Tareas_Autos'];
      
      for (Task tarea: (list<Task>) Trigger.new){
		if (tarea.RecordTypeId == rtAutos.Id && !tarea.IsClosed && tarea.WhoId!=null && tarea.WhoId.getSObjectType() == Lead.sObjectType) setIdsLeads.add(tarea.WhoId); //get the Ids of Leads related to the new tasks
        if (tarea.RecordTypeId == rtAutos.Id && !tarea.IsClosed && tarea.WhatId!=null && tarea.WhatId.getSObjectType() == Account.sObjectType) setIdsAcounts.add(tarea.WhatId); //get the Ids of Accounts related to the new tasks
        if (tarea.RecordTypeId == rtAutos.Id && !tarea.IsClosed && tarea.WhatId!=null && tarea.WhatId.getSObjectType() == Opportunity.sObjectType) setIdsOpportunities.add(tarea.WhatId); //get the Ids of Opportunities related to the new tasks
      }
      
      list<Task> lstTasks = [select Id, whatId, WhoId from task where isClosed=false and (whoId in:setIdsLeads or whatId in:setIdsAcounts or whatId in:setIdsOpportunities) ];
      set<Id> setIdsLeadsAccountsOppsWithOpenTask = new set<Id>();
      for (Task t: lstTasks){
          if (t.whoId!=null) setIdsLeadsAccountsOppsWithOpenTask.add(t.WhoId);
          if (t.whatId!=null) setIdsLeadsAccountsOppsWithOpenTask.add(t.WhatId);
      }
      
      for (Task tarea: (list<Task>) Trigger.new){
          if (setIdsLeadsAccountsOppsWithOpenTask.contains(tarea.whatId) || setIdsLeadsAccountsOppsWithOpenTask.contains(tarea.whoId)) tarea.adderror('Ya existe una tarea Abierta para el registro relacionado de Cuenta/Lead/Oportunidad');
      }
      /*
      if (setIdsLeads.size()>0){
          set<Id> setIdsLeadsConOpenTask = new set<Id>();
          for (Lead l: [select Id, (select Id from Tasks where IsClosed=false limit 1) from Lead where Id in:setIdsLeads]){
              if (l.Tasks.size()>0) setIdsLeadsConOpenTask.add(l.Id);
          }
          for (Task tarea: (list<Task>) Trigger.new){
            if (!tarea.IsClosed && setIdsLeadsConOpenTask.contains(tarea.WhoId)) tarea.adderror('Ya existe una tarea Abierta para este Prospecto');
          }
      }
      
      if (setIdsAcounts.size()>0){
          set<Id> setIdsAcountsConOpenTask = new set<Id>();
          for (Lead l: [select Id, (select Id from Tasks where IsClosed=false limit 1) from Lead where Id in:setIdsAcounts]){
              if (l.Tasks.size()>0) setIdsAcountsConOpenTask.add(l.Id);
          }
          for (Task tarea: (list<Task>) Trigger.new){
            if (!tarea.IsClosed && setIdsAcountsConOpenTask.contains(tarea.WhatId)) tarea.adderror('Ya existe una tarea Abierta para esta cuenta');
          }
      }
      
      if (setIdsOpportunities.size()>0){
          set<Id> setIdsOpportunitiesConOpenTask = new set<Id>();
          for (Lead l: [select Id, (select Id from Tasks where IsClosed=false limit 1) from Lead where Id in:setIdsOpportunities]){
              if (l.Tasks.size()>0) setIdsOpportunitiesConOpenTask.add(l.Id);
          }
          for (Task tarea: (list<Task>) Trigger.new){
            if (!tarea.IsClosed && setIdsOpportunitiesConOpenTask.contains(tarea.WhoId)) tarea.adderror('Ya existe una tarea Abierta para esta Oportunidad');
          }
      }
      */    
  }

  public override void beforeUpdate() {
    checkAccountOutdatedFields(Trigger.new);
  }

  private void checkAccountOutdatedFields(List<Task> tasks) {
    List<Account> accounts = getAccountsFromTasks(tasks);
    checkOutdatedFieldsIn(accounts, tasks);
  }

  private List<Account> getAccountsFromTasks(List<Task> tasks) {
    List<Account> accounts = new List<Account>();
    List<String> opportunityIds = new List<String>();

    for (Task task : tasks) {
      String accountPrefix = Schema.SObjectType.Account.getKeyPrefix();
      String opportunityPrefix = Schema.SObjectType.Opportunity.getKeyPrefix();

      if (task.WhatId == null) {
      } else if (String.valueOf(task.WhatId).startsWith(accountPrefix)) {
        accounts.add(new Account(Id = task.WhatId));
      } else if (String.valueOf(task.WhatId).startsWith(opportunityPrefix)) {
        opportunityIds.add(String.valueOf(task.WhatId));
      }
    }

    if (opportunityIds.size() > 0) {
      List<Opportunity> opportunities = [
        SELECT Id, AccountId, Account.PersonMobilePhone, Account.PersonEmail
        FROM Opportunity
        WHERE Id IN :opportunityIds
      ];

      for (Opportunity opportunity : opportunities) {
        accounts.add(
          new Account(
            Id = opportunity.AccountId,
            PersonMobilePhone = opportunity.Account.PersonMobilePhone,
            PersonEmail = opportunity.Account.PersonEmail
          )
        );
      }
    }

    return accounts;
  }

  private void checkOutdatedFieldsIn(List<Account> accounts, List<Task> tasks) {
    Integer result = FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
      accounts,
      tasks,
      Label.maxDiasTelefonoCuenta,
      Label.maxDiasEmailCuenta
    );
  }
}