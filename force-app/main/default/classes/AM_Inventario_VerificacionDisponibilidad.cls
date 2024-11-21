public class AM_Inventario_VerificacionDisponibilidad{

    public String request{get;set;}
    public String result{get;set;}
    public AM_Inventario_XmlStreamReaderResults.Inventario[] invs {get;set;}
    private Parametros_WS_UNOe__c paramWSUNOe;

    public AM_Inventario_VerificacionDisponibilidad(ApexPages.StandardController controller){
        paramWSUNOe = Parametros_WS_UNOe__c.getInstance(Userinfo.getOrganizationId());
        
        AM_Oportunidad__c AMOP = (AM_Oportunidad__c)controller.getRecord();
        AM_Oportunidad__c myCotizacion = [select id, AM_Color__c, AM_Modelo_de_interes__c,AM_Ano_modelo__c from AM_Oportunidad__c where id = :AMOP.id];
        AM_Producto__c myProd = [select name, AM_Ano__c,Plan_Tipo_de_Modelo_Unoe__c from AM_Producto__c where id = :myCotizacion.AM_Modelo_de_interes__c];
        
        String colorstr = myCotizacion.AM_Color__c ;
        String anostr = myProd.AM_Ano__c.toPlainString().replace('.',''); //myCotizacion.AM_Ano_modelo__c.toPlainString();
        String modelostr = myProd.Plan_Tipo_de_Modelo_Unoe__c;

        AM_Inventario_XmlStreamReaderResults results = new AM_Inventario_XmlStreamReaderResults();
        
        //System.debug('--------------Año:'+anostr);
        String str = '';
        
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            // url that returns the XML in the response body
            // cambio usuario de "integracion" a "galatas517"
            String url = (String)paramWSUNOe.URL__c + '/EjecutarConsultaXML?pvstrxmlParametros=<Consulta><NombreConexion>'+ (String)paramWSUNOe.NombreConexion__c +'</NombreConexion> <IdCia>1</IdCia><IdProveedor>CONC_EXISTENCIA</IdProveedor>  <IdConsulta>INVEXIS</IdConsulta> <Usuario>'+ (String)paramWSUNOe.Usuario__c +'</Usuario> <Clave>'+ (String)paramWSUNOe.Clave__c +'</Clave> <Parametros> <p_id_cia>1</p_id_cia> <p_plan>' + modelostr.toUpperCase() + '</p_plan>  <p_color>'+ colorstr.toUpperCase() + '</p_color>  <p_anno>'+ anostr + '</p_anno> </Parametros> </Consulta>';
            req.setEndpoint(url);
            req.setMethod('GET');
            System.debug('----------------->'+url);
        if(!Test.isRunningTest()) 
        {
            HttpResponse res = h.send(req);
            str = res.getBody();
            // Log the XML content
            //System.debug(res.getBody());
        }else{
            str = '<?xml version="1.0" encoding="utf-8"?><DataSet xmlns="http://tempuri.org/">  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:UseCurrentLocale="true">      <xs:complexType>        <xs:choice minOccurs="0" maxOccurs="unbounded">          <xs:element name="Resultado">            <xs:complexType>              <xs:sequence>                <xs:element name="BODEGA" type="xs:string" minOccurs="0" />                <xs:element name="DESCRIPCION_BODEGA" type="xs:string" minOccurs="0" />                <xs:element name="DISPONIBLE" type="xs:decimal" minOccurs="0" />                <xs:element name="COLOR" type="xs:string" minOccurs="0" />                <xs:element name="PLAN" type="xs:string" minOccurs="0" />                <xs:element name="MODELO" type="xs:string" minOccurs="0" />                <xs:element name="A_OMODELO" type="xs:string" minOccurs="0" />              </xs:sequence>            </xs:complexType>          </xs:element>        </xs:choice>      </xs:complexType>    </xs:element>  </xs:schema>  <diffgr:diffgram xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">    <NewDataSet xmlns="">      <Resultado diffgr:id="Resultado1" msdata:rowOrder="0"><BODEGA>PR12 </BODEGA>        <DESCRIPCION_BODEGA>PRUEBA AGENCIA 1.2</DESCRIPCION_BODEGA>        <DISPONIBLE>1</DISPONIBLE>        <COLOR>BLANCO</COLOR>        <PLAN>MOTOCICLETA</PLAN>        <MODELO>GLAMOUR</MODELO>        <A_OMODELO>2014</A_OMODELO>      </Resultado>      <Resultado diffgr:id="Resultado2" msdata:rowOrder="1">        <BODEGA>CALI3</BODEGA>        <DESCRIPCION_BODEGA>MOTORED PRINCIPAL</DESCRIPCION_BODEGA>        <DISPONIBLE>3</DISPONIBLE>        <COLOR>BLANCO</COLOR>        <PLAN>MOTOCICLETA</PLAN>        <MODELO>GLAMOUR</MODELO>        <A_OMODELO>2014</A_OMODELO>      </Resultado>      <Resultado diffgr:id="Resultado3" msdata:rowOrder="2">        <BODEGA>CALI2</BODEGA>        <DESCRIPCION_BODEGA>MOTORED PRINCIPAL</DESCRIPCION_BODEGA>        <DISPONIBLE>2</DISPONIBLE>        <COLOR>BLANCO</COLOR>        <PLAN>MOTOCICLETA</PLAN>        <MODELO>GLAMOUR</MODELO>        <A_OMODELO>2014</A_OMODELO>      </Resultado>    </NewDataSet>  </diffgr:diffgram></DataSet>';
        }

        XmlStreamReader reader = new XmlStreamReader(str);
        invs = results.parseinvs(reader);

    }
    
    
}