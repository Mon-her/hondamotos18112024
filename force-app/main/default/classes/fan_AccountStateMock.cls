@isTest
global class fan_AccountStateMock implements WebServiceMock{
   
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
    fan_AccountState.row_element row = new fan_AccountState.row_element();
    
      row.CODIGO = 'AXA1';
      row.DESCRIPCION = 'lorem inpsum';
      row.FECHAVCTO = '2022-09-01T00:00:00-05:00';
      row.CORRIENTE = '1.0';
      row.VENCIDO1A30 = '1.0';
      row.VENCIDO31A60 = '1.0';
      row.VENCIDO61A90 = '1.0';
      row.VENCIDO91MAS = '1.0';
      
      fan_AccountState.row_element[] rows = new List<fan_AccountState.row_element>();
      rows.add(row);
  
      fan_AccountState.DT_EstadoCuenta_Rsp res = new fan_AccountState.DT_EstadoCuenta_Rsp();
      res.row = rows;
  
      response.put('response_x', res);
    }
}