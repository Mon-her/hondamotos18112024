@isTest
global class AM_ConsultarInventarioSoapWsMock implements WebServiceMock {
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
    AM_ConsultarInventarioSoapWs.DT_MS_RESPONSE response_x = new AM_ConsultarInventarioSoapWs.DT_MS_RESPONSE();
    List<AM_ConsultarInventarioSoapWs.Row> rows = new List<AM_ConsultarInventarioSoapWs.Row>();
    AM_ConsultarInventarioSoapWs.Row row = new AM_ConsultarInventarioSoapWs.Row();
    row.MATNR = '000000000100000785';
    row.WERKS = '1302';
    row.SEGMENT = 'HONDA';
    row.MKTXT = 'CBF-125 2019 ROJO NEGRO';
    row.MODELO = '2019';
    row.COLOR = 'ROJO';
    row.LINEA = 'CBF-125';
    row.LGORT = 'MN01';
    row.LABTS = '0.000';
    rows.add(row);

    response_x.Row = rows;

    response.put('response_x', response_x);
  }
}