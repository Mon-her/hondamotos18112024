@isTest
public class fan_BillReportControllerTest {
  @testSetup
  static void setup() {
    fan_ServiceEndpoint__c settings = new fan_ServiceEndpoint__c(
      usuario__c = 'test',
      url__c = 'host',
      Nombre__c = 'Fanalca',
      contrasena__c = '123'
    );

    insert settings;
  }
  @isTest
  static void testGetInvoices() {
    Test.setMock(WebServiceMock.class, new fan_GettingInvoiceMock());

    Test.startTest();
    fan_BillReportController.Invoice[] invoices = fan_BillReportController.getInvoices(
      '123456789',
      '2022-06-01',
      '2022-06-01'
    );

    Test.stopTest();

    System.assertEquals('A1234567', invoices[0].billId, 'billId is DOCUMENTO.');
    System.assertEquals(
      'AXS1',
      invoices[0].buyingOrderId,
      'buyingOrderId is ORD_COMPRA.'
    );
    System.assertEquals(
      '2022-06-01',
      invoices[0].billDate,
      'billDate is FECHA.'
    );
    System.assertEquals(
      '2022-06-01',
      invoices[0].expirationDate,
      'expirationDate is FECHA_VENCIMIENTO.'
    );
    System.assertEquals(
      'SUC',
      invoices[0].branchStore,
      'branchStore is DES_SUC_FANALCA.'
    );
    System.assertEquals(
      'COND',
      invoices[0].paymentCondition,
      'paymentCondition is DES_COND_PAGO.'
    );
    System.assertEquals(
      'XAX1',
      invoices[0].orderNumber,
      'orderNumber is PEDIDO.'
    );
    System.assertEquals('100', invoices[0].netValue, 'netValue is VALOR_NETO.'
    );
    System.assertEquals('100', invoices[0].valorfactura, 'valorfactura is ESTADO_DOCUMENTO.');
    
  }
}