global class AM_Actualizar_Estado_Facturas_Batch{// implements Database.AllowsCallouts, Database.Batchable<sObject> {
//RM 14-01-2019. Commented. Not in use 
/*    
    //String etapa = 'No compra';
    String etapa1 = 'Prospectación';
    String etapa2 = 'Facturación';
    String query = 'select name, AM_Etapa__c from AM_Oportunidad__c where AM_Etapa__c IN (:etapa1,:etapa2)';

    private Parametros_WS_UNOe__c paramWSUNOe;
    global AM_Actualizar_Estado_Facturas_Batch() {
        paramWSUNOe = Parametros_WS_UNOe__c.getInstance(Userinfo.getOrganizationId());
    }  
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //system.debug('*******' + query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<AM_Oportunidad__c> opp2 = new List<AM_Oportunidad__c>();
        for(Sobject s : scope){ 
            AM_Oportunidad__c opp = (AM_Oportunidad__c)s;
            system.debug('Opp name-----> ' + opp.name);        
            //WS call START. omar
            String str = '';            
                Http h = new Http();
                HttpRequest req = new HttpRequest();
                // url that returns the XML in the response body
                // change 3/4/2015:
                // Sandbox use: <NombreConexion>Pruebas_MotoR </NombreConexion>
                // Produccion use: <NombreConexion>MotoRed</NombreConexion>
                String url = (String)paramWSUNOe.URL__c + '/EjecutarConsultaXML?pvstrxmlParametros=<Consulta><NombreConexion>'+ (String)paramWSUNOe.NombreConexion__c +'</NombreConexion> <IdCia>1</IdCia><IdProveedor>FAC_ESTADO</IdProveedor>  <IdConsulta>FACEST</IdConsulta> <Usuario>'+ (String)paramWSUNOe.Usuario__c +'</Usuario> <Clave>'+ (String)paramWSUNOe.Clave__c +'</Clave> <Parametros> <p_id_cia>1</p_id_cia> <p_referencia>'+opp.name+'</p_referencia> </Parametros> </Consulta>';
                req.setEndpoint(url);
                req.setMethod('GET');
            if(!Test.isRunningTest())
            {
                HttpResponse res = h.send(req);
                // Log the XML content
                //System.debug(res.getBody());
                str = res.getBody();
            }else{
                str = '<DataSet xmlns="http://tempuri.org/"><xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:UseCurrentLocale="true">      <xs:complexType>        <xs:choice minOccurs="0" maxOccurs="unbounded">          <xs:element name="Resultado">            <xs:complexType>              <xs:sequence>                <xs:element name="COMPANIA" type="xs:decimal" minOccurs="0" />                <xs:element name="TIPO_DOCTO" type="xs:string" minOccurs="0" />                <xs:element name="NRO__DOCTO" type="xs:decimal" minOccurs="0" />                <xs:element name="NIT" type="xs:string" minOccurs="0" />                <xs:element name="CLIENTE" type="xs:string" minOccurs="0" />                <xs:element name="SUCURSAL" type="xs:string" minOccurs="0" />                <xs:element name="FECHA" type="xs:dateTime" minOccurs="0" />                <xs:element name="CO" type="xs:string" minOccurs="0" />                <xs:element name="CONCEPTO" type="xs:decimal" minOccurs="0" />                <xs:element name="ITEM" type="xs:string" minOccurs="0" />                <xs:element name="NOMBRE_ITEM" type="xs:string" minOccurs="0" />                <xs:element name="CANTIDAD" type="xs:decimal" minOccurs="0" />                <xs:element name="VALOR_BRUTO" type="xs:decimal" minOccurs="0" />                <xs:element name="VALOR_NETO" type="xs:decimal" minOccurs="0" />                <xs:element name="ESTADO" type="xs:string" minOccurs="0" />              </xs:sequence>            </xs:complexType>          </xs:element>        </xs:choice>      </xs:complexType>    </xs:element>  </xs:schema>  <diffgr:diffgram xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">    <NewDataSet xmlns="">      <Resultado diffgr:id="Resultado1" msdata:rowOrder="0">        <COMPANIA>29</COMPANIA>        <TIPO_DOCTO>FN </TIPO_DOCTO>        <NRO__DOCTO>4</NRO__DOCTO>        <NIT>11205554</NIT>        <CLIENTE>ROMERO ORTIZ DIEGO IVAN</CLIENTE>        <SUCURSAL>001</SUCURSAL>        <FECHA>2014-10-06T00:00:00-05:00</FECHA>        <CO>A1 </CO>        <CONCEPTO>501</CONCEPTO>        <ITEM>MOTOEXT2                                          </ITEM>        <NOMBRE_ITEM>MOTO CON EXTENSION 2 SPLENDOR</NOMBRE_ITEM>        <CANTIDAD>1</CANTIDAD>        <VALOR_BRUTO>3200000</VALOR_BRUTO>        <VALOR_NETO>3200000</VALOR_NETO>        <ESTADO>DV </ESTADO>      </Resultado>      <Resultado diffgr:id="Resultado2" msdata:rowOrder="1">        <COMPANIA>29</COMPANIA>        <TIPO_DOCTO>DV </TIPO_DOCTO>        <NRO__DOCTO>4</NRO__DOCTO>        <NIT>11205554</NIT>        <CLIENTE>ROMERO ORTIZ DIEGO IVAN</CLIENTE>        <SUCURSAL>001</SUCURSAL>        <FECHA>2014-10-17T00:00:00-05:00</FECHA>        <CO>A1 </CO>        <CONCEPTO>502</CONCEPTO>        <ITEM>MOTOEXT2                                          </ITEM>        <NOMBRE_ITEM>MOTO CON EXTENSION 2 SPLENDOR</NOMBRE_ITEM>        <CANTIDAD>-1</CANTIDAD>        <VALOR_BRUTO>-3200000</VALOR_BRUTO>        <VALOR_NETO>-3200000</VALOR_NETO>        <ESTADO>1</ESTADO>      </Resultado></NewDataSet></diffgr:diffgram></DataSet>';
            }
            XmlStreamReader reader = new XmlStreamReader(str);
            AM_Factura_XmlStreamReaderResults results = new AM_Factura_XmlStreamReaderResults();
            AM_Factura_XmlStreamReaderResults.Facturacion[] facts = results.parsefacts(reader);

            //System.debug(facts.size());
            for (AM_Factura_XmlStreamReaderResults.Facturacion fact : facts) {                
                if (fact.getordenResultado() == 'Resultado1')
                {
                    //System.debug('etapa antes del cambio ---------------> '+fact.getestadoSF());
                    if (fact.getestadoSF() != NULL)
                        opp.AM_Etapa__c = fact.getestadoSF(); // also trims estado value.
                    if (fact.getrazonNoComprarSF() != NULL)
                        opp.AM_Razon_para_no_comprar__c = fact.getrazonNoComprarSF();
                    if (fact.getnumeroFacturaSF() != NULL)
                        opp.AM_Numero_de_factura__c = fact.getnumeroFacturaSF();
                    //System.debug('Razon para no comprar ---------------> '+opp.AM_Razon_para_no_comprar__c);
                    //System.debug('Numero de factura ---------------> '+opp.AM_Numero_de_factura__c);
                    //System.debug('etapa luego del cambio ---------------> '+fact.getestadoSF());
                    //System.debug(fact);
                    break;
                }
            }            
            opp2.add(opp);
            //update opp;                    
            //WS call START. omar
        }
        //update scope;
        List<String> catches = new List<String>();
        String catchStr = '';
        for (AM_Oportunidad__c oneOpp : opp2) {
            try {
                System.debug('---------------before update'+oneOpp.name);
                update oneOpp;
                System.debug('---------------after update'+oneOpp.name);
            }
            catch (DmlException e) {
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    catchStr = ('DMLERROR for Cotizacion '+ oneOpp.name +', '+ e.getDmlId(i) + ': ' + e.getDmlMessage(i));
                    catches.add(catchStr);
                    System.debug(catchStr);
                }
            }
        }
        if (!catches.isEmpty()){
            //send email.
            System.debug('complete DMLERROR List: '+catches);   

            User u = [Select Id, Email from User where Id =:UserInfo.getUserId()];
            String toAddress= u.Email;
            //String toAddress1 = 'ovalenzuela@nexvel.com';
            //String toAddress2 = 'wvelazquez@nexvel.com';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
            String[] toAddresses = new String[] {toAddress}; 
            mail.setToAddresses(toAddresses); 
            mail.setSubject('FANALCA - Integracion Factura - Apex Batch Job Error'); 
            String txtBody = 'FANALCA - DMLERROR List: \n\n';
            for (String oneCatchStr : catches){
                txtBody += oneCatchStr+'\n';
            }
            mail.setPlainTextBody(txtBody); 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }        
    }
    global void finish(Database.BatchableContext BC) {
        //User u = [Select Id, Email from User where Id =:UserInfo.getUserId()];
  //      String toAddress= u.Email;
        //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        //String[] toAddresses = new String[] {toAddress}; 
        //mail.setToAddresses(toAddresses); 
        //mail.setSubject('Apex Batch Job is done'); 
        //mail.setPlainTextBody('The batch Apex job processed '); 
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }*/    
}