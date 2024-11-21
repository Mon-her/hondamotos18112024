//Created by Me, on January 2022
//Description: Controller for Hoja de Vida Vehiculo lightning web component, this class gets the History of the vehicule from SAP using a SOAP API
//Test Class: lwcHojaVidaVehiculo_Test
//Modified on 20220426: changed labels for user and pass
public class lwcHojaVidaVehiculo {
	@auraEnabled
    public static String getNoDocumento(String idCaso){
        system.debug('Entrando a get No Documento');
        if (String.isBlank(idCaso)==false){
        	list<Case> casos = [select Account.AM_Numero_de_documento__c from Case where Id=:idCaso]; 
            if (casos.size()==1) return casos.get(0).Account.AM_Numero_de_documento__c;
            else return '';
        }else return '';
        
    }
    
    @auraEnabled
    public static Historial[] getVehiculo(String noDocumento, String FLEET_NUM){
        try{
            FanalcaSalesForceGetVehiculoSFC2SapEcc.Row_element[] filas; 
            //FanalcaSalesForceGetVehiculoSFC2SapEcc.HTTPS_Port clsGetVehiculo = new FanalcaSalesForceGetVehiculoSFC2SapEcc.HTTPS_Port();
            //filas = clsGetVehiculo.GET('', ''); //clsGetVehiculo.GET(STCD1, FLEET_NUM);
            
            FanalcaSalesForceGetVehiculoSFC2SapEcc.HTTPS_Port enviarWS = new FanalcaSalesForceGetVehiculoSFC2SapEcc.HTTPS_Port();
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUserHojaVidaMoto+':'+Label.FanalcaWSPasswordHojaVidaMoto);
            string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            //enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'text/xml; charset=utf-8');
            enviarWS.timeout_x = 12000;
            
            filas = enviarWS.GET(noDocumento, FLEET_NUM); //clsGetVehiculo.GET(STCD1, FLEET_NUM);
            
            system.debug('filas: ' + filas);
            
            list<Historial> historias = new list<Historial>();
            if (filas==null) return historias;
            for (FanalcaSalesForceGetVehiculoSFC2SapEcc.Row_element row: filas){
                Historial historia = new Historial();
                historia.vin = row.VIN_NUM;
                historia.anio = row.YEAR;
                historia.linea = row.LINE;
                historia.noOrden = row.AUFNR;
                historia.servicio = row.SGTXT;
                historia.fechaServicio = dateFormat(row.DATUM);
                historia.descripcion = row.DESCRIP;
                historia.repuestos = row.MAKTX;
                historia.kilometraje = row.KMS; system.debug('KMS: ' + row.KMS);
                historia.tipoDocumento = row.TPDOC;
                historia.noDocumento = row.STCD1;
                historia.nombres = row.NAME1;
                historia.apellidos = row.NAME3;
                historia.celular = row.CELULAR;
                historia.email = row.SMTP;
                historia.concesionario = row.BUKRSD;
                historia.agencia = row.WERKSD;
                historia.placa = row.FLEET_NUM;
                
                historias.add(historia);
            }
            
            return historias;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static Date dateFormat(String fecha){
        String fechaFormateada = fecha.left(4) + '-' + fecha.substring(4, 6) + '-'+ fecha.right(2);
        return Date.valueOf(fechaFormateada);
    }
    
    public class Historial{
        @AuraEnabled public  string vin { get; set;}
        @AuraEnabled public  string anio  { get; set;}
        @AuraEnabled public  string linea  { get; set;}
        @AuraEnabled public  string noOrden { get; set;}
        @AuraEnabled public  string servicio { get; set;}
        @AuraEnabled public  Date fechaServicio { get; set;}
        @AuraEnabled public  string descripcion { get; set;}
        @AuraEnabled public  string repuestos { get; set;}
        @AuraEnabled public  string kilometraje { get; set;}
        @AuraEnabled public  string tipoDocumento { get; set;}
        @AuraEnabled public  string noDocumento { get; set;}
        @AuraEnabled public  string nombres { get; set;}
        @AuraEnabled public  string apellidos { get; set;}
        @AuraEnabled public  string celular { get; set;}
        @AuraEnabled public  string email { get; set;}
        @AuraEnabled public  string concesionario { get; set;}
        @AuraEnabled public  string agencia { get; set;}
        @AuraEnabled public  string placa { get; set;}
    }
    
}