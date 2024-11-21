@IsTest
public class fan_OrderStatusFOsMock implements WebServiceMock{
    
    // This params are required for the implementarion of doInvoke method
    public void doInvoke(
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
        // Simulate the response from WS
        fan_OrderStatusFOs.row_element rowData = new fan_OrderStatusFOs.row_element();
        rowData.CO_PICKLIST = 'HRC';
        rowData.ORDEN_COMPRA = 'F0-0123';
        rowData.FECHA = '2023-05-19';
        rowData.DOCUMENTO_PICKLIST = 'PRM-00839845';
        rowData.VALORAR_CON_PICKLIST = '123456789';
        rowData.FACTURAR_A_PICKLIST = '123456789';
        rowData.ESTADOI_PICKLIST = 'TestAprobado';
        rowData.FACTURADO = 'No';
        rowData.REMISIONADO = 'No';
        rowData.RETENIDO_CUPO = 'No';
        rowData.RETENIDO_MORA = 'No';
        rowData.RETENIDO_MARGEN = 'No';
        rowData.NO_GUIA_TRANS = 'No';
        fan_OrderStatusFOs.row_element[] responseRows = new fan_OrderStatusFOs.row_element[]{rowData};
        fan_OrderStatusFOs.DT_Pedidos_Rsp response_x = new fan_OrderStatusFOs.DT_Pedidos_Rsp();
        response_x.row = responseRows;
        response.put('response_x', response_x);
    }
}