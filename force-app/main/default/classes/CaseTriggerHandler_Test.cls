//Created by Me on January 2022
@isTest
public class CaseTriggerHandler_Test {
    private static testmethod void testearAutos (){
        TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountNatural); 
        
        Case caso = new Case();
        caso.Subject = 'Subject Case ';
        caso.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Autos_PQRSFS_Autos').getRecordTypeId();
        caso.Reason = 'Radicar PQRSF - Ticket Externos';
        caso.Subcategoria__c = 'Quejas y Reclamos Ventas';
        caso.Subcategoria_2__c = 'Inconveniente con producto';
        insert caso;
            
        caso.alerta_1__c = true;
        caso.Alerta_2__c = true;
        update caso;
      
    }
    
    private static testmethod void testearAutosCotizarRepuestoF18 (){
        TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountNatural); 
              
        //Caso especila, fila 18 de alerta a owner.managerId
        Case casoCotizarRepuesto = new Case();
        casoCotizarRepuesto.Subject = 'Subject Case 2';
        casoCotizarRepuesto.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(1).Id;
        casoCotizarRepuesto.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Autos_PQRSFS_Autos').getRecordTypeId();
        casoCotizarRepuesto.Reason = 'Servicio Posventa - Tickets Externos';
        casoCotizarRepuesto.Subcategoria__c = 'Cotizar un Repuesto';
        insert casoCotizarRepuesto;
            
        casoCotizarRepuesto.alerta_1__c = true;
        casoCotizarRepuesto.alerta_2__c = true;
        update casoCotizarRepuesto;
    }
    
    private static testmethod void testearMotos (){
        try{
            TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountNatural); 
            
            Case caso = new Case();
            caso.Subject = 'Subject Case Moto';
            caso.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
            caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Motos_PQRSFS_Motos').getRecordTypeId();
            caso.Reason = 'Motos';
            caso.Subcategoria__c = 'Queja';
            caso.Comments = 'comment one';
            caso.Auto_asignar_Caso__c = false;
            insert caso;
              
            Case casoConOwner = [select Id, OwnerId, Owner.Name from case where Id =:caso.Id];
            system.debug('casoConOwner: ' + casoConOwner);
            system.debug('casoConOwner.Owner.Name: ' + casoConOwner.Owner.Name);
          
            caso.Comments = 'comment two';
            caso.Status='Apoyo Concluido';
            
            update caso;
        
            
                //Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
            User uNivel1y2 = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = UserINfo.getProfileId(),//p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='fanalcatest220220329standarduser@testorg.com');
    
            insert uNivel1y2;       
            
            user me = new User(Id=Userinfo.getUserId());
            me.Escalacion_1_Motos__c = uNivel1y2.Id;
            me.Escalacion_2_Motos__c = uNivel1y2.Id;
            update me;
            
            Test.startTest();
        
            caso.Nivel_de_Escalacin__c = 1;
            caso.Escalar_Caso__c = true;
            system.debug('casoConOwner: ' + casoConOwner);
            system.debug('me: ' + me);
            update caso;
            
            TEst.stopTest();
            
            caso.Nivel_de_Escalacin__c = 2;
            caso.Escalar_Caso__c = true;
            update caso;
        }catch (exception ex){
            system.debug('Error: ' + ex.getMessage());
        }
    }
    
    private static testmethod void testearMotosComments (){
        TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountNatural); 
        test.startTest();
        Case caso = new Case();
        caso.Subject = 'Subject Case Moto';
        caso.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        caso.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Motos_PQRSFS_Motos').getRecordTypeId();
        caso.Reason = 'Motos';
        caso.Subcategoria__c = 'Queja';
        caso.Status = 'Inicio';
		//caso.Comments = 'comment one';
        
        insert caso;
        
        
        //Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = UserINfo.getProfileId(),//p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='fanalcatest220220329standarduser@testorg.com');

        insert u;        
        
       	Miembro_Equipo_Caso__c miembroCaso = new Miembro_Equipo_Caso__c(Caso__c = caso.Id, Usuario__c = U.Id);//Miembro_Equipo_Caso__c miembroCaso = new Miembro_Equipo_Caso__c(Caso__c = caso.Id, Usuario__c = Userinfo.getUserId());
        insert miembroCaso;
        test.stopTest();
        
        System.runAs(u) {
            // The following code runs as user 'u' 
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId()); 
            
            caso.Comments = 'comment two';
            caso.Status='Apoyo Concluido';
            update caso;
        }
        
        
    }
}