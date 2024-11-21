@IsTest
global class fan_ConsultaCupoMock implements WebServiceMock {

  @TestVisible
  static String VALOR_VCTO_SIN_CO = '40.1';

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
    fan_ConsultaCupo.DT_NIT req= (fan_ConsultaCupo.DT_NIT) request;
    fan_ConsultaCupo.row_element row = new fan_ConsultaCupo.row_element();
    fan_ConsultaCupo.row_element[] rows = new List<fan_ConsultaCupo.row_element>();

    if (req.NITCLIENTE == '123456789') {
     row.NIT='123456789';
     row.CUPO='100.1';
     row.TOTAL_CARTERA_SIN_CO='10.1';
     row.VALOR_VCTO_SIN_CO=VALOR_VCTO_SIN_CO;
     row.ANTICIPO_SIN_CO='-10.1';
     row.TOTAL_CARTERA_HRC='10.1';
     row.VALOR_VCTO_HRC='10.1';
     row.TOTAL_CARTERA_HMC='10.1';
     row.VALOR_VCTO_HMC='10.1';
     row.TOTAL_CARTERA_HOC='10.1';
     row.VALOR_VCTO_SIN_HOC='10.1';
     row.PEDIDOS_COMPROMETIDOS_SIN_CO='10.1';
     row.PEDIDOS_COMPROMETIDOS_HCR='10.1';
     row.PEDIDOS_COMPROMETIDOS_HMC='10.1';
     row.PEDIDOS_COMPROMETIDOS_HOC='10.1';
     row.REMISIONADO_NOFACTURADO_SIN_CO='10.1';
     row.REMISIONADO_NOFACTURADO_HCR='10.1';
     row.REMISIONADO_NOFACTURADO_HMC='10.1';
     row.REMISIONADO_NOFACTURADO_HOC='10.1';
     rows.add(row);
    }

    if (req.NITCLIENTE == '987654321') {
     row.NIT='123456789';
     row.CUPO='100.1';
     row.TOTAL_CARTERA_SIN_CO='10.1';
     row.VALOR_VCTO_SIN_CO='10.1';
     row.ANTICIPO_SIN_CO='-10.1';
     row.TOTAL_CARTERA_HRC='10.1';
     row.VALOR_VCTO_HRC='10.1';
     row.TOTAL_CARTERA_HMC='10.1';
     row.VALOR_VCTO_HMC='10.1';
     row.TOTAL_CARTERA_HOC='10.1';
     row.VALOR_VCTO_SIN_HOC='10.1';
     row.PEDIDOS_COMPROMETIDOS_SIN_CO='10.1';
     row.PEDIDOS_COMPROMETIDOS_HCR='10.1';
     row.PEDIDOS_COMPROMETIDOS_HMC='10.1';
     row.PEDIDOS_COMPROMETIDOS_HOC='10.1';
     row.REMISIONADO_NOFACTURADO_SIN_CO='10.1';
     row.REMISIONADO_NOFACTURADO_HCR='10.1';
     row.REMISIONADO_NOFACTURADO_HMC='10.1';
     row.REMISIONADO_NOFACTURADO_HOC='10.1';
     rows.add(row);
    }
 
    fan_ConsultaCupo.DT_Cupo res = new fan_ConsultaCupo.DT_Cupo();
    res.row = rows;

    response.put('response_x', res);
  }
}