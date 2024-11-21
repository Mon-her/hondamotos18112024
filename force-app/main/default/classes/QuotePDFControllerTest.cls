@isTest
public class QuotePDFControllerTest {
  // private static Map<String, Object> objects = mock();

  @TestSetup
  static void makeData() {
    List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account personaNaturalAccount = accounts[0];

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    Opportunity opp = opps[0];

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Pricebook2 pricebk = new Pricebook2();
    pricebk.Name = 'PB test';
    pricebk.IsActive = true;
    insert pricebk;

    RecordType recordTypeMoto = [
      SELECT Id
      FROM RecordType
      WHERE developerName = 'Motos' AND sobjecttype = 'Product2'
      LIMIT 1
    ];

    Product2 product1 = new Product2(
      RecordTypeId = recordTypeMoto.Id,
      Name = 'Product X',
      ProductCode = 'Pro-X',
      isActive = true,
	  SO_Garantia_motocicleta__c ='Garantia1'
    );
    insert product1;

    if (
      [
        SELECT id
        FROM PricebookEntry
        WHERE
          Product2Id = :product1.Id
          AND Pricebook2Id = :Test.getStandardPricebookId()
      ]
      .size() == 0
    ) {
      PricebookEntry pbentrySt = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = product1.Id,
        UnitPrice = 1000,
        IsActive = true
      );
      insert pbentrySt;
    }

    //Create your pricebook entry
    PricebookEntry pricebookEntry = new PricebookEntry(
      Pricebook2Id = pricebk.Id,
      Product2Id = product1.Id,
      UnitPrice = 100.00,
      IsActive = true
    );
    insert pricebookEntry;

    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId = opp.Id,
      Quantity = 5,
      PricebookEntryId = pricebookEntry.Id,
      TotalPrice = 5 * pricebookEntry.UnitPrice
    );

    Test.startTest();
    insert oli;

    //Test.startTest(); moved 3 lns above on feb 2021, to avoid soql limit in production

    Order order1 = new Order();
    order1.AccountId = personaNaturalAccount.Id;
    order1.Status = 'Draft';
    order1.OpportunityId = opp.Id;
    order1.EffectiveDate = Date.today();
    order1.Pricebook2Id = pricebk.Id;
    insert order1;

    Id recordTypeQuoteMoto = Schema.SObjectType.Quote.getRecordTypeInfosByName()
      .get('Cotizaciones Motos')
      .getRecordTypeId();
    Quote quote = new Quote();
    quote.OwnerId = UserInfo.getUserId();
    quote.OpportunityId = opp.Id;
    quote.Name = 'Test quote';
    quote.RecordTypeId = recordTypeQuoteMoto;
    insert quote;

    QuoteLineItem quoteLineItem1 = new QuoteLineItem();
    quoteLineItem1.Product2Id = product1.Id;
    quoteLineItem1.Quantity = 1;
    quoteLineItem1.Description = 'Test qli description';
    quoteLineItem1.QuoteId = quote.Id;
    quoteLineItem1.UnitPrice = 9000;
    quoteLineItem1.PricebookEntryId = pricebookEntry.Id;
    insert quoteLineItem1;

    Test.stopTest();

    Concesionario__c concesionario = new Concesionario__c();
    concesionario.Name = 'Concesionario 1';
    concesionario.Codigo_de_agencia__c = 'CodigoAgencia';
    concesionario.Codigo_concesionario__c = 'CONC1';
    insert concesionario;

    Miembro_de_Concesionario__c miembroDeConcesionario = new Miembro_de_Concesionario__c();
    miembroDeConcesionario.Concesionario__c = concesionario.Id;
    miembroDeConcesionario.Nombre_de_asesor__c = UserInfo.getUserId();
    insert miembroDeConcesionario;
  }

  // private static Map<String, Object> mock() {
  //   Map<String, Object> objects = new Map<String, Object>();

  //   Id recordTypeAccountPersonaNaturalMoto = Schema.SObjectType.Account.getRecordTypeInfosByName()
  //     .get('Motos Persona Natural')
  //     .getRecordTypeId();
  //   Account account = new Account();
  //   account.RecordTypeId = recordTypeAccountPersonaNaturalMoto;
  //   account.Salutation = 'Sr.';
  //   account.FirstName = '1stName';
  //   account.LastName = '2ndName';
  //   account.PersonEmail = 'test@fastcloudconsulting.com';
  //   account.AccountSource = 'Web';
  //   account.BillingCountry = 'Nicaragua';
  //   account.BillingStreet = 'Billing st';
  //   account.Phone = '85724343';
  //   insert account;
  //   objects.put('account', account);

  //   Pricebook2 pricebook = new Pricebook2();
  //   pricebook.Name = 'Test pricebook';
  //   pricebook.IsActive = true;
  //   insert pricebook;
  //   objects.put('pricebook', pricebook);

  //   Id recordTypeOpportunityMoto = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
  //     .get('Motos Opportunity Layout')
  //     .getRecordTypeId();
  //   Opportunity opportunity = new Opportunity();
  //   opportunity.RecordTypeId = recordTypeOpportunityMoto;
  //   opportunity.AccountId = account.Id;
  //   opportunity.Name = 'Test opportunity';
  //   opportunity.StageName = 'New';
  //   opportunity.CloseDate = Date.newInstance(2022, 1, 1);
  //   insert opportunity;
  //   objects.put('opportunity', opportunity);
  //   // opportunity.Pricebook2Id is null at this point...

  //   Id pricebookId = Test.getStandardPricebookId(); // https://releasenotes.docs.salesforce.com/en-us/summer14/release-notes/rn_apex_price_books_in_tests.htm
  //   opportunity.Pricebook2Id = pricebookId;
  //   update opportunity;
  //   //Pricebook2 standardPB = [SELECT id FROM Pricebook2 WHERE isStandard = true AND isActive=true LIMIT 1]; //
  //   //Id pricebookId = opportunity.Pricebook2Id; // this is set by the Flow Opportunity Creation
  //   objects.put('pricebookId', pricebookId);

  //   Id recordTypeQuoteMoto = Schema.SObjectType.Quote.getRecordTypeInfosByName()
  //     .get('Cotizaciones Motos')
  //     .getRecordTypeId();
  //   Quote quote = new Quote();
  //   quote.OwnerId = UserInfo.getUserId();
  //   quote.OpportunityId = opportunity.Id;
  //   quote.Name = 'Test quote';
  //   quote.RecordTypeId = recordTypeQuoteMoto;
  //   insert quote;
  //   objects.put('quote', quote);

  //   Product2 product1 = new Product2();
  //   product1.Name = 'Test product 1';
  //   product1.Beneficios__c = 'Beneficio 1\nBeneficio 2';
  //   product1.La_motocicleta_se_entregan_con__c = 'Entrega con 1\nEntrega con 2';
  //   product1.IsActive = true;
  //   insert product1;
  //   objects.put('product1', product1);

  //   Product2 product22 = new Product2();
  //   product22.Name = 'Test product 2';
  //   product22.Beneficios__c = 'Beneficio 1\nBeneficio 2';
  //   product22.La_motocicleta_se_entregan_con__c = 'Entrega con 1\nEntrega con 2';
  //   product22.IsActive = true;
  //   insert product22;
  //   objects.put('product2', product22);

  //   PricebookEntry pricebookEntry = new PricebookEntry();
  //   pricebookEntry.Product2Id = product1.Id;
  //   pricebookEntry.IsActive = true;
  //   pricebookEntry.UnitPrice = 50;
  //   pricebookEntry.Pricebook2Id = pricebookId;
  //   insert pricebookEntry;
  //   objects.put('pricebookEntry', pricebookEntry);

  //   PricebookEntry pricebookEntry2 = new PricebookEntry();
  //   pricebookEntry2.Product2Id = product22.Id;
  //   pricebookEntry2.IsActive = true;
  //   pricebookEntry2.UnitPrice = 50;
  //   pricebookEntry2.Pricebook2Id = pricebookId;
  //   insert pricebookEntry2;
  //   objects.put('pricebookEntry2', pricebookEntry2);

  //   List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
  //   QuoteLineItem quoteLineItem1 = new QuoteLineItem();
  //   quoteLineItem1.Product2Id = product1.Id;
  //   quoteLineItem1.Quantity = 1;
  //   quoteLineItem1.Description = 'Test qli description';
  //   quoteLineItem1.QuoteId = quote.Id;
  //   quoteLineItem1.UnitPrice = 50;
  //   quoteLineItem1.PricebookEntryId = pricebookEntry.Id;
  //   insert quoteLineItem1;
  //   quoteLineItems.add(quoteLineItem1);

  //   QuoteLineItem quoteLineItem2 = new QuoteLineItem();
  //   quoteLineItem2.Product2Id = product22.Id;
  //   quoteLineItem2.Description = 'Test qli description';
  //   quoteLineItem2.QuoteId = quote.Id;
  //   quoteLineItem2.UnitPrice = 100;
  //   quoteLineItem2.Quantity = 1;
  //   quoteLineItem2.PricebookEntryId = pricebookEntry.Id;
  //   insert quoteLineItem2;
  //   quoteLineItems.add(quoteLineItem2);
  //   objects.put('quoteLineItems', quoteLineItems);

  //   return objects;
  // }

  @isTest
  static void init() {
    Quote quote = [SELECT Id FROM Quote LIMIT 1];

    Test.startTest();

    ApexPages.currentPage().getParameters().put('id', quote.Id);
    QuotePDFController controller = new QuotePDFController();

    Test.stopTest();
  }

  @isTest
  static void getLastWorkDayOfMonth() {
    Quote quote = [SELECT Id FROM Quote LIMIT 1];

    Test.startTest();

    DateTime quoteCreatedDate = DateTime.newInstance(2021, 4, 30);

    ApexPages.currentPage().getParameters().put('id', quote.Id);
    QuotePDFController controller = new QuotePDFController();
    Date lastWorkDayOfMonth = QuotePDFController.getLastWorkDayOfMonth(
      quoteCreatedDate
    );

    System.assertEquals(quoteCreatedDate.day(), lastWorkDayOfMonth.day());
    System.assertEquals(quoteCreatedDate.month(), lastWorkDayOfMonth.month());
    System.assertEquals(quoteCreatedDate.year(), lastWorkDayOfMonth.year());

    Test.stopTest();
  }
}