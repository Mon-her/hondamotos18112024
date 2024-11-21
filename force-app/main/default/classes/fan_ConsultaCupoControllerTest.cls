@IsTest
public class fan_ConsultaCupoControllerTest {
  @testSetup
  static void setup() {
    INSERT fan_B2BTestDataFactory.buildServiceEndpoint('Fanalca', 'host', 'test', '123');

    Account account = fan_B2BTestDataFactory.createAccount('123456789', 'NIT');
    WebStore webStore = fan_B2BTestDataFactory.createWebStore('WebStore Test');
    WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, 'credito');

    Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', 'PRODUCTCODE-1', null);

    String pricebookId = Test.getStandardPricebookId();
    PricebookEntry pricebookEntry = fan_B2BTestDataFactory.createPricebookEntry(pricebookId, product.Id, 23.7);

    Order order = fan_B2BTestDataFactory.createOrder(account.Id, pricebookId);
    fan_B2BTestDataFactory.createOrderItem(order.Id, product.Id, pricebookEntry.Id, 31, 434, 14);

    fan_B2BTestDataFactory.createCartCheckoutSession(order.Id, webCart.Id);

    Account account2 = fan_B2BTestDataFactory.createAccount('987654321', 'NIT');
    WebCart webCart2 = fan_B2BTestDataFactory.createWebCart(webStore.Id, account2.Id, 'credito');
    fan_B2BTestDataFactory.createCartCheckoutSession(order.Id, webCart2.Id);
  }

  @IsTest
  static void getQuotaDetails() {

    String nitCliente = [SELECT AccountNumber FROM Account LIMIT 1].AccountNumber;

    Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());

    Test.startTest();
    fan_ConsultaCupoController.QuotaDetail quotaDetail = fan_ConsultaCupoController.getQuotaDetails(nitCliente);
    Test.stopTest();

    Assert.areEqual(100.1, quotaDetail.assignedCreditCapacity, 'The assignedCreditCapacity is not as expected.');
    Assert.areEqual(79.9, quotaDetail.availableCreditCapacity, 'The availableCreditCapacity is not as expected.');
    Assert.areEqual(10.1, quotaDetail.advancedBalanceFavor, 'The advancedBalanceFavor is not as expected.');
    Assert.areEqual(0, quotaDetail.consignedValue, 'The consignedValue is not as expected.');
  }

  @IsTest
  static void resolveOrderSummaryStatusWithPsePaymentMethod() {

    UPDATE new WebCart(
      Id = [SELECT Id FROM WebCart][0].Id,
      fan_MetodoPago__c = 'PSE'
    );
    CartCheckoutSession cartCheckoutSession = [SELECT WebCart.fan_MetodoPago__c FROM CartCheckoutSession][0];

    String status = fan_ConsultaCupoController.resolveOrderSummaryStatus(cartCheckoutSession);

    Assert.areEqual('APROBADO', status, 'The status is not as expected.');
  }

  @IsTest
  static void resolveOrderSummaryStatusWithRedAvalPaymentMethod() {

    UPDATE new WebCart(
      Id = [SELECT Id FROM WebCart][0].Id,
      fan_MetodoPago__c = 'RED_AVAL'
    );
    CartCheckoutSession cartCheckoutSession = [SELECT WebCart.fan_MetodoPago__c FROM CartCheckoutSession][0];

    String status = fan_ConsultaCupoController.resolveOrderSummaryStatus(cartCheckoutSession);

    Assert.areEqual('WAITING FOR PAYMENT', status, 'The status is not as expected.');
  }

  @IsTest
  static void resolveOrderSummaryStatusWithTarjetaPaymentMethod() {

    UPDATE new WebCart(
      Id = [SELECT Id FROM WebCart][0].Id,
      fan_MetodoPago__c = 'Tarjeta'
    );
    CartCheckoutSession cartCheckoutSession = [SELECT WebCart.fan_MetodoPago__c FROM CartCheckoutSession][0];

    String status = fan_ConsultaCupoController.resolveOrderSummaryStatus(cartCheckoutSession);

    Assert.areEqual('APROBADO', status, 'The status is not as expected.');
  }

  @IsTest
  static void resolveOrderSummaryStatusWithInsufficientQuota() {

    CartCheckoutSession cartCheckoutSession = [SELECT Order.fan_TipoPedido__c, Order.GrandTotalAmount, WebCart.fan_EsAnticipo__c, TYPEOF WebCart.Account WHEN Account THEN Parent.Id, AccountNumber, Parent.AccountNumber END, WebCart.AccountId, WebCart.fan_FormaPago__c, WebCart.fan_MetodoPago__c  FROM CartCheckoutSession][1];
    Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());

    Test.startTest();
    String status = fan_ConsultaCupoController.resolveOrderSummaryStatus(cartCheckoutSession);
    Test.stopTest();

    Assert.areEqual('PENDING', status, 'The status is not as expected.');
  }

  @IsTest
  static void resolveOrderSummaryStatusWithOverdueInvoices() {

    CartCheckoutSession cartCheckoutSession = [SELECT Order.fan_TipoPedido__c, Order.GrandTotalAmount, WebCart.fan_EsAnticipo__c, TYPEOF WebCart.Account WHEN Account THEN Parent.Id, AccountNumber, Parent.AccountNumber END, WebCart.AccountId, WebCart.fan_FormaPago__c, WebCart.fan_MetodoPago__c  FROM CartCheckoutSession][0];

    fan_ConsultaCupoMock.VALOR_VCTO_SIN_CO = '20';
    Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());

    Test.startTest();
    String status = fan_ConsultaCupoController.resolveOrderSummaryStatus(cartCheckoutSession);
    Test.stopTest();

    Assert.areEqual('LOCKED', status, 'The status is not as expected.');
  }

  @IsTest
  static void resolveOrderSummaryStatusRMT_GarantiaOrderType() {

    CartCheckoutSession cartCheckoutSession = [SELECT Order.fan_TipoPedido__c, Order.GrandTotalAmount, WebCart.fan_EsAnticipo__c, TYPEOF WebCart.Account WHEN Account THEN Parent.Id, AccountNumber, Parent.AccountNumber END, WebCart.AccountId, WebCart.fan_FormaPago__c, WebCart.fan_MetodoPago__c  FROM CartCheckoutSession][0];
    cartCheckoutSession.Order.fan_TipoPedido__c = fan_Constants.OrderType.RMT_GARANTIA.name();

    Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());

    Test.startTest();
    String status = fan_ConsultaCupoController.resolveOrderSummaryStatus(cartCheckoutSession);
    Test.stopTest();

    Assert.areEqual('APROBADO', status, 'The status is not as expected.');
  }

  // An exception is thrown because an OrderSummary is required.
  @IsTest
  static void validateOrderSummaryStatus() {
    try {
      String cartCheckoutSessionId = [SELECT Id FROM CartCheckoutSession][0].Id;
      Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());

      Test.startTest();
      fan_ConsultaCupoController.validateOrderSummaryStatus(new List<String> { cartCheckoutSessionId }); 
      Test.stopTest();
      Assert.fail('A FlowException was expected.');
    } catch (Exception e) {
      Assert.isInstanceOfType(e, FlowException.class, 'The exception type is not as expected.');
    }
  }
}