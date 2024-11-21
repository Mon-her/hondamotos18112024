@isTest
//Testea QuoteLineSyncTrigger, OppLineSyncTrigger y QuoteSyncTrigger
public class QuoteSync_Test {
  static RecordType rtProductoMotos = [
    SELECT Id, name
    FROM recordType
    WHERE sobjecttype = 'Product2' AND name LIKE '%moto%'
    LIMIT 1
  ];
  @TestSetup
  static void makeData() {
    Product2 producto = new Product2();
    producto.Name = 'Honda CRV Test';
    producto.ProductCode = '001';
    producto.IsActive = true;
    producto.RecordTypeId = rtProductoMotos.Id;
    insert producto;

    Product2 producto2 = new Product2();
    producto2.Name = 'Honda CRV Test 2';
    producto2.ProductCode = '002';
    producto2.IsActive = true;
    producto2.RecordTypeId = rtProductoMotos.Id;
    insert producto2;

    if (
      [
        SELECT id
        FROM PricebookEntry
        WHERE
          Product2Id = :producto.Id
          AND Pricebook2Id = :Test.getStandardPricebookId()
      ]
      .size() == 0
    ) {
      PricebookEntry pbentrySt = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = producto.Id,
        UnitPrice = 1001,
        IsActive = true
      );
      insert pbentrySt;
    }

    if (
      [
        SELECT id
        FROM PricebookEntry
        WHERE
          Product2Id = :producto2.Id
          AND Pricebook2Id = :Test.getStandardPricebookId()
      ]
      .size() == 0
    ) {
      PricebookEntry pbentrySt = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = producto2.Id,
        UnitPrice = 1001,
        IsActive = true
      );
      insert pbentrySt;
    }
  }

  public static testMethod void testearQuoteAndOppLineSyncTrigger() {
    QuoteSyncField__c setting = new QuoteSyncField__c();
    setting.Name = 'Concesionario__c';
    setting.OppSyncField__c = 'Concesionario__c';
    insert setting;

    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name IN ('System Administrator', 'Administrador del Sistema') order by createddate asc
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
    );

    Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');

    System.runAs(u) {
      TestDataUtilityClass.crearConcesionarios(1);
      TestDataUtilityClass.crearMiembroConcesionarios(1);
      TestDataUtilityClass.crearClienteMotos(
        Label.MotosRecordTypeDevNameAccountNatural,
        1
      );
      TestDatautilityClass.crearOportunidadMotos(1);
    }
    //TestDataUtilityClass.crearQuoteMotos(1);

    //TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
    Account ctaNatural1 = TestDataUtilityClass.mapClientesMotosNatural.get(1);
    ctaNatural1.Codigo_ERP__c = '1234567890';
    update ctaNatural1;
    Opportunity opp = TestDataUtilityClass.mapOpportunitiesMotos.get(1); //new Opportunity();
    //opp.AccountId = ctaNatural1.Id;
    //opp.Name = 'Name';
    //opp.StageName = '-P0';
    opp.CloseDate = Date.newInstance(2010, 12, 30);
    opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
    //opp.Fecha_de_validez__c = Date.newInstance(2010, 10, 30);
    opp.Fecha_de_validez__c = Date.today() + 10;
    opp.Tipo_de_Pago__c = '101';
    opp.Destinatario_Factura__c = ctaNatural1.Id;
    opp.Destinatario_Mercanc_a__c = ctaNatural1.Id;
    opp.Pagador__c = ctaNatural1.Id;
    opp.Titular_prendario__c = ctaNatural1.Id;
    opp.Codigo_Tercero_SAP__c = ctaNatural1.Id;
    opp.Codigo_Usuario_SAP__c = ctaNatural1.Id;
    opp.OwnerId = Userinfo.getUserId(); //[select Id, OwnerId from Account limit 1].OwnerId;
    opp.Motivo_de_Oportunidad_Vendida__c = 'Otras';
    opp.Averigu_sobre_otras_marcas__c = 'No';
    System.runAs(u) {
      update opp;
    }

    Pricebook2 pricebk = new Pricebook2();
    pricebk.Name = 'PB test';
    pricebk.IsActive = true;
    insert pricebk;

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Product2 producto = [SELECT Id FROM Product2 LIMIT 1];

    PriceBookEntry pbentry = new PriceBookEntry();
    pbentry.Pricebook2Id = pricebk.Id; //standardPricebook.Id; //[select Id from Pricebook2 limit 1].Id;
    pbentry.Product2Id = producto.Id; //[select Id from Product2 limit 1].Id;
    pbentry.IsActive = true;
    pbentry.UnitPrice = 123;
    insert pbentry;

    Quote q = new Quote();
    QuoteLineItem qli = new QuoteLineItem();
    System.runAs(u) {
      system.debug(
        'Antes de insertar Quote Limits.getQueries: ' +
        System.Limits.getQueries()
      );

      q.OpportunityId = opp.Id; //[select Id from Opportunity limit 1].Id;
      q.Pricebook2Id = pricebk.Id; //standardPricebook.Id;
      q.RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE developerName = :Label.Cotizacion_Motos
      ]
      .Id;
      q.Name = 'Nombre';
      q.Tipo_de_Pago__c = '101';
      q.Status = 'Cotización aceptada';
      q.Quote_PDF_Generado__c = true;
      q.Realizo_consulta_de_precios__c = true;
      insert q;
      system.debug(
        'Despues de insertar Quote Limits.getQueries: ' +
        System.Limits.getQueries()
      );

      qli.QuoteId = q.Id; //[select Id from Quote limit 1].Id;
      qli.Product2Id = producto.ID; //[select Id from Product2 limit 1].Id;
      qli.PricebookEntryId = pbentry.Id; //[select Id from PriceBookEntry limit 1].Id;
      qli.Quantity = 132;
      qli.Valor_soat__c = 2343902;
      qli.Valor_matrcula__c = 12334;
      qli.Cuota_Inicial__c = 12334;
      qli.Valor_seguro_robo__c = 12334;
      qli.Descuento_Valor__c = 0;//23;
      qli.UnitPrice = 12334;
      insert qli;
    }

    system.debug('Limits.getQueries: ' + System.Limits.getQueries());
     Test.startTest();  
    System.runAs(u) {
      opp.SyncedQuoteId = q.Id;
      update opp;
    }

    //Test.startTest();

    System.runAs(u) {
      qli.Quantity = 12;
      update qli;
    }


    //update TestDatautilityClass.mapQuotesMotos.get(1);
  }

  public static testMethod void testearQLSyncTrigger() {
    QuoteSyncField__c setting = new QuoteSyncField__c();
    setting.Name = 'Concesionario__c';
    setting.OppSyncField__c = 'Concesionario__c';
    insert setting;

    QuoteLineSyncField__c settingqli = new QuoteLineSyncField__c();
    settingqli.Name = 'Accesorios__c';
    settingqli.OppLineSyncField__c = 'Accesorios__c';
    insert settingqli;

    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name IN ('System Administrator', 'Administrador del Sistema') order by createddate asc
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
    );
insert u;
      
      
      
    Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
//TestDataUtilityClass.crearClienteMotos(
      //  Label.MotosRecordTypeDevNameAccountNatural,
      //  1
      //);
      //TestDataUtilityClass.mapClientesMotosNatural.get(1).OwnerId = u.Id;
      //update TestDataUtilityClass.mapClientesMotosNatural.get(1);
    System.runAs(u) {
      TestDataUtilityClass.crearConcesionarios(1);
      TestDataUtilityClass.crearMiembroConcesionarios(1);
      TestDataUtilityClass.crearClienteMotos(
        Label.MotosRecordTypeDevNameAccountNatural,
        1
      );
      TestDatautilityClass.crearOportunidadMotos(1);
    }
    //TestDataUtilityClass.crearQuoteMotos(1);

    //TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);

    Pricebook2 pricebk = new Pricebook2();
    pricebk.Name = 'PB test';
    pricebk.IsActive = true;
    insert pricebk;

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    List<Product2> productos = [SELECT Id FROM Product2];

    Product2 producto = productos[0];
    Product2 producto2 = productos[1];

    PriceBookEntry pbentry = new PriceBookEntry();
    pbentry.Pricebook2Id = pricebk.Id; //standardPricebook.Id; //[select Id from Pricebook2 limit 1].Id;
    pbentry.Product2Id = producto.Id; //[select Id from Product2 limit 1].Id;
    pbentry.IsActive = true;
    pbentry.UnitPrice = 11;
    insert pbentry;

    PriceBookEntry pbentry2 = new PriceBookEntry();
    pbentry2.Pricebook2Id = pricebk.Id; //standardPricebook.Id; //[select Id from Pricebook2 limit 1].Id;
    pbentry2.Product2Id = producto2.Id; //[select Id from Product2 limit 1].Id;
    pbentry2.IsActive = true;
    pbentry2.UnitPrice = 22;
    insert pbentry2;

    Account ctaNatural1 = TestDataUtilityClass.mapClientesMotosNatural.get(1);
    ctaNatural1.Codigo_ERP__c = '1234567890';
    update ctaNatural1;
    Opportunity opp = TestDataUtilityClass.mapOpportunitiesMotos.get(1); //new Opportunity();
    //opp.AccountId = ctaNatural1.Id;
    //opp.Name = 'Name';
    //opp.StageName = '-P0';
    opp.CloseDate = Date.newInstance(2010, 12, 30);
    opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
    //opp.Fecha_de_validez__c = Date.newInstance(2010, 10, 30);
    opp.Fecha_de_validez__c = Date.today() + 10;
    opp.Tipo_de_Pago__c = '101';
    opp.Destinatario_Factura__c = ctaNatural1.Id;
    opp.Destinatario_Mercanc_a__c = ctaNatural1.Id;
    opp.Pagador__c = ctaNatural1.Id;
    opp.Titular_prendario__c = ctaNatural1.Id;
    opp.Codigo_Tercero_SAP__c = ctaNatural1.Id;
    opp.Codigo_Usuario_SAP__c = ctaNatural1.Id;
    opp.OwnerId = Userinfo.getUserId(); //[select Id, OwnerId from Account limit 1].OwnerId;
    opp.Motivo_de_Oportunidad_Vendida__c = 'Otras';
    opp.Averigu_sobre_otras_marcas__c = 'No';
    opp.Pricebook2Id = pricebk.Id;
    System.runAs(u) {
      update opp;
    }

    Quote q = new Quote();
    QuoteLineItem qli = new QuoteLineItem();
    System.runAs(u) {
      system.debug(
        'Antes de insertar Quote Limits.getQueries: ' +
        System.Limits.getQueries()
      );

      q.OpportunityId = opp.Id; //[select Id from Opportunity limit 1].Id;
      q.Pricebook2Id = pricebk.Id; //standardPricebook.Id;
      q.RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE developerName = :Label.Cotizacion_Motos
      ]
      .Id;
      q.Name = 'Nombre';
      q.Tipo_de_Pago__c = '101';
      q.Status = 'Cotización aceptada';
      q.Quote_PDF_Generado__c = true;
      q.Realizo_consulta_de_precios__c = true;
      insert q;
      system.debug(
        'Despues de insertar Quote Limits.getQueries: ' +
        System.Limits.getQueries()
      );

      qli.QuoteId = q.Id; //[select Id from Quote limit 1].Id;
      qli.Product2Id = producto.ID; //[select Id from Product2 limit 1].Id;
      qli.PricebookEntryId = pbentry.Id; //[select Id from PriceBookEntry limit 1].Id;
      qli.Quantity = 132;
      qli.Valor_soat__c = 2343902;
      qli.Valor_matrcula__c = 12334;
      qli.Cuota_Inicial__c = 12334;
      qli.Valor_seguro_robo__c = 12334;
      qli.Descuento_Valor__c = 0;//23;
      qli.UnitPrice = 12334;
      insert qli;
    }

    system.debug('Limits.getQueries: ' + System.Limits.getQueries());
    Test.startTest();
    System.runAs(u) {
      opp.SyncedQuoteId = q.Id;
      update opp;
    }

    //Test.startTest();
    QuoteSyncUtil.isRunningTest = true;
    System.runAs(u) {
      QuoteLineItem qli2 = new QuoteLineItem();

      system.debug(
        'Despues de insertar Quote Limits.getQueries: ' +
        System.Limits.getQueries()
      );

      qli2.QuoteId = q.Id; //[select Id from Quote limit 1].Id;
      qli2.Product2Id = producto.ID; //[select Id from Product2 limit 1].Id;
      qli2.PricebookEntryId = pbentry.Id; //[select Id from PriceBookEntry limit 1].Id;
      qli2.Quantity = 132;
      qli2.Valor_soat__c = 2343902;
      qli2.Valor_matrcula__c = 12334;
      qli2.Cuota_Inicial__c = 12334;
      qli2.Valor_seguro_robo__c = 12334;
      qli2.Descuento_Valor__c = 0;//23;
      qli2.UnitPrice = qli.UnitPrice; //222;
      qli2.Accesorios__c = 456;
      insert qli2;

      //qli2.Quantity = 2;
      //qli.Quantity = 1;

      list<QuoteLineItem> updQlis = new List<QuoteLineItem>();
      updQlis.add(qli);
      updQlis.add(qli2);
      update updQlis;

      qli2.Accesorios__c = 123;
      update qli2;
    }


    //update TestDatautilityClass.mapQuotesMotos.get(1);
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
        
       
    PriceBookEntry pbentry = new PriceBookEntry();
    pbentry.Pricebook2Id = pricebk.Id; //standardPricebook.Id; //[select Id from Pricebook2 limit 1].Id;
    pbentry.Product2Id = producto.Id; //[select Id from Product2 limit 1].Id;
    pbentry.IsActive = true;
    pbentry.UnitPrice = 123;
    insert pbentry;

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
   
        sincronizar(q.id, op.Id, u.Id);


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