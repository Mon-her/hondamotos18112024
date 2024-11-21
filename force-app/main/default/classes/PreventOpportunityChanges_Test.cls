@isTest
public class PreventOpportunityChanges_Test {

  static Map<String, Object> objects = new Map<String, Object>();

  static void makeData() {
    TriggerHandler.bypass('AccountTriggerHandler');
    TriggerHandler.bypass('ContactTriggerHandler');
    Triggerhandler.bypass('OpportunityTriggerHandler');
    Triggerhandler.bypass('QuoteTriggerHandler');
    Triggerhandler.bypass('TaskTriggerHandler');
    Triggerhandler.bypass('OrderTriggerHandler');
    
    List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account personaNaturalAccount = accounts[0];
    objects.put('account', personaNaturalAccount);

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    Opportunity opp = opps[0];
    objects.put('opportunity', opp);

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

    Product2 prod = new Product2(
      RecordTypeId = recordTypeMoto.Id,
      Name = 'Product X',
      ProductCode = 'Pro-X',
      isActive = true
    );
    insert prod;
    objects.put('product', prod);

    if (
      // [
      //   SELECT id
      //   FROM PricebookEntry
      //   WHERE
      //     Product2Id = :prod.Id
      //     AND Pricebook2Id = :Test.getStandardPricebookId()
      // ]
      // .size() == 0
      false
    ) {
      PricebookEntry pbentrySt = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = prod.Id,
        UnitPrice = 1000,
        IsActive = true
      );
      insert pbentrySt;
    }

    //Create your pricebook entry
    PricebookEntry pbEntry = new PricebookEntry(
      Pricebook2Id = pricebk.Id,
      Product2Id = prod.Id,
      UnitPrice = 100.00,
      IsActive = true
    );
    insert pbEntry;

    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId = opp.Id,
      Quantity = 5,
      PricebookEntryId = pbEntry.Id,
      TotalPrice = 5 * pbEntry.UnitPrice
    );

    insert oli;

    Order order1 = new Order();
    order1.AccountId = personaNaturalAccount.Id;
    order1.Status = 'Draft';
    order1.OpportunityId = opp.Id;
    order1.EffectiveDate = Date.today();
    order1.Pricebook2Id = pricebk.Id;
    insert order1;
    objects.put('order', order1);

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

  @isTest
  private static void isOpportunityUpdatable() {
    makeData();
    
    Test.startTest();
    List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
    PreventOpportunityChanges.areOpportunitiesUpdatable(opportunities);
    Test.stopTest();
  }
}