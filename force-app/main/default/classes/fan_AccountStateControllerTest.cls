@isTest
public class fan_AccountStateControllerTest {
  @testSetup
  static void setup() {
    fan_ServiceEndpoint__c settings = new fan_ServiceEndpoint__c(
      usuario__c = 'test',
      url__c = 'host',
      Nombre__c = 'Fanalca',
      contrasena__c = '123'
    );

    insert settings;

    Account account = new Account(
      Name = 'TestAccount',
      AccountNumber = '123456789',
      AM_Numero_de_documento__c = '123456789',
      AM_Tipo_de_documento__c = 'NIT'
    );
    insert account;
  }

  @isTest
  static void testGetAccountState() {
    Test.setMock(WebServiceMock.class, new fan_AccountStateMock());

    Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

    Test.startTest();
    fan_AccountStateController.Summary[] summaries = fan_AccountStateController.getAccountState(
      accountId
    );
    Test.stopTest();

    System.assertEquals('AXA1', summaries[0].code, 'code is CODIGO.');

    System.assertEquals(
      'lorem inpsum',
      summaries[0].description,
      'description is DESCRIPCION.'
    );

    System.assertEquals('1.0', summaries[0].current, 'current is CORRIENTE.');

    System.assertEquals(
      '1.0',
      summaries[0].expiryAmountShort,
      'expiryAmountShort is VENCIDO1A30.'
    );

    System.assertEquals(
      '1.0',
      summaries[0].expiryAmountMedium,
      'expiryAmountMedium is VENCIDO31A60.'
    );

    System.assertEquals(
      '1.0',
      summaries[0].expiryAmountLong,
      'expiryAmountLong is VENCIDO61A90.'
    );

    System.assertEquals(
      '1.0',
      summaries[0].expiryAmountMax,
      'expiryAmountMax is VENCIDO91MAS.'
    );
  }
}