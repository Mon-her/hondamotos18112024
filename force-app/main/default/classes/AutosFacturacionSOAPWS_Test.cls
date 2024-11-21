/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for AutosFacturacionSOAPWS integration.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     31/03/2021      Juan Ansaldi            Class definition.
* @version  1.1     31/03/2021      Juan Ansaldi            Class finished testing succesfully 100% class AutosFacturacionSOAPWS.
*********************************************************************************************************/
@isTest
public class AutosFacturacionSOAPWS_Test {
    @isTest
    private static void TestModificarFactura(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        list<AutosFacturacionSOAPWS.AutosInvoiceWS> lstInvoiceWS = new list<AutosFacturacionSOAPWS.AutosInvoiceWS>();
        AutosFacturacionSOAPWS.AutosInvoiceWS InvoiceWS = new AutosFacturacionSOAPWS.AutosInvoiceWS();
        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        List<Account> cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //List<Opportunity> oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        RecordType rt = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE DeveloperName = :Label.RTOportunidadAutos
   		 ];
        
              Asset a = New Asset();
        a.Name = 'hola';
        a.AccountId = cuentaPN[0].Id;
        a.Placa__c = 'abc123';
        insert a;
        
        Pricebook2 pb = New Pricebook2();
        pb.Name = 'Precios Usados';
        pb.IsActive = true;
        insert pb;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
    
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Ano__c = '2021';
        i.Caja__c = 'AT';
		i.Cilindraje__c = 1.1;
        i.Color__c = '123';
        i.Estado_Del_Vehiculo__c = 'DISPONIBLE';
        i.Linea__c = '1';
        i.Marca__c = '123';
        i.Nombre_De_Producto__c = '123';
        i.Placas__c = 'abc123';
        i.Tipo_de_Combustible__c = 'DIESEL';
        i.Traccion__c = '2WD';
        i.Version__c = '1';
        i.Kilometraje__c = '123';
        i.Precio_Venta__c = 123;
        i.Vin__c = '123';
        insert i;
        
        Opportunity opp = New Opportunity();
        opp.Tipo_de_Oportunidad__c = 'Usados';
        opp.Name = 'Opp123';
        opp.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        opp.AccountId = cuentaPN[0].Id;
        opp.Tipo_de_cliente__c = 'Cliente Honda';
        opp.CloseDate = system.today();
        opp.Tipo_de_Pago__c = '101';
        opp.Temperatura_de_la_Compra__c = 'Media';
        opp.RecordTypeId = rt.Id;
        opp.StageName = 'P0';
        opp.CloseDate = Date.newInstance(2010, 12, 30);
        opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        opp.Fecha_de_validez__c = Date.today() + 10;
        opp.Tipo_de_Pago__c = 	'101';
        opp.OwnerId = Userinfo.getUserId();
        opp.AutoNumber__c = 'abc123'; //ESTO DA NULL
        opp.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        opp.Averigu_sobre_otras_marcas__c = 'No';
        opp.Tipo_de_cliente__c = 'Cliente Honda';
        opp.Temperatura_de_la_Compra__c = 'Media';
        opp.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        opp.Bodega_Usados__c = '43001';
        opp.Order_Generated__c = false;
        opp.Propietario_vehiculo__c = cuentaPN[0].Id;
        opp.Notas_de_despacho__c = 'Test';
        opp.Usado_Separado__c = i.Id;
		opp.Amount = 1.1;
        opp.Notas_de_despacho__c = 'Test';
        opp.VIN__c ='abc123';
        Concesionario__c lavitri = [Select Id from Concesionario__c Limit 1];
		opp.Vitrina_de_despacho__c = lavitri.Id;
        insert opp;
        
		System.debug(opp.Numero_de_Oportunidad__c); //ESTO DA NULL
        
        Order o = New Order ();
        o.OpportunityId = opp.Id;
        o.Name ='Test';
        o.Numero_del_pedido__c = '123';
        o.AccountId = cuentaPN[0].Id;
        o.EffectiveDate = Date.newInstance(2040, 01, 01);
        o.Status = 'Draft';
        insert o;

		 
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.Product2Id = [Select Id from product2 limit 1].Id;
        oli.PricebookEntryId = [Select Id from PricebookEntry Limit 1].Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
        insert oli; 
        
        Opportunity oppty = [Select Id, Numero_de_Oportunidad__c from Opportunity where Name = 'Opp123'];
        
        InvoiceWS.f461_referencia = oppty.Numero_de_Oportunidad__c;
        InvoiceWS.f350_consec_docto = '0';
        InvoiceWS.Estado = '1';
        InvoiceWS.Fecha_factura = '12/12/2012';
        InvoiceWS.f461_motivo = 'Algun mótivo';
        InvoiceWS.f461_descripcion_Motivo = 'Mejor competencia';
        
    	lstInvoiceWS.add(InvoiceWS);
        
        //AutosFacturacionSOAPWS.ModificarFactura(lstInvoiceWS);
        
        lstInvoiceWS[0].f461_referencia = oppty.Numero_de_Oportunidad__c;
        lstInvoiceWS[0].Estado = '2';
        //update lstInvoiceWS[0];
        
        AutosFacturacionSOAPWS.ModificarFactura(lstInvoiceWS);
        
        lstInvoiceWS[0].Estado = '1';
        AutosFacturacionSOAPWS.ModificarFactura(lstInvoiceWS);
        
        AutosFacturacionSOAPWS.AutosInvoiceWS facturaVacia = new AutosFacturacionSOAPWS.AutosInvoiceWS();
        AutosFacturacionSOAPWS.ModificarFactura(new list<AutosFacturacionSOAPWS.AutosInvoiceWS>{facturaVacia});
        
    }
}