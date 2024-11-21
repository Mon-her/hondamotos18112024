@IsTest
global class fan_ItemsUnoMock implements WebServiceMock {
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
    fan_ItemsUnoE.row_element row1 = new fan_ItemsUnoE.row_element();
    row1.ITEM = '2400';
    row1.DESCRIPCION = 'PCLOCTITE';
    row1.REFERENCIA = 'SUPERFLEXTEST';
    row1.MODELO_ANIO = '2023';
    row1.CAMPO_IVA = '0';
    row1.CAMPO_IVAC = '0.19';
    row1.ITEM_EQUIVALENTE = '2450';

    fan_ItemsUnoE.row_element substitute = new fan_ItemsUnoE.row_element();
    substitute.ITEM = '2450';
    substitute.DESCRIPCION = 'PCLOCTITE';
    substitute.REFERENCIA = 'SUPERFLEXTEST-5';
    substitute.MODELO_ANIO = '2023';
    substitute.CAMPO_IVA = '0';
    substitute.CAMPO_IVAC = '0.19';
    substitute.ITEM_EQUIVALENTE = 'preserve';

    fan_ItemsUnoE.row_element row2 = new fan_ItemsUnoE.row_element();
    row2.ITEM = 'M2400';
    row2.DESCRIPCION = 'PCLOCTITE';
    row2.REFERENCIA = 'SUPERFLEXTEST';
    row2.MODELO_ANIO = '2023';
    row2.CAMPO_IVA = '0';
    row2.CAMPO_IVAC = '0.19';
    row2.EXT_ITEM_COLOR = 'ROJO';

    fan_ItemsUnoE.row_element[] rows = new List<fan_ItemsUnoE.row_element>();
    rows.add(row1);
    rows.add(substitute);
    rows.add(row2);

    fan_ItemsUnoE.DT_Items_Rsp res = new fan_ItemsUnoE.DT_Items_Rsp();
    res.row = rows;

    response.put('response_x', res);
  }
}