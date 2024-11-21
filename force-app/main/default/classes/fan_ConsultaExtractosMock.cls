@IsTest
global class fan_ConsultaExtractosMock implements WebServiceMock {

    global static String NITCLIENTE;
    @TestVisible
    static Boolean isReadTimedOutException;

    global void doInvoke(
        Object stub,
        Object request,
        Map<String,Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNamespace,
        String responseName,
        String responseType) {

        fan_ConsultaExtractos.DT_NIT input = (fan_ConsultaExtractos.DT_NIT) request;

        fan_ConsultaExtractos.DT_Extractos output = new fan_ConsultaExtractos.DT_Extractos();
        output.row = new List<fan_ConsultaExtractos.row_element>();

        if(input.NITCLIENTE == NITCLIENTE) {

            fan_ConsultaExtractos.row_element row = new fan_ConsultaExtractos.row_element();
            row.NIT = NITCLIENTE;
            row.FECHA = '2022-06-25';
            row.DOCUMENTO = 'DOC-MXBB-319319';
            row.DOCTO_CRUCE = 'NDE-3135';
            row.VCTO = '2022-07-25';
            row.VALOR_DOCUMENTO = '46204213';
            row.SALDO_INICIAL = '46204213';
            row.VALOR_APLICADO = '0';
            row.SALDO = '46204213';
            row.AUXILIAR = 'ANTIC. DE CLIENTES';

            output.row.add(row);
        }
        if(isReadTimedOutException == true) {
            throw new CalloutException('Read timed out');
        }

        response.put('response_x', input.NITCLIENTE == NITCLIENTE
        ? output
        : null);
    }
}