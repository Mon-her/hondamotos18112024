@isTest
private class MilestoneTest {

    static testMethod void TestCompleteMilestoneCase() {
        List < Account > acts = new List < Account > ();
        Account myAcc = new Account(Name = 'TestAct', phone = '1001231');
        myAcc.AM_Numero_de_documento__c = '25974159' + '1';
        myACc.recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Persona Juridica').getRecordTypeId();
        myAcc.AM_Tipo_de_documento__c = 'NIT';
        
        acts.add(myAcc);

        Account busAcc = new Account(Name = 'TestForMS', phone = '3586789');
        busAcc.AM_Numero_de_documento__c = '25974159' + '2';
        busAcc.recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Persona Juridica').getRecordTypeId();
        busAcc.AM_Tipo_de_documento__c = 'NIT';
        
        acts.add(busAcc);
        insert acts;
        Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone = '4567890999', accountid = busAcc.id);
        insert(cont);

        Id contactId = cont.Id;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = busAcc.Id);
        insert entl;

        String entlId;
        if (entl != null)
            entlId = entl.Id;

        List < Case > cases = new List < Case > {};
        if (entlId != null) {
            Case c = new Case(Subject = 'Test Case with Entitlement ',
                EntitlementId = entlId, ContactId = contactId);
            cases.add(c);
        }
        
        Entitlement entlAutos = new Entitlement(Name = 'TestEntitlementAuto', AccountId = busAcc.Id);
        entlAutos.StartDate = System.today() -50;
        entlAutos.EndDate = System.today() + 50;
        entlAutos.SlaProcessId = [SELECT Id FROM SlaProcess where IsActive =true and Name like '%sarha%'].Id;
        insert entlAutos;
        
        
        //autos Case to get milestone
        Case casoAuto = new Case();
        casoAuto.AccountId = busAcc.Id;
        casoAuto.Reason = 'Radicar Consultas - Tickets Internos';
        casoAuto.subCategoria__c = 'Repuestos';
        casoAuto.Subcategoria_2__c = 'Nota Crédito';
        casoAuto.EntitlementId = entlAutos.Id;
        casoAuto.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('PQRSFS Autos').getRecordTypeId();
        test.startTest();
        insert casoAuto;
        
        
        test.stopTest();
        
        //milestoneUtils.completeMilestone(new List<Id>{casoAuto.Id}, System.now());
        
        list<CaseMilestone> caseMilestones = [select Id from CaseMilestone];
        system.debug('caseMilestones: ' + caseMilestones);
        
		milestoneUtils.completeMilestone(new List<Id>{casoAuto.Id}, System.now());        
        /*
        if (cases.isEmpty() == false) {
            insert cases;
            List < Id > caseIds = new List < Id > ();
            for (Case cL: cases) {
                caseIds.add(cL.Id);
            }
            //milestoneUtils.completeMilestone(caseIds, 'First Response', System.now());
            milestoneUtils.completeMilestone(caseIds, System.now());
        }
        */
        
    }
/*
    static testMethod void testCompleteMilestoneViaCase() {

        List < Account > acts = new List < Account > ();
        Account myAcc = new Account(Name = 'TestAct', phone = '1001231');
        myAcc.recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Persona Juridica').getRecordTypeId();
        myAcc.AM_Numero_de_documento__c = '25974159' + '0';
        myAcc.AM_Tipo_de_documento__c = 'NIT';
        acts.add(myAcc);

        Account busAcc = new Account(Name = 'TestForMS', phone = '4567892');
        busAcc.recordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Persona Juridica').getRecordTypeId();
        busAcc.AM_Numero_de_documento__c = '25974159' + '1';
        busAcc.AM_Tipo_de_documento__c = 'NIT';
        acts.add(busAcc);
        insert acts;
        Contact cont = new Contact(FirstName = 'Test', LastName = 'LastName', phone = '4567891', accountid = busAcc.id);
        insert(cont);

        Id contactId = cont.Id;

        Entitlement entl = new Entitlement(Name = 'TestEntitlement', AccountId = busAcc.Id);
        insert entl;

        String entlId;
        if (entl != null)
            entlId = entl.Id;

        List < Case > cases = new List < Case > {};
        for (Integer i = 0; i < 1; i++) {
            Case c = new Case(Subject = 'Test Case ' + i);
            cases.add(c);
            if (entlId != null) {
                c = new Case(Subject = 'Test Case with Entitlement ' + i,
                    EntitlementId = entlId);
                cases.add(c);
            }
        }
    }
*/
}