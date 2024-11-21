//Mock Class for FanalcaSalesForceGetVehiculoSFC2SapEcc
@isTest
global class FanalcaSalesForceGetVehiculoSFC2Sap_Mock implements WebServiceMock{
	public static Integer option {get; set;}
    public FanalcaSalesForceGetVehiculoSFC2Sap_Mock (integer opcion){
        option = opcion;
    }
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
        // start - specify the response you want to send
        
        FanalcaSalesForceGetVehiculoSFC2SapEcc.Row_element row = new FanalcaSalesForceGetVehiculoSFC2SapEcc.Row_element();
               
        FanalcaSalesForceGetVehiculoSFC2SapEcc.DT_Vehicle_detail_Rsp respuesta = new FanalcaSalesForceGetVehiculoSFC2SapEcc.DT_Vehicle_detail_Rsp();
            
        switch on option {
            when 1 {		//1 ok
                /*response_x.TYPE_x ='S';
                response_x.NUMBER_x ='000';       
                response_x.MSSGS ='Modificación de Deudor Exitosa';
                response_x.KUNNR ='0010692738';  */  
                row.VIN_NUM = '123456';
                row.YEAR = '2022';
                row.LINE = 'ECO DELUXE ES';
                row.AUFNR = '70000608853'; //No Orden
                row.SGTXT = 'Orden de servicio Mantenimiento'; //servicio
                row.DATUM = '20200128';
                row.DESCRIP= 'Alguna descripción del servicio';
                row.MAKTX = 'Ajuste Holgura de Valvulas'; //repuestos
                row.KMS = '50000';
                row.TPDOC = '13'; //tipoDocumento;
                row.STCD1 = '11312965'; //noDocumento
                row.NAME1 = 'PABLO EMILIO';
                row.NAME3 = 'LAGUNA MORENO';
                row.CELULAR = '3213378546';
                row.SMTP= 'somen@email.com'; //email
                row.BUKRSD = 'SUPERMOTOS DE GIRARDO SAS'; //concesionario
                row.WERKSD = '2000'; //agencia
                row.FLEET_NUM = 'QMF90C'; //placa
                
                respuesta.Row = new FanalcaSalesForceGetVehiculoSFC2SapEcc.Row_element[]{row};
            }	
            when 2 {		
                 
            }
            when 3 {		
                throw new CalloutException('Algún error de callout');
            }
            when else {		  
                
            }
        }
           
        // end
        //response.put('response_x', response_x); 
        response.put('response_x', respuesta); 
   }
}