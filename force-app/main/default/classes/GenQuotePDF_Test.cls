@IsTest
public class GenQuotePDF_Test {
  private static Map<String, Object> objects = new Map<String, Object>();

  private static Quote makeDataQuoteAndQuoteLineItem(Boolean isAutos){
    
    Opportunity opp = (Opportunity) objects.get('opportunity');
    Pricebook2 pricebk = (Pricebook2) objects.get('pricebook');

    String quoteRtDevName = isAutos ? Label.RTQuoteAutos : Label.Cotizacion_Motos;
    Quote q = new Quote();
    q.OpportunityId = opp.Id; //[select Id from Opportunity limit 1].Id;
    q.Pricebook2Id = pricebk.Id; //standardPricebook.Id;
    q.RecordTypeId = [
      SELECT Id
      FROM RecordType
      WHERE developerName = :quoteRtDevName
    ]
    .Id;
    q.OwnerId = UserInfo.getUserId();
    q.Name = 'Nombre';
    q.Tipo_de_Pago__c = '101';
    q.Status = 'Cotización aceptada';
    q.Quote_PDF_Generado__c = true;
    q.Realizo_consulta_de_precios__c = true;
    insert q;
    objects.put('quote', q);
    
    Product2 producto = (Product2) objects.get('product');
    PricebookEntry pbentry = (PricebookEntry) objects.get('pricebookEntry');

    QuoteLineItem qli = new QuoteLineItem();
    qli.QuoteId = q.Id; //[select Id from Quote limit 1].Id;
    qli.Product2Id = producto.ID; //[select Id from Product2 limit 1].Id;
    qli.PricebookEntryId = pbentry.Id; //[select Id from PriceBookEntry limit 1].Id;
    qli.Quantity = 132;
    qli.Valor_soat__c = 2343902;
    qli.Valor_matrcula__c = 12334;
    qli.Cuota_Inicial__c = 12334;
    qli.Valor_seguro_robo__c = 12334;
    qli.Descuento_Valor__c = 23;
    qli.UnitPrice = 12334;
    insert qli;
    objects.put('quoteLineItem', qli);

    return q;
  }

  private static RecordType makeDataGetProductRT(Boolean isAutos){
    String productRtDevName = isAutos ? 'Autos' : 'Motos';
    RecordType productRecordType = [
      SELECT Id
      FROM RecordType
      WHERE developerName = :productRtDevName  AND sobjecttype = 'Product2'
      LIMIT 1
    ];

    return productRecordType;
  }

  private static void makeDataContentDocumentLink(){
    
    ContentVersion contentVersion = new ContentVersion(
      Title = 'Penguins',
      PathOnClient = 'Penguins.jpg',
      VersionData = Blob.valueOf('Test Content'),
      IsMajorVersion = true
    );
    insert contentVersion;

    List<ContentDocument> documents = [
      SELECT Id, Title, LatestPublishedVersionId
      FROM ContentDocument
    ];

    //create ContentDocumentLink  record
    Quote q = (Quote) objects.get('quote');

    ContentDocumentLink cdl = new ContentDocumentLink();
    cdl.LinkedEntityId = q.id;
    cdl.ContentDocumentId = documents[0].Id;
    cdl.shareType = 'V';
    insert cdl;
  }

  private static void makeDataHelper(Boolean isAutos, Account personaNaturalAccount, Opportunity opp, String productRecordTypeId, Boolean isOpportunityWithOrder, Boolean isInsertingOLI){

    objects.put('account', personaNaturalAccount);
    objects.put('opportunity', opp);

    if(isOpportunityWithOrder){
      Order order1 = new Order();
      order1.AccountId = personaNaturalAccount.Id;
      order1.Status = 'Draft';
      order1.OpportunityId = opp.Id;
      order1.EffectiveDate = Date.today();
      insert order1;
      objects.put('order', order1);
    }

    Pricebook2 pricebk = new Pricebook2();
    pricebk.Name = 'PB test';
    pricebk.IsActive = true;
    insert pricebk;
    objects.put('pricebook', pricebk);

    if(isAutos){
      Pricebook2 pb = New Pricebook2();
        pb.Name = 'Precios Usados';
        pb.IsActive = true;
        insert pb;
        objects.put('pricebookUsados', pb);
    }

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Product2 producto = new Product2();
    producto.RecordTypeId = productRecordTypeId;
    producto.Name = 'Honda CRV Test';
    producto.ProductCode = '001';
    producto.IsActive = true;

    if(isAutos){
      // Inventario_de_Usados__c i = new Inventario_de_Usados__c();
      // i.Color__c = 'Test';
      // insert i;

      // producto.Inventario_de_Usados__c = i.Id;
    }

    insert producto;
    objects.put('product', producto);

    if (
      // [
      //   SELECT id
      //   FROM PricebookEntry
      //   WHERE
      //     Product2Id = :producto.Id
      //     AND Pricebook2Id = :Test.getStandardPricebookId()
      // ]
      // .size() == 0
      false
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
    objects.put('pricebookEntry', pbentry);

    if(isInsertingOLI){
      OpportunityLineItem oli = new OpportunityLineItem();
      oli.OpportunityId = opp.Id;
      oli.Product2Id = producto.ID;
      oli.PricebookEntryId = pbentry.Id;
      oli.Quantity = 132;
      oli.Valor_soat__c = '2343902';
      oli.Valor_matrcula__c = 12334;
      oli.Cuota_Inicial__c = 12334;
      oli.Valor_seguro_robo__c = 12334;
      oli.Descuento_Valor__c = 23;
      oli.UnitPrice = 12334;
  
      insert oli;
    }
  }

  static void makeDataMotos(String productRecordTypeId, Boolean isOpportunityWithOrder, Boolean isInsertingOLI) {

    TriggerHandler.bypass('AccountTriggerHandler');
    Triggerhandler.bypass('OpportunityTriggerHandler');
    Triggerhandler.bypass('QuoteTriggerHandler');
    Triggerhandler.bypass('TaskTriggerHandler');
    
    List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account personaNaturalAccountMotos = accounts[0];

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    Opportunity oppMotos = opps[0];

    makeDataHelper(false, personaNaturalAccountMotos, oppMotos, productRecordTypeId, isOpportunityWithOrder, isInsertingOLI);
  }

  static void makeDataAutos(String productRecordTypeId, Boolean isOpportunityWithOrder, Boolean isInsertingOLI) {

    TriggerHandler.bypass('AccountTriggerHandler');
    Triggerhandler.bypass('OpportunityTriggerHandler');
    Triggerhandler.bypass('QuoteTriggerHandler');
    Triggerhandler.bypass('TaskTriggerHandler');

    TestDataUtilityClass.crearConcesionarios(1);
    Concesionario__c concesionario = TestDataUtilityClass.mapConcesionarios.get(1);

    Miembro_de_Concesionario__c miembroDeConcesionario = new Miembro_de_Concesionario__c();
    miembroDeConcesionario.Concesionario__c = concesionario.Id;
    miembroDeConcesionario.Nombre_de_asesor__c = UserInfo.getUserId();
    insert miembroDeConcesionario;
    objects.put('miembroDeConcesionario', miembroDeConcesionario);

    List<Account> accounts = TestDataUtilityClass.crearCuentasAutos(
      1,
      Label.AutosRecordTypeDevNameAccountNatural
    );
    Account personaNaturalAccountAutos = accounts[0];

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadAutos(1);
    Opportunity oppAutos = opps[0];

    makeDataHelper(true, personaNaturalAccountAutos, oppAutos, productRecordTypeId, isOpportunityWithOrder, isInsertingOLI);
  }

  @IsTest
  static void sendEmailWithAttachment() {

    Boolean isAutos = false;
    Boolean isOpportunityWithOrder = true;
    Boolean isInsertingOLI = false;
    RecordType productRecordType = makeDataGetProductRT(isAutos);
    makeDataMotos(productRecordType.Id, isOpportunityWithOrder, isInsertingOLI);
    makeDataQuoteAndQuoteLineItem(isAutos);
    makeDataContentDocumentLink();

    Test.startTest();
    

    Quote quote = (Quote) objects.get('quote');
    // Quote quote = [SELECT Id FROM Quote ORDER BY CreatedDate ASC LIMIT 1];

    ApexPages.currentPage().getParameters().put('Id', quote.id);
    ApexPages.StandardController stdController = new ApexPages.StandardController(
      quote
    );
    new GenQuotePDF(stdController).sendEmail();
    Test.stopTest();
  }


  @IsTest
  static void sendEmailWithoutAttachment() {

    Boolean isAutos = false;
    Boolean isOpportunityWithOrder = true;
    Boolean isInsertingOLI = false;
    RecordType productRecordType = makeDataGetProductRT(isAutos);
    makeDataMotos(productRecordType.Id, isOpportunityWithOrder, isInsertingOLI);
    makeDataQuoteAndQuoteLineItem(isAutos);

    Test.startTest();
    

    Quote quote = (Quote) objects.get('quote');
    // Quote quote = [SELECT Id FROM Quote ORDER BY CreatedDate ASC LIMIT 1];

    ApexPages.currentPage().getParameters().put('Id', quote.id);
    ApexPages.StandardController stdController = new ApexPages.StandardController(
      quote
    );
    new GenQuotePDF(stdController).sendEmail();
    Test.stopTest();
  }

  @IsTest
  static void saveQuoteDocumentMotos() {

    Boolean isAutos = false;
    Boolean isOpportunityWithOrder = true;
    Boolean isInsertingOLI = true;
    RecordType productRecordType = makeDataGetProductRT(isAutos);
    makeDataMotos(productRecordType.Id, isOpportunityWithOrder, isInsertingOLI);

    Test.startTest();

    makeDataQuoteAndQuoteLineItem(isAutos);

    Quote quote = (Quote) objects.get('quote');
    // Quote quote = [SELECT Id FROM Quote ORDER BY CreatedDate ASC LIMIT 1];

    ApexPages.currentPage().getParameters().put('Id', quote.id);
    ApexPages.StandardController stdController = new ApexPages.StandardController(
      quote
    );
    new GenQuotePDF(stdController).saveQuoteDocument();
    Test.stopTest();
  }


  @IsTest
  static void saveQuoteDocumentAutos() {

    User thisUser = [SELECT Id FROM User WHERE Profile.Name = :Label.Autos_Nombre_Perfil_Asesores_Autos AND ManagerId <> null AND IsActive = true LIMIT 1]; 

    Boolean isAutos = true;
    Boolean isOpportunityWithOrder = true;
    Boolean isInsertingOLI = false;

    System.runAs ( thisUser ) {
      RecordType productRecordType = makeDataGetProductRT(isAutos);
      makeDataAutos(productRecordType.Id, isOpportunityWithOrder, isInsertingOLI);
    }

    Test.startTest();

    makeDataQuoteAndQuoteLineItem(isAutos);

    Quote quote = (Quote) objects.get('quote');
    // Quote quote = [SELECT Id FROM Quote ORDER BY CreatedDate DESC LIMIT 1];

    ApexPages.currentPage().getParameters().put('Id', quote.id);
    ApexPages.StandardController stdController = new ApexPages.StandardController(
      quote
    );
    new GenQuotePDF(stdController).saveQuoteDocument();
    Test.stopTest();
  }

  @IsTest
  static void sendToNodriza() {

    User thisUser = [SELECT Id FROM User WHERE Profile.Name =: Label.Autos_Nombre_Perfil_Asesores_Autos AND ManagerId <> null AND IsActive = true LIMIT 1]; 

    Boolean isAutos = true;
    Boolean isOpportunityWithOrder = false;
    Boolean isInsertingOLI = false;

    System.runAs ( thisUser ) {
      RecordType productRecordType = makeDataGetProductRT(isAutos);
      makeDataAutos(productRecordType.Id, isOpportunityWithOrder, isInsertingOLI);
    }
    
    Test.startTest();
      makeDataQuoteAndQuoteLineItem(isAutos);

      Quote quote = (Quote) objects.get('quote');
      // Quote quote = [SELECT Id FROM Quote ORDER BY CreatedDate ASC LIMIT 1];

      ApexPages.currentPage().getParameters().put('Id', quote.id);
      ApexPages.StandardController stdController = new ApexPages.StandardController(
        quote
      );
      Test.setMock(HttpCalloutMock.class, new EnviarQuoteHaciaNodriza_Mock(1));
      new GenQuotePDF(stdController).sendToNodriza();
    Test.stopTest();
  }
}