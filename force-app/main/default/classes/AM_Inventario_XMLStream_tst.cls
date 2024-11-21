@isTest    
public class AM_Inventario_XMLStream_tst{

    public static testMethod void testAM_Inventario_XMLSream_tst() {

        String str = '<?xml version="1.0" encoding="utf-8"?><DataSet xmlns="http://tempuri.org/">  <xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">    <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:UseCurrentLocale="true">      <xs:complexType>        <xs:choice minOccurs="0" maxOccurs="unbounded">          <xs:element name="Resultado">            <xs:complexType>              <xs:sequence>                <xs:element name="BODEGA" type="xs:string" minOccurs="0" />                <xs:element name="DESCRIPCION_BODEGA" type="xs:string" minOccurs="0" />                <xs:element name="DISPONIBLE" type="xs:decimal" minOccurs="0" />                <xs:element name="COLOR" type="xs:string" minOccurs="0" />                <xs:element name="PLAN" type="xs:string" minOccurs="0" />                <xs:element name="MODELO" type="xs:string" minOccurs="0" />              </xs:sequence>            </xs:complexType>          </xs:element>        </xs:choice>      </xs:complexType>    </xs:element></xs:schema><diffgr:diffgram xmlns:msdata="urn:schemas-microsoft-com:xml-msdata" xmlns:diffgr="urn:schemas-microsoft-com:xml-diffgram-v1">    <NewDataSet xmlns="">      <Resultado diffgr:id="Resultado1" msdata:rowOrder="0">        <BODEGA>PR12 </BODEGA>        <DESCRIPCION_BODEGA>PRUEBA AGENCIA 1.2</DESCRIPCION_BODEGA>        <DISPONIBLE>1</DISPONIBLE>        <COLOR>BLANCO</COLOR><PLAN>MOTOCICLETA</PLAN>        <MODELO>GLAMOUR</MODELO>      </Resultado>      <Resultado diffgr:id="Resultado2" msdata:rowOrder="1">        <BODEGA>CALI3</BODEGA>        <DESCRIPCION_BODEGA>MOTORED PRINCIPAL</DESCRIPCION_BODEGA>        <DISPONIBLE>3</DISPONIBLE>        <COLOR>BLANCO</COLOR>        <PLAN>MOTOCICLETA</PLAN>        <MODELO>GLAMOUR</MODELO>      </Resultado>      <Resultado diffgr:id="Resultado3" msdata:rowOrder="2">        <BODEGA>CALI2</BODEGA>        <DESCRIPCION_BODEGA>MOTORED PRINCIPAL</DESCRIPCION_BODEGA>        <DISPONIBLE>2</DISPONIBLE>        <COLOR>BLANCO</COLOR>        <PLAN>MOTOCICLETA</PLAN>        <MODELO>GLAMOUR</MODELO>      </Resultado>    </NewDataSet></diffgr:diffgram></DataSet>';

        AM_Inventario_XmlStreamReaderResults results = new AM_Inventario_XmlStreamReaderResults(); 
        XmlStreamReader reader = new XmlStreamReader(str);
        AM_Inventario_XmlStreamReaderResults.Inventario[] invs = results.parseinvs(reader);

        System.debug(invs.size());

        for (AM_Inventario_XmlStreamReaderResults.Inventario inv : invs) {
            System.debug(inv);
        }

    }
}