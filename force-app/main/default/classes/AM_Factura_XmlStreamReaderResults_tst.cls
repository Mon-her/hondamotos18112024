@isTest
private class AM_Factura_XmlStreamReaderResults_tst
{
    static testmethod void testFacturacionParser()
    {
        AM_Factura_XmlStreamReaderResults demo = new AM_Factura_XmlStreamReaderResults();

        String str = '<DataSet xmlns="http://tempuri.org/"><xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:UseCurrentLocale="true">      <xs:complexType>        <xs:choice minOccurs="0" maxOccurs="unbounded">          <xs:element name="Resultado">            <xs:complexType>              <xs:sequence>                <xs:element name="COMPANIA" type="xs:decimal" minOccurs="0" />                <xs:element name="TIPO_DOCTO" type="xs:string" minOccurs="0" />                <xs:element name="NRO__DOCTO" type="xs:decimal" minOccurs="0" />                <xs:element name="NIT" type="xs:string" minOccurs="0" />                <xs:element name="CLIENTE" type="xs:string" minOccurs="0" />                <xs:element name="SUCURSAL" type="xs:string" minOccurs="0" />                <xs:element name="FECHA" type="xs:dateTime" minOccurs="0" />                <xs:element name="CO" type="xs:string" minOccurs="0" />                <xs:element name="CONCEPTO" type="xs:decimal" minOccurs="0" />                <xs:element name="ITEM" type="xs:string" minOccurs="0" />                <xs:element name="NOMBRE_ITEM" type="xs:string" minOccurs="0" />                <xs:element name="CANTIDAD" type="xs:decimal" minOccurs="0" />                <xs:element name="VALOR_BRUTO" type="xs:decimal" minOccurs="0" />                <xs:element name="VALOR_NETO" type="xs:decimal" minOccurs="0" />                <xs:element name="ESTADO" type="xs:string" minOccurs="0" />              </xs:sequence>            </xs:complexType>          </xs:element>        </xs:choice>      </xs:complexType>    </xs:element>  </xs:schema>  <diffgr:diffgram xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">    <NewDataSet xmlns="">      <Resultado diffgr:id="Resultado1" msdata:rowOrder="0">        <COMPANIA>29</COMPANIA>        <TIPO_DOCTO>FN </TIPO_DOCTO>        <NRO__DOCTO>4</NRO__DOCTO>        <NIT>11205554</NIT>        <CLIENTE>ROMERO ORTIZ DIEGO IVAN</CLIENTE>        <SUCURSAL>001</SUCURSAL>        <FECHA>2014-10-06T00:00:00-05:00</FECHA>        <CO>A1 </CO>        <CONCEPTO>501</CONCEPTO>        <ITEM>MOTOEXT2                                          </ITEM>        <NOMBRE_ITEM>MOTO CON EXTENSION 2 SPLENDOR</NOMBRE_ITEM>        <CANTIDAD>1</CANTIDAD>        <VALOR_BRUTO>3200000</VALOR_BRUTO>        <VALOR_NETO>3200000</VALOR_NETO>        <ESTADO>DV </ESTADO>      </Resultado>      <Resultado diffgr:id="Resultado2" msdata:rowOrder="1">        <COMPANIA>29</COMPANIA>        <TIPO_DOCTO>DV </TIPO_DOCTO>        <NRO__DOCTO>4</NRO__DOCTO>        <NIT>11205554</NIT>        <CLIENTE>ROMERO ORTIZ DIEGO IVAN</CLIENTE>        <SUCURSAL>001</SUCURSAL>        <FECHA>2014-10-17T00:00:00-05:00</FECHA>        <CO>A1 </CO>        <CONCEPTO>502</CONCEPTO>        <ITEM>MOTOEXT2                                          </ITEM>        <NOMBRE_ITEM>MOTO CON EXTENSION 2 SPLENDOR</NOMBRE_ITEM>        <CANTIDAD>-1</CANTIDAD>        <VALOR_BRUTO>-3200000</VALOR_BRUTO>        <VALOR_NETO>-3200000</VALOR_NETO>        <ESTADO>1</ESTADO>      </Resultado></NewDataSet></diffgr:diffgram></DataSet>';
        XmlStreamReader reader = new XmlStreamReader(str);
        AM_Factura_XmlStreamReaderResults.Facturacion[] facts = demo.parsefacts(reader);

        System.debug(facts.size());

        for (AM_Factura_XmlStreamReaderResults.Facturacion fact : facts) {
            System.debug(fact);
            System.debug(fact.getestadoSF()); // also trims estado value.
            System.debug(fact.getrazonNoComprarSF());
            System.debug(fact.getnumeroFacturaSF());
        }

    }
}