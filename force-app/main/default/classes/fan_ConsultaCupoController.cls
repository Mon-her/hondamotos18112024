public with sharing class fan_ConsultaCupoController {

  enum FormaPago { CREDITO } 
  enum MetodoPago { PSE, RED_AVAL, BCO_BOGOTA_OFC, TARJETA }

  class Store {
    @AuraEnabled
    public String name;
    @AuraEnabled
    public Decimal expiredWallet;
    @AuraEnabled
    public Decimal walletTotal;
    @AuraEnabled
    public Decimal dispatchmentOrder;
    @AuraEnabled
    public Decimal pendingPaymentOrders;
  }

  public class QuotaDetail {
    @AuraEnabled
    public Decimal assignedCreditCapacity;
    @AuraEnabled
    public Decimal availableCreditCapacity;
    @AuraEnabled
    public Decimal advancedBalanceFavor;
    @AuraEnabled
    public Decimal consignedValue;
    @AuraEnabled
    public Map<String, Store> storeCreditCapacities;
  }

  @AuraEnabled
  public static QuotaDetail getQuotaDetails(String nitCliente) {
    try {
      fan_ConsultaCupo.row_element[] response = fan_ConsultaCupoHandler.getData(
        nitCliente
      );

      if (response.size() == 0) {
        throw new HandledException('No quota details were found');
      }

      fan_ConsultaCupo.row_element data = response[0];

      QuotaDetail detail = new QuotaDetail();

      detail.assignedCreditCapacity = convertToDecimal(data.CUPO);
      detail.availableCreditCapacity = fan_ConsultaCupoHandler.availableCredit(data);

      detail.advancedBalanceFavor = convertToDecimal(data.ANTICIPO_SIN_CO) * -1;

      detail.consignedValue = getConsignedValue(nitCliente, fan_Constants.OrderSummaryStatus.WAITING_FOR_PAYMENT.name().replace('_', ' '));

      Map<String, Store> storeCreditCapacities = new Map<String, Store>();
      // Get credit data for each store
      storeCreditCapacities.put('motorcycleStore', getMotorcycleStore(nitCliente, data));
      storeCreditCapacities.put('aftermarketStore', getAftermarketStore(nitCliente, data));

      detail.storeCreditCapacities = storeCreditCapacities;

      return detail;
    } catch (System.NullPointerException e) {
      System.debug(LoggingLevel.INFO, e.getMessage());
      return new QuotaDetail();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  private static Store getMotorcycleStore(String nitCliente, fan_ConsultaCupo.row_element data) {
    Store motorcycleStore = new Store();
    motorcycleStore.expiredWallet = convertToDecimal(data.VALOR_VCTO_HMC) + convertToDecimal(data.VALOR_VCTO_SIN_HOC);
    motorcycleStore.walletTotal = convertToDecimal(data.TOTAL_CARTERA_HMC) + convertToDecimal(data.TOTAL_CARTERA_HOC);
    motorcycleStore.dispatchmentOrder = convertToDecimal(data.PEDIDOS_COMPROMETIDOS_HMC) + convertToDecimal(data.PEDIDOS_COMPROMETIDOS_HOC) +
                                        convertToDecimal(data.REMISIONADO_NOFACTURADO_HMC) + convertToDecimal(data.REMISIONADO_NOFACTURADO_HOC);
    motorcycleStore.pendingPaymentOrders = getPendingPaymentOrders(nitCliente, 'motos');

    return motorcycleStore;
  }

  private static Store getAftermarketStore(String nitCliente, fan_ConsultaCupo.row_element data) {
    Store aftermarketStore = new Store();
    aftermarketStore.expiredWallet = convertToDecimal(data.VALOR_VCTO_HRC);
    aftermarketStore.walletTotal = convertToDecimal(data.TOTAL_CARTERA_HRC);
    aftermarketStore.dispatchmentOrder = convertToDecimal(data.PEDIDOS_COMPROMETIDOS_HCR) + convertToDecimal(data.REMISIONADO_NOFACTURADO_HCR);
    aftermarketStore.pendingPaymentOrders = getPendingPaymentOrders(nitCliente, 'posventa');

    return aftermarketStore;
  }

  private static Decimal convertToDecimal(string value) {
    Decimal decimalValue = Decimal.valueOf(String.isNotBlank(value) ? value : '0');
    return decimalValue;
  }

  private static String getSaleStoreId(String store) {
    fan_IdTienda__mdt[] stores;

    if (String.isNotBlank(store)) {
      stores = [
        SELECT fan_IdTienda__c
        FROM fan_IdTienda__mdt
        WHERE DeveloperName = :store
        LIMIT 1
      ];
    } else {
      stores = [
        SELECT fan_IdTienda__c
        FROM fan_IdTienda__mdt
        LIMIT 1
      ];
    }

    if (!Test.isRunningTest() && stores.size() == 0) {
      throw new HandledException('Store not found: ' + store);
    }

    String idStore = Test.isRunningTest() ? 'XXXXXXXX' : stores[0].fan_IdTienda__c;

    return idStore;
  }

  private static Decimal getPendingPaymentOrders(String nitCliente, String store) {
    String salesStoreId = getSaleStoreId(store);

    AggregateResult[] orders = [
      SELECT SUM(TotalAmount) pendingPaymentOrders
      FROM Order
      WHERE AccountId = :nitCliente AND SalesStoreId = :salesStoreId
      WITH SECURITY_ENFORCED
    ];

    if (orders[0].get('pendingPaymentOrders') == null) {
      return 0;
    }

    return (Decimal) orders[0].get('pendingPaymentOrders');
  }

  private static decimal getConsignedValue(String nitCliente, String status) {
    AggregateResult[] orderSummaries = [
      SELECT SUM(GrandTotalAmount) consignedValue
      FROM OrderSummary
      WHERE Account.AccountNumber = :nitCliente AND Status = :status
      WITH SECURITY_ENFORCED
    ];

    if (orderSummaries[0].get('consignedValue') == null) {
      return 0;
    }

    return (Decimal) orderSummaries[0].get('consignedValue');
  }

  @TestVisible
  static String resolveOrderSummaryStatus(CartCheckoutSession cartCheckoutSession) {
    String status;
    if(cartCheckoutSession.WebCart.fan_MetodoPago__c == MetodoPago.RED_AVAL.name() || cartCheckoutSession.WebCart.fan_MetodoPago__c == MetodoPago.BCO_BOGOTA_OFC.name()) {
      status = fan_Constants.OrderSummaryStatus.WAITING_FOR_PAYMENT.name().replace('_', ' ');
    } else if(cartCheckoutSession.WebCart.fan_MetodoPago__c == MetodoPago.PSE.name() ||cartCheckoutSession.WebCart.fan_MetodoPago__c == MetodoPago.TARJETA.name()) {
      status = fan_Constants.OrderSummaryStatus.APROBADO.name();
    } else if(cartCheckoutSession.WebCart.fan_FormaPago__c == FormaPago.CREDITO.name()) {

      String nitCliente = fan_B2BUtils.resolveAccountNumber(cartCheckoutSession.WebCart.AccountId);
      fan_ConsultaCupo.row_element[] response = fan_ConsultaCupoHandler.getData(nitCliente);

      Account account = (Account) cartCheckoutSession.WebCart.Account;
      fan_CuentasExcepcionCupo__mdt accountException = fan_CuentasExcepcionCupo__mdt.getInstance('X' + account.AccountNumber) ?? fan_CuentasExcepcionCupo__mdt.getInstance('X' + account.Parent.AccountNumber);

      fan_ConsultaCupoHandler.Order order = new fan_ConsultaCupoHandler.Order(cartCheckoutSession.Order, cartCheckoutSession.WebCart.fan_EsAnticipo__c);
      status = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(accountException, response, order);
    }
    return status;
  }

  @InvocableMethod(
    label = 'Validar Estado del Resumen de la Orden'
    description = 'Se actualizará el estado de la orden si (Cupo disponible es insuficiente) -> Bloqueado por cupo; (Clientes con facturas vencidas, sin Pagar) -> Bloqueado por mora; (Método de pago Red Aval) -> Pendiente de pago.'
    callout = true
    Category = 'B2B Commerce'
  )
  public static void validateOrderSummaryStatus(String[] cartCheckoutSessionId) {
    try {
      CartCheckoutSession cartCheckoutSession = [SELECT Order.fan_TipoPedido__c, Order.GrandTotalAmount, OrderId, WebCart.AccountId, WebCart.fan_FormaPago__c, WebCart.fan_MetodoPago__c, WebCart.fan_EsAnticipo__c, WebCartId, TYPEOF WebCart.Account WHEN Account THEN AccountNumber, Parent.AccountNumber END FROM CartCheckoutSession WHERE Id =: cartCheckoutSessionId[0] WITH SECURITY_ENFORCED];
      String status = resolveOrderSummaryStatus(cartCheckoutSession);
      
      if(status != null) {
        OrderSummary orderSummary = [SELECT Id FROM OrderSummary WHERE OriginalOrderId = :cartCheckoutSession.OrderId];
        orderSummary.Status = status;
        UPDATE orderSummary;
      }
    } catch (Exception e) {
      throw new FlowException(e.getMessage());
    }
  }

}