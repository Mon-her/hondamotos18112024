@IsTest
class fan_ConsultaCupoHandlerTest {

    @IsTest
    static void resolveOrderSummaryStatusWithAccountException() {

        fan_CuentasExcepcionCupo__mdt accountException = new fan_CuentasExcepcionCupo__mdt();
        fan_ConsultaCupo.row_element[] quotaResponse;
        OrderSummary orderSummary = new OrderSummary();

        fan_ConsultaCupoHandler.Order order = new fan_ConsultaCupoHandler.Order(orderSummary);
        String orderSummaryStatus = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(accountException, quotaResponse, order);

        Assert.areEqual('APROBADO', orderSummaryStatus, 'The orderSummaryStatus is not as expected.');
    }

    @IsTest
    static void resolveOrderSummaryStatusWithOrderTypeRMT_Garantia() {

        fan_CuentasExcepcionCupo__mdt accountException = new fan_CuentasExcepcionCupo__mdt();
        fan_ConsultaCupo.row_element[] quotaResponse;
        Map<String, String> orderSummaryData = new Map<String, String> { 'fan_TipoPedido__c' => 'RMT_Garantia' };
        OrderSummary orderSummary = (OrderSummary) JSON.deserialize(JSON.serialize(orderSummaryData), OrderSummary.class);

        fan_ConsultaCupoHandler.Order order = new fan_ConsultaCupoHandler.Order(orderSummary);
        String orderSummaryStatus = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(accountException, quotaResponse, order);

        Assert.areEqual('APROBADO', orderSummaryStatus, 'The orderSummaryStatus is not as expected.');
    }

    @IsTest
    static void resolveOrderSummaryStatusWithoutQuotaResponse() {

        fan_ConsultaCupo.row_element[] quotaResponse;
        Decimal orderGrandTotalAmount;

        String orderSummaryStatus = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(quotaResponse, orderGrandTotalAmount);

        Assert.areEqual('PENDING', orderSummaryStatus, 'The orderSummaryStatus is not as expected.');
    }

    @IsTest
    static void resolveOrderSummaryStatusShouldBlockTheOrder() {
        
        fan_ConsultaCupo.row_element row_element = new fan_ConsultaCupo.row_element();
        row_element.VALOR_VCTO_SIN_CO = '20';
        row_element.ANTICIPO_SIN_CO = '10.1';
        fan_ConsultaCupo.row_element[] quotaResponse = new fan_ConsultaCupo.row_element[] {
            row_element
        };
        Decimal orderGrandTotalAmount;

        String orderSummaryStatus = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(quotaResponse, orderGrandTotalAmount);

        Assert.areEqual('LOCKED', orderSummaryStatus, 'The orderSummaryStatus is not as expected.');
    }

    @IsTest
    static void resolveOrderSummaryStatusShouldHoldOrder() {

        fan_ConsultaCupo.row_element row_element = new fan_ConsultaCupo.row_element();
        row_element.CUPO = '0';
        row_element.TOTAL_CARTERA_SIN_CO = '0';
        row_element.PEDIDOS_COMPROMETIDOS_SIN_CO = '0';
        row_element.REMISIONADO_NOFACTURADO_SIN_CO = '0';
        row_element.VALOR_VCTO_SIN_CO = '0';
        row_element.ANTICIPO_SIN_CO = '0';
        fan_ConsultaCupo.row_element[] quotaResponse = new fan_ConsultaCupo.row_element[] {
            row_element
        };
        Decimal orderGrandTotalAmount = 5000;

        String orderSummaryStatus = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(quotaResponse, orderGrandTotalAmount);

        Assert.areEqual('PENDING', orderSummaryStatus, 'The orderSummaryStatus is not as expected.');
    }
}