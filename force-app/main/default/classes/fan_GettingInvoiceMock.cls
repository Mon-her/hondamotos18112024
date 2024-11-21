global class fan_GettingInvoiceMock implements WebServiceMock {
  global void doInvoke(
    Object stub,
    Object request,
    Map<String, Object> response,
    String endpoint,
    String soapAction,
    String requestName,
    String responseNS,
    String responseName,
    String responseType
  ) {
    fan_GettingInvoice.row_element row = new fan_GettingInvoice.row_element();
    row.CO = 'HRC';
    row.DOCUMENTO = 'A1234567';
    row.ORD_COMPRA = 'AXS1';
    row.FECHA = '2022-06-01';
    row.FECHA_VENCIMIENTO = '2022-06-01';
    row.DES_SUC_FANALCA = 'SUC';
    row.DES_COND_PAGO = 'COND';
    row.PEDIDO = 'XAX1';
    row.VALOR_NETO = '100';
    row.ESTADO_DOCUMENTO = '100';

    fan_GettingInvoice.row_element[] rows = new List<fan_GettingInvoice.row_element>();
    rows.add(row);

    fan_GettingInvoice.DT_Facturas_Rsp res = new fan_GettingInvoice.DT_Facturas_Rsp();
    res.row = rows;

    response.put('response_x', res);
  }
}