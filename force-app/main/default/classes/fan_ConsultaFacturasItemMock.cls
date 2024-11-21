@IsTest
public class fan_ConsultaFacturasItemMock implements WebServiceMock {

    @TestVisible
    static String factura;
    @TestVisible
    static Boolean isReadTimedOutException;

    public void doInvoke(
        Object stub,
        Object request,
        Map<String,Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNamespace,
        String responseName,
        String responseType) {

            fan_ConsultaFacturasItem.DT_Consulta input = (fan_ConsultaFacturasItem.DT_Consulta) request;

            fan_ConsultaFacturasItem.DT_FacturasItem output = new fan_ConsultaFacturasItem.DT_FacturasItem();

            if(input.FACTURA == factura) {
                output.row = new List<fan_ConsultaFacturasItem.row_element>();

                fan_ConsultaFacturasItem.row_element row = new fan_ConsultaFacturasItem.row_element();
                row.DOCUMENTO = factura;
                row.REFERENCIA = 'FLM-4642';
                row.DES_REFERENCIA = 'MOTOCICLETA FLM-4642';
                row.FECHA = '2022-06-21';
                row.CANTIDAD = '1';
                row.PR_UNITARIO = '19133858';
                row.POR_DESCUENTO = '0.14';
                row.VALOR_SUBTOTAL = '16455118';
                row.POR_IMPUESTOS = '0.19';
                row.VALOR_IMPUESTOS = '3126472';
                row.VALOR_NETO = '19581590';

                output.row.add(row);
            }
            if(isReadTimedOutException == true) {
                throw new CalloutException('Read timed out');
            }
            response.put('response_x', output);
    }
}