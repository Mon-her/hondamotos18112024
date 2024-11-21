@isTest
public class OpportunityTriggerTest {
   public static Integer HorasParaEvento = Integer.valueOf(LABEL.HorasParaEvento);
    public static Date hoy = system.today();
    public static DateTime ahora = system.now();
    /*
    private static testMethod void TestAutoNumberHandler() {
       account testaccount = new account (Name='test data');
       insert testaccount; 
       contact testcontact = new contact (FirstName='test data');
       insert testcontact; 

      Opportunity testOpportunity = new Opportunity(   accountId=testaccount.Id,   contactId=testcontact.Id,budget_confirmed__c=true,discovery_completed__c=true,roi_analysis_completed__c=true,registro_migrado__c=true,RecordTypeId= 'test data');

      insert testOpportunity;
      testOpportunity.RecordTypeId = 'new test1';
      update testOpportunity;
   }
    */
    
    private static testmethod void testear30Horas(){
		HorasParaEvento = 30;
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
    } 
    
    private static testmethod void testear0Horas(){
		HorasParaEvento = 0;
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
    } 
    
    public static testmethod void testearHoySabado8am12horas(){
        HorasParaEvento = 12;
        String nombreDia = ahora.format('EEEE');
		system.debug('El nombre del Dia es '+nombreDia);
		
        switch on nombreDia {
            when 'Monday' { hoy = hoy.addDays(5); }
            when 'Tuesday' { hoy = hoy.addDays(4); }
            when 'Wednesday' { hoy = hoy.addDays(3); }
            when 'Thursday' { hoy = hoy.addDays(2); }
            when 'Friday' { hoy = hoy.addDays(1); }
            //when 'Saturday' { hoy.addDays(6); }
            when 'Sunday' { hoy = hoy.addDays(6); }
        }
        ahora = DAteTime.newInstance(hoy.year(),hoy.month(),hoy.day(),8,0,0); //8 am local del dia sábado máx próximo en el futuro, o mismo día sábado si hoy es sábado, jajajaja
        
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
    }
    public static testmethod void testearHoyDomingo8am12horas(){
        HorasParaEvento = 12;
        String nombreDia = ahora.format('EEEE');
		system.debug('El nombre del Dia es '+nombreDia);
		
        switch on nombreDia {
            when 'Monday' { hoy = hoy.addDays(6); }
            when 'Tuesday' { hoy = hoy.addDays(5); }
            when 'Wednesday' { hoy = hoy.addDays(4); }
            when 'Thursday' { hoy = hoy.addDays(3); }
            when 'Friday' { hoy = hoy.addDays(2); }
            when 'Saturday' { hoy = hoy.addDays(1); }
            //when 'Sunday' { hoy.addDays(6); }
        }
        ahora = DAteTime.newInstance(hoy.year(),hoy.month(),hoy.day(),8,0,0); //8 am local del dia sábado máx próximo en el futuro, o mismo día sábado si hoy es sábado, jajajaja
        
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        TestDatautilityClass.crearOportunidadMotos(1);
    }
    
    private static testmethod void testearOppRenting(){
		HorasParaEvento = 30;
        Triggerhandler.bypass('AccountTriggerHandler');
      	Triggerhandler.bypass('TaskTriggerHandler');
        
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'VP_HONDA_AUTOS' Limit 1];

		//set a role to admin user, to allow create a community user, if I don't do this, I get "portal account owner must have a role" when trying to create a portal user
        User adminUser = new User(Id=Userinfo.getUserId());
		adminUser.UserRoleId = userRole.Id;
		update adminUser;
        
        User userRenting1;
        Contact c,c2;
        Profile p;
            
        
        
        system.runAs(adminUser){
        	TestDataUtilityClass.crearConcesionarios(1);
        	TestDataUtilityClass.crearCuentasAutos(1,Label.AutosRecordTypeDevNameAccountJuridica);   
            TestDataUtilityClass.crearCuentasAutos(1,Label.AutosRecordTypeDevNameAccountNatural);  //Esta se usa en la creación de opp desde test data utility class
            
            
                
             TestDataUtilityClass.mapClientesAutosJuridico.get(0).IsPartner = true;
			update TestDataUtilityClass.mapClientesAutosJuridico.get(0);
            
            c = new Contact();
            c.FirstName = 'fName';
            c.LastName = 'lName';
            c.AM_Tipo_de_documento_Contacto__c = 'Cédula de ciudadanía';
            c.AM_Numero_de_documento_contacto__c = '12365478';
            c.AccountId = TestDatautilityClass.mapClientesAutosJuridico.get(0).Id;
            insert c;
            
            c2 = new Contact();
            c2.FirstName = 'fName2';
            c2.LastName = 'lName2';
            c2.AM_Tipo_de_documento_Contacto__c = 'Cédula de ciudadanía';
            c2.AM_Numero_de_documento_contacto__c = '123654789';
            c2.AccountId = TestDatautilityClass.mapClientesAutosJuridico.get(0).Id;
            insert c2;
            
            //Create a renting user
            p = [SELECT Id FROM Profile WHERE Name in ('Asesores autos') order by Name desc limit 1];
            String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
            userRenting1 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id, ContactId=c.Id,
                TimeZoneSidKey='America/Los_Angeles',
                                    ManagerId= UserInfo.getUserId(),
                 UserName=uniqueUserName);
            insert userRenting1;
            
            //Dar acceso de edición a la cuenta al amigo userRenting1
            AccountShare acShare = new AccountShare();
            acShare.AccountId = TestDatautilityClass.mapClientesAutosNatural.get(0).Id;
            acShare.RowCause = 'Manual';
            acShare.UserOrGroupId = userRenting1.Id;
            acShare.AccountAccessLevel ='Edit';
            acShare.OpportunityAccessLevel = 'Edit';
            insert acShare;
            
            //crearMiembroConcesionarios relacionado al userRenting1
            Miembro_de_Concesionario__c mc = new Miembro_de_Concesionario__c();
            mc.Concesionario__c = TestDatautilityClass.mapConcesionarios.get(1).Id;
            mc.Nombre_de_asesor__c = userRenting1.Id;
            insert mc;
            
            //System.runAs(adminUser){
            String uniqueUserName2 = 'standarduser2' + DateTime.now().getTime() + '@testorg.com';
            User userRenting2 = new User(Alias = 'standt', Email='standarduser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',ContactId=c2.Id,
                                         ManagerId= UserInfo.getUserId(),
                 UserName=uniqueUserName2);
            insert userRenting2;
            
            Miembro_de_Concesionario__c mc2 = new Miembro_de_Concesionario__c();
            mc2.Concesionario__c = TestDatautilityClass.mapConcesionarios.get(1).Id;
            mc2.Nombre_de_asesor__c = userRenting2.Id;
            mc2.Asesor_de_renting2__c = true;
            insert mc2;
            
            //Dar acceso de edición a la cuenta al amigo userRenting2
            AccountShare acShare2 = new AccountShare();
            acShare2.AccountId = TestDatautilityClass.mapClientesAutosNatural.get(0).Id;
            acShare2.RowCause = 'Manual';
            acShare2.UserOrGroupId = userRenting2.Id;
            acShare2.AccountAccessLevel ='Edit';
            acShare2.OpportunityAccessLevel = 'Edit';
            insert acShare2;
        	//}
        }
        RecordType rt = [    SELECT Id, DeveloperName      FROM RecordType      WHERE DeveloperName = :Label.RTOportunidadAutos    ];
        Test.startTest();
        Opportunity op;
        System.runAs(userRenting1){
            //TestDataUtilityClass.crearMiembroConcesionarios(1);
            //TestDataUtilityClass.crearCuentasAutos(1,Label.AutosRecordTypeDevNameAccountNatural);
            
            //TestDatautilityClass.crearOportunidadAutos(1);
                    
            
            
            op = new Opportunity();
          op.Name = 'Opp1 ' ;
          op.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
          op.Tipo_de_cliente__c = 'Cliente Honda';
          op.CloseDate = system.today();
          op.Tipo_de_Pago__c = '101';
          op.AutoNumber__c = '123';
          op.Temperatura_de_la_Compra__c = 'Media';
          op.StageName = '-P0';
          op.RecordTypeId = rt.Id;
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
          op.AutoNumber__c = '123';
          op.Tipo_de_Oportunidad__c='Renting';
            insert op;
            //TestDatautilityClass.mapOpportunitiesAutos.get(1).Tipo_de_Oportunidad__c='Renting';
            //update TestDatautilityClass.mapOpportunitiesAutos.get(1);
        }
        
        System.runAs(adminUser){
            op.OwnerId = userRenting1.Id;
            update op;
        }
       
        Test.stopTest();
    } 
    
    private static testmethod void testearOppUsados(){
		HorasParaEvento = 30;
        Triggerhandler.bypass('AccountTriggerHandler');
      	Triggerhandler.bypass('TaskTriggerHandler');
       
        	TestDataUtilityClass.crearConcesionarios(1);
        	TestDataUtilityClass.crearMiembroConcesionarios(1);
        
       
        RecordType rt = [    SELECT Id, DeveloperName      FROM RecordType      WHERE DeveloperName = :Label.RTOportunidadAutos    ];
        Test.startTest();
        Opportunity op;
        
        RecordType pnRecordType;
        RecordType pjRecordType;
        for (RecordType rtA : [
          SELECT id, DeveloperName
          FROM RecordType
          WHERE sobjecttype = 'Account' AND isActive = TRUE
        ]) {
          if (rtA.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)
            pnRecordType = rtA;
          if (rtA.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica)
            pjRecordType = rtA;
        }

        
        Account a = new account();
        a.AM_Numero_de_documento__c = '25974159';
        a.recordTypeID = pnRecordType.Id;
        a.Salutation = 'Sr.'; //Esto determina el género
        a.AM_Tipo_de_documento__c = 'Cédula de ciudadanía';
        a.FirstName = 'Jorge Pablo' + '1';
        a.LastName = 'Perez' + '1';
        a.Primer_nombre__c = a.FirstName;
        a.Primer_Apellido__c = a.LastName;
        a.Segundo_Apellido__c = 'Josema' + '1';
        a.PersonEmail = 'email' + '1' + '@email.com';
        //a.PersonMobilePhone = '348789542' + i;
        a.PersonBirthdate = Date.newInstance(1997, 12, 30);
        a.AM_Estado_civil__pc = 'Soltero';
        a.Fecha_Fin_Garantia__c = Date.newInstance(2050, 12, 30);
        a.Segmentacion2__c = 'Cliente en Garantía';
        a.Creado_en_UNOEE__c = true;
        a.Genero__c	 = 'Masculino'; //y esta creación manual todo el género
        a.AM_Genero__pc = 'Masculino';
        
        system.debug('a: ' + a.Genero__c);
        insert a;
        
        system.debug([select Id, Name,Genero__c,AM_Genero__pc from Account where Id=:a.Id]);    
        
          op = new Opportunity();
          op.Name = 'Opp1 ' ;
          op.AccountId = a.Id;//TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        
          op.Tipo_de_cliente__c = 'Cliente Honda';
          op.CloseDate = system.today();
          op.Tipo_de_Pago__c = '101';
          op.AutoNumber__c = '123';
          op.Temperatura_de_la_Compra__c = 'Media';
          op.StageName = '-P0';
          op.RecordTypeId = rt.Id;
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
          op.AutoNumber__c = '123';
          op.Tipo_de_Oportunidad__c='Usados';
          
            insert op;

        //Create a renting user
            Profile pIntegra = [SELECT Id FROM Profile WHERE Name in ('Integraciones') order by Name desc limit 1];
            String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
            User userIntegrador = new User(Alias = 'standt', Email='standarduser@testorg.com',
                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', ProfileId = pIntegra.Id,
                TimeZoneSidKey='America/Los_Angeles',
                ManagerId = UserInfo.getUserId(),
                 UserName=uniqueUserName);
            insert userIntegrador;
        
        Miembro_de_Concesionario__c mc = new Miembro_de_Concesionario__c();
            mc.Concesionario__c = TestDatautilityClass.mapConcesionarios.get(1).Id;
            mc.Nombre_de_asesor__c = userIntegrador.Id;
            insert mc;
       
        System.runAs(userIntegrador){
            op.StageName = 'P5';
            update op;    
        }
        
        
        
        Test.stopTest();
    } 
    
    public static testMethod void testearOppUsadoswithProduct() {
    Triggerhandler.bypass('AccountTriggerHandler');
      	Triggerhandler.bypass('TaskTriggerHandler');
        

    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name IN ('Integraciones') order by CreatedDAte asc//WHERE Name IN ('System Administrator', 'Administrador del Sistema') order by CreatedDAte asc
      LIMIT 1
    ];
    User u = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Integraciones',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'standarduser@testorg.com.fanalcaSandbox'
        ,ManagerId= UserInfo.getUserId()
    );
        insert u;

    //Triggerhandler.bypass('OpportunityTriggerHandler');
    Triggerhandler.bypass('QuoteTriggerHandler');

    Opportunity op = new Opportunity();
    RecordType rt = [    SELECT Id, DeveloperName      FROM RecordType      WHERE DeveloperName = :Label.RTOportunidadAutos    ];
        
    System.runAs(u) {
      TestDataUtilityClass.crearConcesionarios(1);
      TestDataUtilityClass.crearMiembroConcesionarios(1);
      TestDataUtilityClass.crearCuentasAutos(
        1,Label.AutosRecordTypeDevNameAccountNatural
      );
        TestDataUtilityClass.mapClientesAutosNatural.get(0).Salutation = 'Sr.';
        TestDataUtilityClass.mapClientesAutosNatural.get(0).Genero__c	 = 'Masculino'; //y esta creación manual todo el género
        TestDataUtilityClass.mapClientesAutosNatural.get(0).AM_Genero__pc = 'Masculino';
        update TestDataUtilityClass.mapClientesAutosNatural.get(0);
      //TestDatautilityClass.crearOportunidadAutos(1);
       op.Name = 'Opp1 ' ;
          op.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        
          op.Tipo_de_cliente__c = 'Cliente Honda';
          op.CloseDate = system.today();
          op.Tipo_de_Pago__c = '101';
          op.AutoNumber__c = '123';
          op.Temperatura_de_la_Compra__c = 'Media';
          op.StageName = '-P0';
          op.RecordTypeId = rt.Id;
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
          op.AutoNumber__c = '123';
          op.Tipo_de_Oportunidad__c='Usados';
          
            insert op;
    }
    
    Account ctaNatural1 = TestDataUtilityClass.mapClientesAutosNatural.get(0);
        
       
         
        
    //ctaNatural1.Codigo_ERP__c = '1234567890';
    //update ctaNatural1;
    //Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1); 
    //opp.AccountId = ctaNatural1.Id;
    //opp.Name = 'Name';
    //opp.StageName = '-P0';
    op.CloseDate = Date.newInstance(2010, 12, 30);
    op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
    //opp.Fecha_de_validez__c = Date.newInstance(2010, 10, 30);
    op.Fecha_de_validez__c = Date.today() + 10;
    op.Tipo_de_Pago__c = '101';
    op.Destinatario_Factura__c = ctaNatural1.Id;
    op.Destinatario_Mercanc_a__c = ctaNatural1.Id;
    op.Pagador__c = ctaNatural1.Id;
    op.Titular_prendario__c = ctaNatural1.Id;
    op.Codigo_Tercero_SAP__c = ctaNatural1.Id;
    op.Codigo_Usuario_SAP__c = ctaNatural1.Id;
    op.OwnerId = Userinfo.getUserId(); //[select Id, OwnerId from Account limit 1].OwnerId;
    op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
    op.Averigu_sobre_otras_marcas__c = 'No';
        //opp.Tipo_de_Oportunidad__c='Usados';
    
    system.debug(  'Antes de Start Test Limits.getQueries: ' +     System.Limits.getQueries()      );
  Test.startTest();
    
        System.runAs(u) {
          update op;
        }

        Pricebook2 standardPricebook = new Pricebook2(
          Id = Test.getStandardPricebookId(),
          IsActive = true
        );
        update standardPricebook;

          Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        
        
		Inventario_de_Usados__c i = new Inventario_de_Usados__c();
      	i.Color__c = 'Test';
        i.Estado_Del_Vehiculo__c = 'DISPONIBLE';
      	insert i;

       system.debug(  'Después de insert i Limits.getQueries: ' +     System.Limits.getQueries()      );
        
        RecordType rtProductoMotos = [  SELECT Id, name   FROM recordType   WHERE sobjecttype = 'Product2' AND name LIKE '%auto%'  LIMIT 1 ];
        Product2 producto = new Product2();
        producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoMotos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto;
        
       
        

    

    //Product2 producto = [SELECT Id FROM Product2 LIMIT 1];

    PriceBookEntry pbentry = new PriceBookEntry();
    pbentry.Pricebook2Id = pricebk.Id; //standardPricebook.Id; //[select Id from Pricebook2 limit 1].Id;
    pbentry.Product2Id = producto.Id; //[select Id from Product2 limit 1].Id;
    pbentry.IsActive = true;
    pbentry.UnitPrice = 123;
    insert pbentry;
//system.debug('product2');
        //system.debug([select id, name, Inventario_de_Usados__c, Inventario_de_Usados__r.Estado_Del_Vehiculo__c from Product2]);
    Quote q = new Quote();
    QuoteLineItem qli = new QuoteLineItem();
        
        system.debug(  'Antes de insertar Quote Limits.getQueries: ' +     System.Limits.getQueries()      );
    System.runAs(u) {
      

      q.OpportunityId = op.Id; //[select Id from Opportunity limit 1].Id;
      q.Pricebook2Id = pricebk.Id; //standardPricebook.Id;
      q.RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE sobjecttype='Quote' and developerName like '%auto%'// = :Label.Cotizacion_Motos
      ]
      .Id;
      q.Name = 'Nombre';
      q.Tipo_de_Pago__c = '101';
      q.Status = 'Cotización aceptada';
      q.Quote_PDF_Generado__c = true;
        q.DescuentoApro__c = true;
      q.Realizo_consulta_de_precios__c = true;
      insert q;
      system.debug(
        'Despues de insertar Quote Limits.getQueries: ' +
        System.Limits.getQueries()
      );

      qli.QuoteId = q.Id; //[select Id from Quote limit 1].Id;
      qli.Product2Id = producto.ID; //[select Id from Product2 limit 1].Id;
      qli.PricebookEntryId = pbentry.Id; //[select Id from PriceBookEntry limit 1].Id;
      qli.Quantity = 1;
      qli.Valor_soat__c = 2343902;
      qli.Valor_matrcula__c = 12334;
      qli.Cuota_Inicial__c = 12334;
      qli.Valor_seguro_robo__c = 12334;
      qli.Descuento_Valor__c = 0;
      qli.UnitPrice = 12334;
      insert qli;
    }

    system.debug('Limits.getQueries: ' + System.Limits.getQueries());
    /*System.runAs(u) {
      op.StageName = 'P5';
        op.SyncedQuoteId = q.Id;
      update op;
    }*/
        sincronizar(q.id, op.Id, u.Id);
   
/*
    System.runAs(u) {
      qli.Quantity = 12;
      update qli;
    }*/


  }
    
    @future
    private static void sincronizar(id qId, Id oppId,Id userId){
        User u = [select Id from User where Id=:userId];
        System.runAs(u){
            Opportunity op = new Opportunity(Id=oppId);
            op.StageName = 'P5';
            op.SyncedQuoteId = qId;
          update op;
        }
        
    }
}