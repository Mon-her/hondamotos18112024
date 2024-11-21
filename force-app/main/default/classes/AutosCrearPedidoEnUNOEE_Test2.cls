@isTest
public class AutosCrearPedidoEnUNOEE_Test2 {
    
    private static testmethod void testEnviarPedidoAUNOEE151645(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.Registro_Migrado__c  = true;
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'VH-80123';
        
        opp.Tipo_Impo_Utilidad__c = '151645';
        opp.Valor_Utilidad__c = 9000000;
        opp.Vitrina__c = TestDataUtilityClass.mapConcesionarios.get(1).Id;
        
        update opp;

		//Account acc = [Select Id from Account Limit 1];        
        //String msg = AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        //if (msg.toUpperCase().contains('ERROR')){
        //    throw new AuraHandledException(msg);
        //}
        
        futureMethod(opp.Id);
            
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
    
    private static testmethod void testEnviarPedidoAUNOEE(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
       // op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'VH-03123';
        
        opp.Tipo_Impo_Utilidad__c = '73282';
        opp.Valor_Utilidad__c = 9000000;
        opp.Vitrina__c = TestDataUtilityClass.mapConcesionarios.get(1).Id;
        
        update opp;

		Account acc = [Select Id from Account Limit 1];        
        //String msg = AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        //if (msg.toUpperCase().contains('ERROR')){
        //    throw new AuraHandledException(msg);
        //}
        
        futureMethod(opp.Id);
            
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
        
    @future(callout=true)
    public static void futureMethod(Id oppId){
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        String nuevos = AutosCrearPedidoEnUNOEE.EnviarPedido(oppId);
        system.debug('respuesta: ' + nuevos);
        if (nuevos.toUpperCase().contains('ERROR')){
            //throw new  AuraHandledException(nuevos);
    //        throw new IllegalArgumentException(nuevos);
        }
    }
    
   // @future(callout=true)
    public static void futureMethodUpdate(Id oppId){
        try{
        Opportunity opp1 = New Opportunity();
        opp1.Id = oppId;
        opp1.Facturar_a_nombre_de__c = null;
        update opp1;
        String nuevos = AutosCrearPedidoEnUNOEE.EnviarPedido(oppId);
        }catch(Exception ex){
            
        }
    }
    
   // @future(callout=true)
    public static void futureMethodUpdate2(Id oppId, Id accId){
        
        List<product2> p = [Select Id, Name from Product2];
        for(Product2 p1 : p) {
            Product2 p2 = New Product2();
            p2.Id = p1.Id;
            p2.Name = 'Test';
            Update p2;
        }
        
        List<OpportunityLineItem> oli = [Select Name, Descuento_valor__c, Id from OpportunityLineItem];
        for(OpportunityLineItem p1 : oli) {
            OpportunityLineItem p2 = New OpportunityLineItem();
            p2.Id = p1.Id;
            p2.Descuento_valor__c = 23;
            Update p2;
        }
        
        Opportunity opp1 = New Opportunity();
        opp1.Id = oppId;
        opp1.Facturar_a_nombre_de__c = accId;
        update opp1;
        
        String nuevos = AutosCrearPedidoEnUNOEE.EnviarPedido(oppId);
        
    }
    
    @future(callout=true)
    public static void futureMethodUpdate3(Id oppId, Id accId){
        Opportunity opp1 = New Opportunity();
        opp1.Id = oppId;
        opp1.Facturar_a_nombre_de__c = accId;
        opp1.Tipo_Impo_Utilidad__c = '151645';
        opp1.Valor_Utilidad__c = 9000000;
        update opp1;
        
        String nuevos = AutosCrearPedidoEnUNOEE.EnviarPedido(oppId);
        
    }
    
    @future(callout=true)
    public static void futureMethodUpdate4(Id oppId, Id accId){
        Opportunity opp1 = New Opportunity();
        opp1.Id = oppId;
        opp1.Facturar_a_nombre_de__c = accId;
        opp1.Forma_de_pago__c ='Contado + Retoma';
        opp1.Marca_retoma__c = 'Audi';
        opp1.Version_retoma__c = 'Test';
        opp1.Modelo_retoma__c = 'Test';
        update opp1;
        
        String nuevos = AutosCrearPedidoEnUNOEE.EnviarPedido(oppId);
        
    }
    
    @future(callout=true)
    public static void futureMethodUpdate5(Id oppId, Id accId){
        
 		OpportunityLineItem oli = [Select Name, Descuento_valor__c, Id from OpportunityLineItem];
        oli.Descuento_valor__c = 23;
        update oli;
        
        Opportunity opp1 = New Opportunity();
        opp1.Id = oppId;
        opp1.Facturar_a_nombre_de__c = accId;
        opp1.Tipo_Impo_Utilidad__c = '151645';
        opp1.Valor_Utilidad__c = 9000000;
        update opp1;
        
        String nuevos = AutosCrearPedidoEnUNOEE.EnviarPedido(oppId);
        
    }

    
    private static testmethod void testEnviarPedidoAUNOEE_renting(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'Consignación';        
        insert i;
        
        Product2 producto = new Product2();
      //  producto.Name = 'odysey';
        producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
       // producto.Inventario_de_Usados__c = i.Id;
        insert producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Renting';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
       // op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'VH-03123';
        
        opp.Tipo_Impo_Utilidad__c = '73282';
        opp.Valor_Utilidad__c = 9000000;
        opp.Vitrina__c = TestDataUtilityClass.mapConcesionarios.get(1).Id;
        
        update opp;

		Account acc = [Select Id from Account Limit 1];        
        //String msg = AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        //if (msg.toUpperCase().contains('ERROR')){
        //    throw new AuraHandledException(msg);
        //}
        
        futureMethod(opp.Id);
            
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
/*
	private static testmethod void testEnviarPedidoAUNOEE2(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
      
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P0';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'tst123';
        
        opp.Tipo_Impo_Utilidad__c = '73282';
        
        update opp;

		Account acc = [Select Id from Account Limit 1];        
        AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
         
    private static testmethod void testEnviarPedidoAUNOEE3(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
       
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P0';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'tst123';
        
        opp.Tipo_Impo_Utilidad__c = '73282';
        
        update opp;

		Account acc = [Select Id from Account Limit 1];        
        //AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
    
    private static testmethod void testEnviarPedidoAUNOEE4(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
       
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P0';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'tst123';
        
        opp.Tipo_Impo_Utilidad__c = '73282';
        
        update opp;

		Account acc = [Select Id from Account Limit 1];        
        //AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
    
    private static testmethod void testEnviarPedidoAUNOEE5(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
       
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P0';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'tst123';
        
        opp.Tipo_Impo_Utilidad__c = '73282';
        
        update opp;

		Account acc = [Select Id from Account Limit 1];        
        //AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
 */
  
    private static testmethod void testEnviarPedidoAUNOEENuevos(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        op.Vitrina__c = [Select Id from Concesionario__c Limit 1].Id;//TestDataUtilityClass.mapConcesionarios.get(1).Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        Account acc = [Select Id from Account Limit 1];
        Opportunity op2 = new Opportunity();
        op2.Name = 'Opp123';
        op2.Facturar_a_nombre_de__c = acc.Id;
        op2.AccountId = acc.Id;
        op2.Tipo_de_cliente__c = 'Cliente Honda';
        op2.CloseDate = system.today();
        op2.Tipo_de_Pago__c = '101';
        op2.Temperatura_de_la_Compra__c = 'Media';
        op2.RecordTypeId = rt.Id;
        op2.StageName = 'P3';
        op2.CloseDate = Date.newInstance(2010, 12, 30);
        op2.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op2.Fecha_de_validez__c = Date.today() + 10;
        op2.Tipo_de_Pago__c = 	'101';
        op2.OwnerId = Userinfo.getUserId();
        op2.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op2.Averigu_sobre_otras_marcas__c = 'No';
        op2.Tipo_de_cliente__c = 'Cliente Honda';
        op2.Temperatura_de_la_Compra__c = 'Media';
		op2.Amount = 1.1;
        op2.Notas_de_despacho__c = 'Test';
        op2.Tipo_de_Oportunidad__c = 'Nuevos';
        op2.VIN__c ='VH-00193';
        Concesionario__c lavitri = [Select Id from Concesionario__c Limit 1];
		op2.Vitrina_de_despacho__c = lavitri.Id;
        op2.Vitrina__c = lavitri.Id;
        system.debug('hola'+lavitri);
        op2.Order_Generated__c = true;
        insert op2;
        
        Product2 product = [Select Id from Product2 Limit 1];
        PricebookEntry pb = [Select Id from PricebookEntry Limit 1];
        OpportunityLineItem oli1 = new OpportunityLineItem();
        oli1.OpportunityId = op2.Id;
        oli1.Product2Id = product.ID;
        oli1.PricebookEntryId = pb.Id;
        oli1.Quantity = 132;
        oli1.Valor_soat__c = '2343902';
        oli1.Valor_matrcula__c = 12334;
        oli1.Cuota_Inicial__c = 12334;
        oli1.Valor_seguro_robo__c = 12334;
        oli1.Descuento_Valor__c = 23;
        oli1.UnitPrice = 12334;
         
        insert oli1; 
        

        Opportunity opp1 = [select Id, Name from Opportunity where Name = 'Opp123' Limit 1];
        
        futureMethod(opp1.Id);
        Account acc1 = [Select Id from Account Limit 1];
        //futureMethodUpdate2(opp1.Id, acc1.Id);
        
        try{
            futureMethodUpdate(opp1.Id);
        }
        catch(exception ex){}
    }
    
    @isTest
    public static void testEnviarPedidoASF(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        Test.startTest();
            
        Opportunity opp = [select Id, Name from Opportunity Limit 1];
        String hola = AutosCrearPedidoEnSF.EnviarPedido(opp.Id);
    	Test.stopTest();
    }
    
    private static testmethod void testEnviarPedidoAUNOEE1516452(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.Registro_Migrado__c  = true;
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        //insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'VH-80123';
        
        opp.Tipo_Impo_Utilidad__c = '151645';
        opp.Valor_Utilidad__c = 9000000;
        opp.Vitrina__c = TestDataUtilityClass.mapConcesionarios.get(1).Id;
        
        update opp;

		//Account acc = [Select Id from Account Limit 1];        
        //String msg = AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        //if (msg.toUpperCase().contains('ERROR')){
        //    throw new AuraHandledException(msg);
        //}
        
        futureMethod(opp.Id);   
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
    private static testmethod void testEnviarPedidoAUNOEE1516453(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        Triggerhandler.bypass('CaseTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> cuentaPN;
        List<Account> cuentaPJ;
        
        RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
        RecordType rt = [
          SELECT Id, DeveloperName
          FROM RecordType
          WHERE DeveloperName = :Label.RTOportunidadAutos
        ];

        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        //oppList = TestDataUtilityClass.crearOportunidadAutos(1);
        //oppList[0].Tipo_de_Oportunidad__c = 'Usados';
        //update oppList;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'Precios Usados';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        Inventario_de_Usados__c i = New Inventario_de_Usados__c();
        i.Color__c = 'Test';
        i.Origen__c = 'RENTING';
        insert i;
        
        Product2 producto = [Select Id from Product2 Limit 1];
        producto.Name = 'odysey';
        update producto;
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        /*producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        producto.Inventario_de_Usados__c = i.Id;
        insert producto; */
        
        /*if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        PriceBookEntry pbentry = [SELECT Id from Pricebookentry Limit 1];

        
        Opportunity op = new Opportunity();
        op.Name = 'Opp 1';
        op.AccountId = cuentaPN[0].Id;
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.CloseDate = system.today();
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Tipo_de_Pago__c = '101';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.StageName = 'P3';
        op.RecordTypeId = rt.Id;
        op.CloseDate = Date.newInstance(2010, 12, 30);
        op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        op.Fecha_de_validez__c = Date.today() + 10;
        op.OwnerId = Userinfo.getUserId();
        op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        op.Averigu_sobre_otras_marcas__c = 'No';
        op.Tipo_de_cliente__c = 'Cliente Honda';
        op.Temperatura_de_la_Compra__c = 'Media';
        op.Registro_Migrado__c  = true;
		op.Amount = 1.1;
        op.Tipo_de_Oportunidad__c = 'Usados';
        op.Facturar_a_nombre_de__c = cuentaPN[0].Id;
        op.Bodega_Usados__c = '43001';
        op.Order_Generated__c = false;
        op.Propietario_vehiculo__c = cuentaPN[0].Id;
        op.Notas_de_despacho__c = 'Test';
        op.Vitrina_de_despacho__c = [Select Id from Concesionario__c Limit 1].Id;
        //op.Creado_en_UNOEE__c = false;
        op.Usado_Separado__c = i.Id;
        insert op;
        
        
        Order ord = new Order();
        ord.AccountId = cuentaPN[0].Id;
        ord.OpportunityId = op.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        ///System.runAs(u) { 
        insert ord; ///}
        
        Quote q = new Quote();
        q.OpportunityId = op.Id;
        q.Pricebook2Id = standardPricebook.Id;
        //q.RecordTypeId = [select Id from RecordType where developerName = 'Cotizaciones_Autos'].Id;
        q.Name = 'Nombre';
        //q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        ///System.runAs(u) { 
        insert q; ///}
        
        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = q.Id;
        qli.Product2Id = producto.ID;
        qli.PricebookEntryId = pbentry.Id;
        qli.Quantity = 132;
        qli.Valor_soat__c = 2343902;
        qli.Valor_matrcula__c = 12334;
        qli.Cuota_Inicial__c = 12334;
        qli.Valor_seguro_robo__c = 12334;
        qli.Descuento_Valor__c = 23;
        qli.UnitPrice = 12334;
        insert qli;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = op.Id;
        oli.Product2Id = producto.ID;
        oli.PricebookEntryId = pbentry.Id;
        oli.Quantity = 132;
        oli.Valor_soat__c = '2343902';
        oli.Valor_matrcula__c = 12334;
        oli.Cuota_Inicial__c = 12334;
        oli.Valor_seguro_robo__c = 12334;
        oli.Descuento_Valor__c = 23;
        oli.UnitPrice = 12334;
         
        insert oli; 
        
        TEst.startTest();
        Test.setMock(WebServiceMock.class, new FanalcaComSfcsalesorder2unoe_Mock());
        FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER objWS = new FanalcaComSfcsalesorder2unoe.DT_CREATE_SALES_ORDER();
        
        Opportunity opp = [select Id, Name from Opportunity where Name = 'Opp 1' Limit 1];
        opp.Order_Generated__c = true;
        opp.VIN__c = 'VH-80123';
        
        opp.Tipo_Impo_Utilidad__c = '151645';
        opp.Valor_Utilidad__c = 9000000;
        opp.Vitrina__c = TestDataUtilityClass.mapConcesionarios.get(1).Id;
        
        opp.Se_creo_pedido_en_UNOEE__c = true;
        update opp;

		//Account acc = [Select Id from Account Limit 1];        
        //String msg = AutosCrearPedidoEnUNOEE.EnviarPedido(opp.Id);//futureMethod(opp.Id);
        //if (msg.toUpperCase().contains('ERROR')){
        //    throw new AuraHandledException(msg);
        //}
        
        futureMethod(opp.Id);  
        //opp.Tipo_Impo_Utilidad__c = '73282';
        //update opp;
        //futureMethodUpdate2(opp.Id, acc.Id);
        //futureMethodUpdate3(opp.Id, acc.Id);
        //futureMethodUpdate4(opp.Id, acc.Id);
        //futureMethodUpdate5(opp.Id, acc.Id);
       
    	Test.stopTest();
    }
        
}