@IsTest
global class fan_PricebookMock implements WebServiceMock{
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
        fan_Pricebook.row_element[] rowElements;
        fan_Pricebook.DT_Lista_Precios input = (fan_Pricebook.DT_Lista_Precios) request;
    
        if(input.ITEM == 'RMT') {
          fan_Pricebook.row_element rowElement = new fan_Pricebook.row_element();
          if(input.DETALLE == '1') {
            rowElement.LISTA = 'RMT';
            rowElement.ITEM = 'SKU-1';
            rowElement.PORCENTAJE = '0.3';
            rowElement.DESC_DETALLE_EXT_1 = '2';
            rowElement.PRECIO = '12312';
          } else {
            rowElement.LISTA = 'EMPTY';
            rowElement.ITEM = 'EMPTY';
          }
          rowElements = new List<fan_Pricebook.row_element> { rowElement };
        }

        fan_Pricebook.DT_Lista_Precios_Rsp output = new fan_Pricebook.DT_Lista_Precios_Rsp();
        output.row = rowElements;
        response.put('response_x', output);
      }
}