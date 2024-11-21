@isTest
public class Invocable_UpdateCase_Test {
    private static testmethod void testear(){
         TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountNatural); 
        
        Case caso = new Case();
        caso.Subject = 'Subject Case ';
        caso.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Autos_PQRSFS_Autos').getRecordTypeId();
        caso.Reason = 'Radicar PQRSF - Ticket Externos';
        caso.Subcategoria__c = 'Quejas y Reclamos Ventas';
        caso.Subcategoria_2__c = 'Inconveniente con producto';
        insert caso;
        
        Invocable_UpdateCase.assignmentParameter parametro = new Invocable_UpdateCase.assignmentParameter();
        parametro.recordId = caso.Id;
        
        Invocable_UpdateCase.updateCase(new list<Invocable_UpdateCase.assignmentParameter>{parametro});
    }
}