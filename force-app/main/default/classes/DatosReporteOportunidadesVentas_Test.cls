/**
 * Fanalca
 * @author           Olvin Abarca
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     25/01/2021      Olvin Abarca            Class definition.
 * @version  1.1     25/02/2021      Olvin Abarca            Synchronize quote before running assertions
 *********************************************************************************************************/
@isTest
private class DatosReporteOportunidadesVentas_Test {
  static Map<String, Object> objects = new Map<String, Object>();

  @TestSetup
  static void makeData() {
    Test.startTest();
    User portalUser = getPortalUser('PowerPartner', null, true);

    Quote q = null;
    Opportunity opportunity = null;

    System.runAs(portalUser) {
      Account account = (Account) objects.get('account');

      Concesionario__c concesionario = new Concesionario__c(
        Name = 'NAME1',
        Cuota_por_Asesor__c = 5,
        Agencia__c = 'AGENCIA1',
        Asesores_comerciales__c = 3,
        Codigo_concesionario__c = 'CON1',
        Codigo_de_agencia__c = 'AGE1',
        Departamento__c = 'DEP'
      );
      insert concesionario;
      objects.put('concesionario', concesionario);

      Miembro_de_concesionario__c miembrodeconcesionarioc = new Miembro_de_concesionario__c(
        Nombre_de_asesor__c = UserInfo.getUserId(),
        Concesionario__c = concesionario.Id
      );
      insert miembrodeconcesionarioc;
      objects.put('miembrodeconcesionarioc', miembrodeconcesionarioc);

      opportunity = new Opportunity(
        AccountId = account.Id,
        Tipo_de_cliente__c = 'Cliente Honda',
        Temperatura_de_la_Compra__c = 'Media',
        StageName = '-P0',
        CloseDate = System.today(),
        Amount = 1.1,
        OwnerId = UserInfo.getUserId(),
        Name = 'test value'
      );

      insert opportunity;

      Pricebook2 pricebk = new Pricebook2();
      pricebk.Name = 'PB test';
      pricebk.IsActive = true;
      insert pricebk;

      Pricebook2 standardPricebook = new Pricebook2(
        Id = Test.getStandardPricebookId(),
        IsActive = true
      );
      update standardPricebook;

      Map<String, RecordType> rtMap = new Map<String, RecordType>();
      for (RecordType rt : [
        SELECT Id, sobjecttype, DeveloperName
        FROM RecordType
      ]) {
        rtMap.put(rt.sobjecttype + '-' + rt.DeveloperName, rt);
      }

      RecordType recordTypeMoto = rtMap.get('Product2-Motos');
      Product2 producto = new Product2();
      producto.RecordTypeId = recordTypeMoto.Id;
      producto.Name = 'CB190R';
      producto.ProductCode = '001';
      producto.IsActive = true;
      insert producto;

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

      PriceBookEntry pbentry = new PriceBookEntry();
      pbentry.Pricebook2Id = pricebk.Id;
      pbentry.Product2Id = producto.Id;
      pbentry.IsActive = true;
      pbentry.UnitPrice = 123;
      insert pbentry;

      RecordType recordTypeQuoteMoto = rtMap.get(
        'Quote-' + Label.Cotizacion_Motos
      );

      q = new Quote();
      q.OpportunityId = opportunity.Id; //[select Id from Opportunity limit 1].Id;
      q.Pricebook2Id = pricebk.Id; //standardPricebook.Id;
      q.RecordTypeId = recordTypeQuoteMoto.Id;
      q.OwnerId = UserInfo.getUserId();
      q.Name = 'Nombre';
      q.Tipo_de_Pago__c = '101';
      q.Status = 'Cotización aceptada';
      q.Quote_PDF_Generado__c = true;
      q.Realizo_consulta_de_precios__c = true;
      insert q;

      QuoteLineItem qli = new QuoteLineItem();
      qli.QuoteId = q.Id;
      qli.Product2Id = producto.ID;
      qli.PricebookEntryId = pbentry.Id;
      qli.Quantity = 132;
      qli.Valor_soat__c = 2343902;
      qli.Valor_matrcula__c = 12334;
      qli.Cuota_Inicial__c = 12334;
      qli.Valor_seguro_robo__c = 12334;
      qli.Descuento_Valor__c = 23;
      qli.UnitPrice = 12334;
      insert qli;

      Concesionario__c con = new Concesionario__c();
      con.Agencia__c = 'Unico';
      con.Name = 'Palermo';
      con.OwnerId = opportunity.ownerId;
      insert con;

      Miembro_de_Concesionario__c mem = new Miembro_de_Concesionario__c();
      mem.Nombre_de_asesor__c = opportunity.ownerId;
      mem.Concesionario__c = con.Id;
      insert mem;
    }

    Test.stopTest();
  }

  public static User getPortalUser(
    String portalTypeName,
    User userWithRole,
    Boolean doInsert
  ) {
    /* Make sure the running user has a role otherwise an exception
     will be thrown. */
    String orgId = UserInfo.getOrganizationId();
    if (userWithRole == null) {
      if (UserInfo.getUserRoleId() == null) {
        UserRole r = new UserRole(name = 'VP Motos');
        Database.insert(r);
        userWithRole = new User(
          alias = 'hasrole',
          email = 'userwithrole@roletest1.com',
          username = 'puser@' + orgId + 'testing.com2',
          userroleid = r.id,
          emailencodingkey = 'UTF-8',
          lastname = 'Testing',
          languagelocalekey = 'en_US',
          localesidkey = 'en_US',
          profileid = UserInfo.getProfileId(),
          timezonesidkey = 'America/Los_Angeles'
        );
      } else {
        userWithRole = new User(
          Id = UserInfo.getUserId(),
          UserRoleId = UserInfo.getUserRoleId()
        );
      }
      System.assert(
        userWithRole.userRoleId != null,
        'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.'
      );
    }
    Account a;
    Contact c;
    System.runAs(userWithRole) {
      TestDataUtilityClass.crearClienteMotos(
        Label.MotosRecordTypeDevNameAccountJuridica,
        1
      );

      Account account = [
        SELECT Id
        FROM Account
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];
      objects.put('account', account);

      Contact contact = new Contact(
        FirstName = 'Test',
        Lastname = 'McTesty',
        AccountId = account.Id,
        Email = System.now().millisecond() + 'test@test.com'
      );
      Database.insert(contact);
      objects.put('contact', c);
      c = contact;
    }
    /* Get any profile for the given type.*/
    Profile portalUserProfile = [
      SELECT Id, Name
      FROM profile
      WHERE Name = 'Asesores motos'
      LIMIT 1
    ];

    String testemail = 'puser000@' + orgId + '.com';
    User pu = new User(
      profileId = portalUserProfile.Id,
      username = testemail,
      email = testemail,
      emailencodingkey = 'UTF-8',
      localesidkey = 'en_US',
      languagelocalekey = 'en_US',
      timezonesidkey = 'America/Los_Angeles',
      alias = 'cspu',
      lastname = 'lastname',
      contactId = c.id,
      Oportunidades_Objetivo__c = 10,
      Cuota__c = 10
    );
    if (doInsert) {
      Database.insert(pu);
    }
    return pu;
  }

  @isTest
  static void getDatosVentasOportunidadesAsAsesor() {
    synOpp();

    User portalUser = [SELECT Id FROM User WHERE alias = 'cspu' LIMIT 1];
    System.runAs(portalUser) {
      DatosReporteOportunidadesVentas instance = new DatosReporteOportunidadesVentas();
      List<Decimal> output = instance.ventasOportunidades;
      System.assert(output[0] == 1, true); // opp count
      // System.assert(output[1] == 10, true); // depends on day of month, difficult to assert
      System.assert(output[2] == 1, true);
      // System.assert(output[3] == 10, true);
    }
  }

  @isTest
  static void getDatosVentasOportunidadesAsGerente() {
    synOpp();

    // Profile profileGerente = [
    //   SELECT Id
    //   FROM Profile
    //   WHERE Name LIKE '%erente%' AND NAME LIKE '%otos%'
    //   LIMIT 1
    // ];

    // String testemail = 'gerentefanalca@' + orgId + '.com';
    // User userGerente = new User(
    //   ProfileId = profileGerente.Id,
    //   username = testemail,
    //   email = testemail,
    //   emailencodingkey = 'UTF-8',
    //   localesidkey = 'en_US',
    //   languagelocalekey = 'en_US',
    //   timezonesidkey = 'America/Los_Angeles',
    //   alias = 'gerfan',
    //   lastname = 'lastname2',
    //   Oportunidades_Objetivo__c = 10,
    //   Cuota__c = 10
    // );
    // update userGerente;

    // System.runAs(userGerente) {
    DatosReporteOportunidadesVentas instance = new DatosReporteOportunidadesVentas();
    List<Decimal> output = instance.ventasOportunidades;
    System.assert(output[0] == 1, true); // opp count
    // System.assert(output[1] == 10, true); // depends on day of month, difficult to assert
    System.assert(output[2] == 0, true);
    // System.assert(output[3] == 10, true);
    // }
  }

  @isTest
  private static void getOppListAsCSV() {
    Test.startTest();
    DatosReporteOportunidadesVentas.getOppListAsCSV(null);
    Test.stopTest();
  }

  private static void synOpp() {
    User usuarioIntegraciones = new User(
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Integraciones',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = UserInfo.getProfileId(),
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'standarduser@testorg.com.fanalcaSandbox'
    );

    Test.startTest();
    System.runAs(usuarioIntegraciones) {
      Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
      Quote quote = [SELECT Id FROM Quote LIMIT 1];
      opportunity.SyncedQuoteId = quote.Id;
      update opportunity;
    }
    Test.stopTest();
  }
}