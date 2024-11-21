global class fan_CargaClientesMock implements WebServiceMock {
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
    fan_CargaClientes.row_element row = new fan_CargaClientes.row_element();
    row.TERCERO = '111111';
    row.RSOCIAL = 'RS123';
    row.SUCURSAL = '000';
    row.SUC_SUCURSAL = 'SS123';
    row.PENV_ID = '001';
    row.PENV_CIUDAD = '111';
    row.PENV_PAIS = '222';
    row.PENV_DIRECCION1 = 'CR 100 148 57';
    row.PENV_DESCRIPCION = 'MALAVER VERGARA';

    fan_CargaClientes.row_element[] rows = new List<fan_CargaClientes.row_element>();
    rows.add(row);

    fan_CargaClientes.DT_Clientes_Rsp res = new fan_CargaClientes.DT_Clientes_Rsp();
    res.row = rows;

    response.put('response_x', res);
  }
}