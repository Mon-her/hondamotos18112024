public with sharing class fan_ConsultaCupoHandler {
  private static fan_ServiceEndpoint__c getSettings(String serviceName) {
    List<fan_ServiceEndpoint__c> settings = [
      SELECT usuario__c, url__c, Nombre__c, contrasena__c
      FROM fan_ServiceEndpoint__c
      WHERE Nombre__c = :serviceName];

    if (settings.size() == 0) {
      throw new HandledException('Settings not found to: ' + serviceName);
    }

    return settings[0];
  }

  public static fan_ConsultaCupo.row_element[] getData(String nitCliente) {
    fan_ServiceEndpoint__c settings = getSettings('Fanalca');

    fan_ConsultaCupo.HTTPS_Port port = new fan_ConsultaCupo.HTTPS_Port(
      settings.url__c
    );

    port.inputHttpHeaders_x = new Map<String, String>();

    Blob headerValue = Blob.valueOf(
      settings.usuario__c +
      ':' +
      settings.contrasena__c
    );
    String authorizationHeader =
      'Basic ' + EncodingUtil.base64Encode(headerValue);
    port.inputHttpHeaders_x.put('Authorization', authorizationHeader);
    port.inputHttpHeaders_x.put('Content-Type', 'text/xml');

    fan_ConsultaCupo.row_element[] rows = port.POST(nitCliente);

    return rows;
  }

  public static Decimal availableCredit(fan_ConsultaCupo.row_element details) {

    Decimal quota = Decimal.valueOf(
      String.isNotBlank(details.CUPO) ? details.CUPO : '0'
    );

    Decimal totalWalletWithOutCO = Decimal.valueOf(
      String.isNotBlank(details.TOTAL_CARTERA_SIN_CO)
        ? details.TOTAL_CARTERA_SIN_CO
        : '0'
    );

    Decimal committedOrders = Decimal.valueOf(
      String.isNotBlank(details.PEDIDOS_COMPROMETIDOS_SIN_CO)
        ? details.PEDIDOS_COMPROMETIDOS_SIN_CO
        : '0'
    );

    Decimal uninvoicedShippedNoOrder = Decimal.valueOf(
      String.isNotBlank(details.REMISIONADO_NOFACTURADO_SIN_CO)
        ? details.REMISIONADO_NOFACTURADO_SIN_CO
        : '0'
    );

    Decimal advanceWithoutCO = Decimal.valueOf(
      String.isNotBlank(details.ANTICIPO_SIN_CO)
        ? details.ANTICIPO_SIN_CO
        : '0'
    );

    return quota - 
      advanceWithoutCO -
      totalWalletWithOutCO - 
      committedOrders - 
      uninvoicedShippedNoOrder;
  }

  @TestVisible
  static String resolveOrderSummaryStatus(fan_ConsultaCupo.row_element[] quotaResponse, Decimal orderAmount) {

    String status = fan_Constants.OrderSummaryStatus.APROBADO.name();

    if(quotaResponse?.isEmpty() ?? true) {
      status = fan_Constants.OrderSummaryStatus.PENDING.name();
    } else {
      Decimal VALOR_VCTO_SIN_CO = Decimal.valueOf(quotaResponse[0].VALOR_VCTO_SIN_CO);
      Decimal ANTICIPO_SIN_CO = Decimal.valueOf(quotaResponse[0].ANTICIPO_SIN_CO);
      Decimal availableCredit = availableCredit(quotaResponse[0]);

      if(VALOR_VCTO_SIN_CO > -ANTICIPO_SIN_CO) {
        status = fan_Constants.OrderSummaryStatus.LOCKED.name();
      } else if(availableCredit < orderAmount || availableCredit < 0) {
        status = fan_Constants.OrderSummaryStatus.PENDING.name();
      }
    }
    return status;
  }

  public static String resolveOrderSummaryStatus(fan_CuentasExcepcionCupo__mdt accountException, fan_ConsultaCupo.row_element[] quotaResponse, Order order) {

    String status;
   
    // Account exception prevents withholding orders.
    if(accountException != null || order.isAdvance || order.type == fan_Constants.OrderType.RMT_GARANTIA.name()) {
      // The order is not blocked due to quota or arrears.
      status = fan_Constants.OrderSummaryStatus.APROBADO.name();
    } else { 
      status = resolveOrderSummaryStatus(quotaResponse, order.amount);
    }
    return status;
  }

  public class Order {
    String type;
    Decimal amount;
    Boolean isAdvance = false;

    public Order(Schema.Order order, Boolean isAdvance) {
      type = order.fan_TipoPedido__c;
      amount = order.GrandTotalAmount;
      this.isAdvance = isAdvance;
    }

    public Order(OrderSummary orderSummary) {
      type = orderSummary.fan_TipoPedido__c;
      amount = orderSummary.Total_Valor_Pendiente_Impuestos__c;
    }
  }
}