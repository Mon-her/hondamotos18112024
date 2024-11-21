@isTest
public class EnviarQuoteHaciaNodriza_Test {
  @TestSetup
  static void makeData() {
      //Triggerhandler.bypass('QuoteTriggerHandler');
      Triggerhandler.bypass('AccountTriggerHandler');
      Triggerhandler.bypass('TaskTriggerHandler');
      TriggerStopper.stopOppLine = true;
      Triggerstopper.stopQuoteLine = true;
      TriggerStopper.stopOpp = true;
      TriggerStopper.stopQuote = true;
      
    TestDataUtilityClass.crearCuentasAutos(
      1,
      Label.AutosRecordTypeDevNameAccountNatural
    );
    TestDataUtilityClass.crearConcesionarios(1);
    TestDataUtilityClass.crearMiembroConcesionarios(1);
      
      
      Pricebook2 standardPricebook = new Pricebook2(
          Id = Test.getStandardPricebookId(),
          IsActive = true
        );
        update standardPricebook;
          
    TestDataUtilityClass.crearOportunidadAutos(1);
    TestDataUtilityClass.crearQuoteAutos(1);

    // Quote q = TestDataUtilityClass.mapQuotesAutos.get(1);
    // q.Creado_Prolibu__c = true;
    // update q;
  }

  @IsTest
  static void send() {
    Quote utilQuote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];

     
      
    insertQLI(utilQuote.Id);

      Test.startTest();
    Quote quote = GenQuotePDF.genQuoteToSendToNodriza(utilQuote.Id);
    Date quoteExpirationDate = QuotePDFController.getLastWorkDayOfMonth(
      quote.CreatedDate
    );

    //Test.startTest();

    Test.setMock(HttpCalloutMock.class, new EnviarQuoteHaciaNodriza_Mock(1));

    EnviarQuoteHaciaNodriza.send(quote, quoteExpirationDate);

    Test.stopTest();
  }

  // private static void insertOLI(String opportunityId) {
  //   RecordType rtProductoAutos = [
  //     SELECT Id, name
  //     FROM recordType
  //     WHERE sobjecttype = 'Product2' AND name LIKE '%auto%'
  //     LIMIT 1
  //   ];

  //   Product2 producto = new Product2();
  //   producto.Name = 'Honda CRV Test';
  //   producto.ProductCode = '001';
  //   producto.IsActive = true;
  //   producto.RecordTypeId = rtProductoAutos.Id;
  //   // producto.Inventario_de_Usados__c = i.Id;
  //   insert producto;

  //   Pricebook2 standardPricebook = new Pricebook2(
  //     Id = Test.getStandardPricebookId(),
  //     IsActive = true
  //   );
  //   update standardPricebook;

  //   PriceBookEntry pbentry = new PriceBookEntry();
  //   pbentry.Pricebook2Id = standardPricebook.Id;
  //   pbentry.Product2Id = producto.Id;
  //   pbentry.IsActive = true;
  //   pbentry.UnitPrice = 123;
  //   insert pbentry;

  //   OpportunityLineItem oli = new OpportunityLineItem();
  //   oli.OpportunityId = opportunityId;
  //   oli.Product2Id = producto.ID;
  //   oli.PricebookEntryId = pbentry.Id;
  //   oli.Quantity = 132;
  //   oli.Valor_soat__c = '2343902';
  //   oli.Valor_matrcula__c = 12334;
  //   oli.Cuota_Inicial__c = 12334;
  //   oli.Valor_seguro_robo__c = 12334;
  //   oli.Descuento_Valor__c = 23;
  //   oli.UnitPrice = 12334;

  //   insert oli;
  // }

  private static void insertQLI(String quoteId) {
    RecordType rtProductoAutos = [
      SELECT Id, name
      FROM recordType
      WHERE sobjecttype = 'Product2' AND name LIKE '%auto%'
      LIMIT 1
    ];

    //Pricebook2 standardPricebook = new Pricebook2(
    //  Id = Test.getStandardPricebookId(),
    //  IsActive = true
    //);
    //update standardPricebook;
      
    Product2 producto = new Product2();
    producto.Name = 'Honda CRV Test';
    producto.ProductCode = '001';
    producto.IsActive = true;
    producto.RecordTypeId = rtProductoAutos.Id;
    // producto.Inventario_de_Usados__c = i.Id;
    insert producto;

    PriceBookEntry pbentry = [select Id,pricebook2Id from PriceBookEntry where Product2Id=:producto.Id and isACtive=true limit 1];//new PriceBookEntry();
    /*pbentry.Pricebook2Id = standardPricebook.Id;
    pbentry.Product2Id = producto.Id;
    pbentry.IsActive = true;
    pbentry.UnitPrice = 123;
    insert pbentry;*/
   //   system.debug(pbentry);
   Quote q = [select id, pricebook2id, pricebook2.name from quote where id=:quoteId];
   q.Pricebook2Id = pbentry.pricebook2id;
   update q;
   // system.debug(q);
      
    QuoteLineItem oli = new QuoteLineItem();
    oli.QuoteId = quoteId;
    oli.Product2Id = producto.ID;
    oli.PricebookEntryId = pbentry.Id;
    oli.Quantity = 132;
    oli.Valor_soat__c = 2343902;
    oli.Valor_matrcula__c = 12334;
    oli.Cuota_Inicial__c = 12334;
    oli.Valor_seguro_robo__c = 12334;
    oli.Descuento_Valor__c = 23;
    oli.UnitPrice = 12334;

    insert oli;
  }
}