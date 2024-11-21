/**
* Fanalca
* @author           Raul Mora
* Description:      Controller class to query the required fields to be displayed on the PDF quote.
*                   This was required as the getcontent as pdf was not working with the standardcontroller Visualforce.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     17/01/2019      Raul Mora (RM)          Class definition.
*********************************************************************************************************/
public class RM_CotizacionFinanciacion_ctr {
    
    public AM_Oportunidad__c objOp {get;set;}
    
    public String strObservaciones1 {get;set;}
    public String strObservaciones2 {get;set;}
    public String strObservaciones3 {get;set;}
    public String strNameStyle {get;set;}
    public String strAddressStyle {get;set;}
    public String strServiciosIncluidos {get;set;}
    public Boolean blnSistemaAntibloqueoFrenos {get; set;}
    public Boolean blnControlElectronicoEstabilidad {get; set;}
    public Boolean blnAlertaColisionFrontal {get; set;}
    public Boolean blnFrenadoAutonomoEmergencia {get; set;}
    public Boolean blnSistemaSujecionInfantil {get; set;}
    public Boolean blnSistemaBolsaAire {get; set;}
    public Integer intBolsasAire {get; set;}
    
    public RM_CotizacionFinanciacion_ctr( ApexPages.StandardController stdController ) {
        this.objOp = [ Select Id, AM_Fecha_de_creacion__c, Name, AM_Usuario_motocicleta__r.Name, AM_Usuario_motocicleta__r.AM_Numero_de_documento__c,
                       Owner.Name, AM_Usuario_motocicleta__r.Phone, AM_Movil_propietario__c, AM_Usuario_motocicleta__r.PersonOtherPhone, Owner.Email,
                       AM_Usuario_motocicleta__r.AM_Direccion__c, AM_Agencia_propietario__c, AM_Direccion_propietario__c, AM_Usuario_motocicleta__r.PersonEmail,
                       AM_Canal_de_atencion__c, AM_Modelo_sugerido_1__c, AM_Modelo_de_interes__r.Name, AM_Modelo_de_interes__r.AM_URL_foto__c, 
                       AM_Modelo_de_interes__r.AM_Linea__c, AM_Color__c, AM_Modelo_de_interes__r.AM_Version__c, AM_Modelo_de_interes__r.AM_Cilindraje__c,
                       AM_Modelo_de_interes__r.SO_Sistema_antibloqueo_de_frenos__c, AM_Modelo_de_interes__r.SO_Control_electronico_de_estabilidad__c,
                       AM_Modelo_de_interes__r.SO_Alerta_de_colision_frontal__c, AM_Modelo_de_interes__r.SO_Frenado_autonomo_de_emergencia__c,
                       AM_Modelo_de_interes__r.SO_Sistema_de_sujecion_infantil__c, AM_Modelo_de_interes__r.SO_Sistema_de_bolsa_de_aire__c,
                       AM_Modelo_de_interes__r.SO_Numero_de_bolsas_de_aire__c,
                       AM_Modelo_de_interes__r.AM_Transmision__c, AM_Modelo_de_interes__r.AM_Precio_de_lista__c, AM_Modelo_sugerido_1__r.Name, 
                       AM_Modelo_sugerido_1__r.AM_URL_foto__c, AM_Modelo_sugerido_1__r.AM_Linea__c, Color_sugerido__c, AM_Modelo_sugerido_1__r.AM_Version__c,
                       AM_Modelo_sugerido_1__r.AM_Cilindraje__c, AM_Modelo_sugerido_1__r.AM_Transmision__c, AM_Modelo_sugerido_1__r.AM_Precio_de_lista__c,
                       AM_Valor_Simulacion1__c, AM_Valor_Simulacion2__c, AM_Valor_SImulacion3__c, AM_Valor_Simulacion4__c, AM_Financiera_Simulacion1__c,
                       AM_Financiera_Simulacion2__c, AM_Financiera_Simulacion3__c, AM_Financiera_Simulacion4__c, AM_Cuota_Inicial_Simulacion1__c,
                       AM_Cuota_Inicial_Simulacion2__c, AM_Cuota_Inicial_Simulacion3__c, AM_Cuota_Inicial_Simulacion4__c, AM_Saldo_a_financiar_Simulacion1__c,
                       AM_Saldo_a_financiar_Simulacion2__c, AM_Saldo_a_financiar_Simulacion3__c, AM_Saldo_a_financiar_Simulacion4__c, AM_Plazo_Simulacion1__c,
                       AM_Plazo_Simulacion2__c, AM_Plazo_Simulacion3__c, AM_Plazo_Simulacion4__c, AM_Cuota_Mensual_Simulacion1__c, AM_Cuota_Mensual_Simulacion2__c,
                       AM_Cuota_Mensual_Simulacion3__c, AM_Cuota_Mensual_Simulacion4__c, AM_Observaciones__c, AM_Propietario_motocicleta__r.Name, 
                       AM_Propietario_motocicleta__r.PersonOtherPhone, AM_Propietario_motocicleta__r.AM_Numero_de_documento__c, AM_Propietario_motocicleta__r.AM_Direccion__c,
                       AM_Propietario_motocicleta__r.Phone, AM_Propietario_motocicleta__r.PersonEmail, AM_Ano_modelo__c, AM_Color_opcion_2__c, AM_Ano_modelo_sugerido__c,
                       AM_Color_opc_2_sugerido__c, AM_ObservacionesL__c, AM_Placa__c, AM_Otro_Placa__c, AM_Modelo_de_interes__r.AM_Placa_usado__c, AM_Modelo_de_interes__r.AM_Caja__c,
                       AM_Modelo_sugerido_1__r.AM_Caja__c, Marca_usado__c, Linea_usado__c, version_usado__c, Ciudad_de_placa__r.Name,AM_Tipo_Renting__c ,AM_Cantidad_de_vehiculos__c ,
                       AM_Plazo_Renting1__c,AM_Plazo_Renting2__c,AM_Plazo_Renting3__c,AM_Kilometraje_Renting1__c,AM_Kilometraje_Renting2__c,AM_Kilometraje_Renting3__c,
                       AM_Canon_Renting1__c,AM_Canon_Renting2__c,AM_Canon_Renting3__c,AM_Servicios_incluidos_Renting__c,AM_Servicios_adicionales__c,
                       Cilindraje_usados__c, caja_usado__C, Ano_modelo_usado__c, Color_usado__c, Placa_usado__c, Precio_venta_usado__c, Kilometraje_usado__c
                       ,AM_Porcentaje_IVA__c,AM_IVA_Canon_Renting1__c,AM_IVA_Canon_Renting2__c,AM_IVA_Canon_Renting3__c
                       From AM_Oportunidad__c
                       Where Id =: apexpages.currentpage().getparameters().get('id') ];
        if( this.objOp.AM_Modelo_de_interes__r != null ){
            blnSistemaAntibloqueoFrenos         =   this.objOp.AM_Modelo_de_interes__r.SO_Sistema_antibloqueo_de_frenos__c ;
            blnControlElectronicoEstabilidad    =   this.objOp.AM_Modelo_de_interes__r.SO_Control_electronico_de_estabilidad__c;
            blnAlertaColisionFrontal            =   this.objOp.AM_Modelo_de_interes__r.SO_Alerta_de_colision_frontal__c;
            blnFrenadoAutonomoEmergencia        =   this.objOp.AM_Modelo_de_interes__r.SO_Frenado_autonomo_de_emergencia__c;
            blnSistemaSujecionInfantil          =   this.objOp.AM_Modelo_de_interes__r.SO_Sistema_de_sujecion_infantil__c;
            blnSistemaBolsaAire                 =   this.objOp.AM_Modelo_de_interes__r.SO_Sistema_de_bolsa_de_aire__c ;
            intBolsasAire                       =   this.objOp.AM_Modelo_de_interes__r.SO_Numero_de_bolsas_de_aire__c != null ? Integer.ValueOf( this.objOp.AM_Modelo_de_interes__r.SO_Numero_de_bolsas_de_aire__c ) : 0; 
        }
        
        String strObservacionesFirstW = this.objOp.AM_ObservacionesL__c != null ? this.objOp.AM_ObservacionesL__c.substringBefore(' ') : '';
        String strObservaciones = strObservacionesFirstW.isAllUpperCase() ? this.objOp.AM_ObservacionesL__c.toLowerCase().capitalize() : this.objOp.AM_ObservacionesL__c;
        strServiciosIncluidos = this.objOp.AM_Servicios_incluidos_Renting__c != null?this.objOp.AM_Servicios_incluidos_Renting__c.replace('<br>','. '):null;
        strObservaciones1 = strObservaciones != null ? strObservaciones : '';
        strObservaciones2 = '';
        strObservaciones3 = '';
        if(strObservaciones1.length() > 71) {
            strObservaciones2 = strObservaciones1.substring( 71 );
            strObservaciones1 = strObservaciones1.left( 71 );    
            if( strObservaciones2.length() > 71 ) {
                strObservaciones3 = strObservaciones2.length() > 142 ? strObservaciones2.substring( 71, 142 ) : strObservaciones2.substring( 71 );
                strObservaciones2 = strObservaciones2.left( 71 );
            }
        }
        
        strNameStyle = objOp.AM_Propietario_motocicleta__r.Name != null ? ( objOp.AM_Propietario_motocicleta__r.Name.length() > 18 ? 'p0 ft99' : 'p0 ft9' ) : 'p0 ft9';
        strAddressStyle = objOp.AM_Propietario_motocicleta__r.AM_Direccion__c != null ? ( objOp.AM_Propietario_motocicleta__r.AM_Direccion__c.length() > 18 ? 'p0 ft88' : 'p0 ft8' ) : 'p0 ft8';
    }

}