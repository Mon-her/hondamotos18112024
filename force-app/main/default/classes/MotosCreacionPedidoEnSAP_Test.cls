/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for MotosCreacionPedidoEnSAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     14/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     20/11/2020      Juan Ansaldi            Class finished testing succesfully 100% class MotosCreacionPedidoEnSAP. 
*********************************************************************************************************/
@isTest
public class MotosCreacionPedidoEnSAP_Test {
    static RecordType rtProductoMotos = [select Id,name from recordType where sobjecttype='Product2' and name like '%moto%' limit 1];
    @isTest
    static void TestCrearPedido(){
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        
        Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema')]; 
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Integraciones', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.fanalcaSandbox');
        
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Account ctaNatural1 = TestDataUtilityClass.mapClientesMotosNatural.get(1);
        ctaNatural1.Codigo_ERP__c = '1234567890'; update ctaNatural1;
        Opportunity opp = new Opportunity();
        opp.AccountId = ctaNatural1.Id;
        opp.Name = 'Name';
        opp.StageName = '-P0';
        opp.CloseDate = Date.newInstance(2010, 12, 30);
        opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
        opp.Fecha_de_validez__c = Date.today() + 10;
        opp.Tipo_de_Pago__c = 	'101';
        opp.Destinatario_Factura__c = ctaNatural1.Id;
        opp.Destinatario_Mercanc_a__c = ctaNatural1.Id;
        opp.Pagador__c = ctaNatural1.Id;
        opp.Titular_prendario__c = ctaNatural1.Id;
        opp.Codigo_Tercero_SAP__c = ctaNatural1.Id;
        opp.Codigo_Usuario_SAP__c = ctaNatural1.Id;
        opp.OwnerId = Userinfo.getUserId();//[select Id, OwnerId from Account limit 1].OwnerId;
        opp.Motivo_de_Oportunidad_Vendida__c = 'Otras';
        opp.Averigu_sobre_otras_marcas__c = 'No';
        System.runAs(u) { insert opp; }
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'PB test';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        
        Product2 producto = new Product2();
        producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoMotos.Id;
        insert producto; 
        
        if ([select id from PricebookEntry where Product2Id=:producto.Id and Pricebook2Id=:standardPricebook.ID].size()==0){
            PriceBookEntry pbentryStandard = new PriceBookEntry();
            pbentryStandard.Pricebook2Id = standardPricebook.Id;
            pbentryStandard.Product2Id = producto.Id;
            pbentryStandard.IsActive = true; 
            pbentryStandard.UnitPrice = 123;
            insert pbentryStandard;
        }
        
        PriceBookEntry pbentry = new PriceBookEntry();
        pbentry.Pricebook2Id = pricebk.Id;
        pbentry.Product2Id = producto.Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;

        Order ord = new Order();
        ord.AccountId = ctaNatural1.Id;
        ord.OpportunityId = opp.Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        System.runAs(u) { insert ord; }
        
        Quote q = new Quote();
        q.OpportunityId = opp.Id;
        q.Pricebook2Id = pricebk.Id;
        q.RecordTypeId = [select Id from RecordType where developerName =: Label.Cotizacion_Motos].Id;
        q.Name = 'Nombre';
        q.Tipo_de_Pago__c = '101';
        q.Status = 'Cotización aceptada';
        q.Quote_PDF_Generado__c = true;
        q.Realizo_consulta_de_precios__c = true;
        System.runAs(u) { insert q; }
        system.debug('Despues de insertar Quote Limits.getQueries: ' + System.Limits.getQueries());
        
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
        System.runAs(u) { insert qli; }
        
        Concesionario__c con = new Concesionario__c();
        con.Agencia__c = 'Unico';
        con.Name = 'Palermo';
        con.OwnerId = opp.ownerId;
        System.runAs(u) { insert con; }
        
        Miembro_de_Concesionario__c mem =  new Miembro_de_Concesionario__c();
        mem.Nombre_de_asesor__c = opp.ownerId;
        mem.Concesionario__c = con.Id;
        System.runAs(u) { insert mem; }
        
        //Test.startTest(); 
        //Triggerhandler.bypass('OpportunityTriggerHandler');
        //Triggerhandler.bypass('QuoteTriggerHandler');
        system.debug('Limits.getQueries: ' + System.Limits.getQueries());
        System.runAs(u) {
            opp.SyncedQuoteId = q.Id;
            update opp;
        }
        
        Test.startTest();        
        Test.setMock(WebServiceMock.class, new FanalcaCreacionPedidosSAP_Mock(1));
        // Call the method that invokes a callout
        MotosCreacionPedidoEnSAP.CrearPedido(opp.Id);
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new FanalcaCreacionPedidosSAP_Mock(1));
        // Call the method that invokes a callout
        MotosCreacionPedidoEnSAP.CrearPedido(opp.Id);
        Test.stopTest();                     
        
    }
    
    @isTest
    static void testearError(){
        try{
            Test.startTest();
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new FanalcaCreacionPedidosSAP_Mock(2));
            // Call the method that invokes a callout
            MotosCreacionPedidoEnSAP.CrearPedido(null);
            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }
    
    @isTest
    static void testearValidacionesOpp(){
        try{
            TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
            
            //Se bypass estos triggers para no aumentar tanto las soql
            Triggerhandler.bypass('OpportunityTriggerHandler');
            Triggerhandler.bypass('QuoteTriggerHandler');
            
            Account ctaNatural1 = TestDataUtilityClass.mapClientesMotosNatural.get(1);
            ctaNatural1.Codigo_ERP__c = '1234567890'; update ctaNatural1;
            Opportunity opp = new Opportunity();
            opp.Name = 'Name';
            opp.StageName = '-P0';
            opp.CloseDate = Date.newInstance(2010, 12, 30);
            opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
            opp.Fecha_de_validez__c = Date.today() - 10;
            opp.Tipo_de_Pago__c = 	'101';
            opp.Codigo_Tercero_SAP__c = ctaNatural1.Id;
            opp.Codigo_Usuario_SAP__c = ctaNatural1.Id;
            opp.OwnerId = Userinfo.getUserId();
            opp.ID_de_pedido_ERP__c = '123456';
            insert opp;
            
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //Aqui primero retornará error de quote no sincronizada
            
             Pricebook2 pricebk = new Pricebook2();
            pricebk.Name = 'PB test';
            pricebk.IsActive = true;
            insert pricebk;
            
            Pricebook2 standardPricebook = new Pricebook2(  
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            Product2 producto = new Product2();
            producto.Name = 'Honda CRV Test';
            producto.ProductCode = '001';
            producto.IsActive = true;
            producto.RecordTypeId = rtProductoMotos.Id;
            insert producto; 
            
            PriceBookEntry pbentry = new PriceBookEntry();
            pbentry.Pricebook2Id = pricebk.Id;
            pbentry.Product2Id = producto.Id;
            pbentry.IsActive = true; 
            pbentry.UnitPrice = 123;
            insert pbentry;
            
    
            Order ord = new Order();
            ord.AccountId = ctaNatural1.Id;
            ord.OpportunityId = opp.Id;
            ord.Pricebook2Id = standardPricebook.Id;
            ord.EffectiveDate = Date.newInstance(2031, 12, 30);
            ord.Status = 'Draft';
            insert ord;
            system.debug('Antes de insertar Quote Limits.getQueries: ' + System.Limits.getQueries());
            Quote q = new Quote();
            q.OpportunityId = opp.Id;//[select Id from Opportunity limit 1].Id;
            q.Pricebook2Id = pricebk.Id;//standardPricebook.Id;
            q.RecordTypeId = [select Id from RecordType where developerName =: Label.Cotizacion_Motos].Id;
            q.Name = 'Nombre';
            q.Tipo_de_Pago__c = '101';
            q.Status = 'Cotización aceptada';
            q.Quote_PDF_Generado__c = true;
            q.Realizo_consulta_de_precios__c = false;
            insert q;           
            
            Concesionario__c con = new Concesionario__c();
            con.Agencia__c = 'Unico';
            con.Name = 'Palermo';
            con.OwnerId = opp.ownerId;
            insert con;
            
            Miembro_de_Concesionario__c mem =  new Miembro_de_Concesionario__c();
            mem.Nombre_de_asesor__c = opp.ownerId;
            mem.Concesionario__c = con.Id;
            insert mem;
            
            Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema')]; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Integraciones', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.fanalcaSandbox');
    
            system.debug('Limits.getQueries: ' + System.Limits.getQueries());
            
            System.runAs(u) {
                opp.SyncedQuoteId = q.Id;
                update opp;
            }
            Test.startTest();
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //2do retornará error de falta de motivo de opp vendida
            
            opp.Motivo_de_Oportunidad_Vendida__c = 'Otras'; update opp;
        	MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //3ro retornará error de falta de averiguó sobre otras marcas
            
            
            opp.Averigu_sobre_otras_marcas__c = 'Si'; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //4to retornará error de falta de cual marca averiguó 
            
            opp.Cu_l_marca_averigu_durante_la_compra__c = 'Yamaha'; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //5to retornará error  de que debe haber solo 1 producto
            
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
            System.runAs(u) { insert qli; }

            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //6to retornará error  de fecha de validez menor al día de hoy
            
            opp.Fecha_de_validez__c = Date.today() + 10; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //7mo retornará error  de pedido enviado ya a sap
            
            opp.ID_de_pedido_ERP__c = null; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //8vo retornará error Realizo_consulta_de_precios__c no se ha hecho en quote
            
            q.Realizo_consulta_de_precios__c = true; System.runAs(u) { update q; }
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //9no retornará error de que no hay cuenta principal

            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }
    
    @isTest
    static void testearCtas(){
        try{
            TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
            
            //Se bypass estos triggers para no aumentar tanto las soql
            Triggerhandler.bypass('OpportunityTriggerHandler');
        	Triggerhandler.bypass('QuoteTriggerHandler');
            
            Account ctaNatural1 = TestDataUtilityClass.mapClientesMotosNatural.get(1);
            Opportunity opp = new Opportunity();
            opp.Name = 'Name';
            opp.StageName = '-P0';
            opp.CloseDate = Date.newInstance(2010, 12, 30);
            opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
            opp.Fecha_de_validez__c = Date.today() + 10;
            opp.Tipo_de_Pago__c = 	'101';
            opp.Codigo_Tercero_SAP__c = ctaNatural1.Id;
            opp.Codigo_Usuario_SAP__c = ctaNatural1.Id;
            opp.OwnerId = Userinfo.getUserId();
            opp.Motivo_de_Oportunidad_Vendida__c = 'Otras';
            opp.Averigu_sobre_otras_marcas__c = 'No';
            insert opp;

            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //Aqui primero retornará error de quote no sincronizada
            
             Pricebook2 pricebk = new Pricebook2();
            pricebk.Name = 'PB test';
            pricebk.IsActive = true;
            insert pricebk;
            
            Pricebook2 standardPricebook = new Pricebook2(  
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            Product2 producto = new Product2();
            producto.Name = 'Honda CRV Test';
            producto.ProductCode = '001';
            producto.IsActive = true;
            producto.RecordTypeId = rtProductoMotos.Id;
            insert producto; 
            
            PriceBookEntry pbentry = new PriceBookEntry();
            pbentry.Pricebook2Id = pricebk.Id;
            pbentry.Product2Id = producto.Id;
            pbentry.IsActive = true; 
            pbentry.UnitPrice = 123;
            insert pbentry;
            
    
            Order ord = new Order();
            ord.AccountId = ctaNatural1.Id;
            ord.OpportunityId = opp.Id;
            ord.Pricebook2Id = standardPricebook.Id;
            ord.EffectiveDate = Date.newInstance(2031, 12, 30);
            ord.Status = 'Draft';
            insert ord;
            
            Quote q = new Quote();
            q.OpportunityId = opp.Id;
            q.Pricebook2Id = pricebk.Id;
            q.RecordTypeId = [select Id from RecordType where developerName =: Label.Cotizacion_Motos].Id;
            q.Name = 'Nombre';
            q.Tipo_de_Pago__c = '101';
            q.Status = 'Cotización aceptada';
            q.Quote_PDF_Generado__c = true;
            q.Realizo_consulta_de_precios__c = true;
            insert q;
            
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
            
            Concesionario__c con = new Concesionario__c();
            con.Agencia__c = 'Unico';
            con.Name = 'Palermo';
            con.OwnerId = opp.ownerId;
            insert con;
            
            Miembro_de_Concesionario__c mem =  new Miembro_de_Concesionario__c();
            mem.Nombre_de_asesor__c = opp.ownerId;
            mem.Concesionario__c = con.Id;
            insert mem;
            
            Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema')]; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Integraciones', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.fanalcaSandbox');
            
            System.runAs(u) {
                opp.SyncedQuoteId = q.Id;
                update opp;
            }
            Test.startTest();
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //1ro retornará error de falta de cuenta principal
         
            opp.AccountId = ctaNatural1.Id; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //2do retornará error de falta de pagador
            
            opp.Pagador__c = ctaNatural1.Id; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //3ro retornará error de falta de destinatario factura
            
            opp.Destinatario_Factura__c = ctaNatural1.Id; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //4to retornará error de falta de destinatario mercancia
            
            opp.Destinatario_Mercanc_a__c = ctaNatural1.Id; update opp;
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //5to retornará error de falta de titular prendario
                       
            opp.Titular_prendario__c = ctaNatural1.Id; update opp;
            
            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }
    
    @isTest
    static void testearCalloutsCtas(){
        try{
            TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 5);
            
            //Se bypass estos triggers para no aumentar tanto las soql
            Triggerhandler.bypass('OpportunityTriggerHandler');
        	Triggerhandler.bypass('QuoteTriggerHandler');
            Triggerhandler.bypass('AccountTriggerHandler');
            TriggerStopper.stopOppLine = true;
            Triggerstopper.stopQuoteLine = true;
            TriggerStopper.stopOpp = true;
            TriggerStopper.stopQuote = true;
            
            Account ctaNatural1 = TestDataUtilityClass.mapClientesMotosNatural.get(1);
            Account ctaPagador = TestDataUtilityClass.mapClientesMotosNatural.get(2);
            Account ctaFactura = TestDataUtilityClass.mapClientesMotosNatural.get(3);
            Account ctaMercancia = TestDataUtilityClass.mapClientesMotosNatural.get(4);
            Account ctaPrendario = TestDataUtilityClass.mapClientesMotosNatural.get(5);
            
            Opportunity opp = new Opportunity();
            opp.AccountId = ctaNatural1.Id;
            opp.Name = 'Name';
            opp.StageName = '-P0';
            opp.CloseDate = Date.newInstance(2010, 12, 30);
            opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
            opp.Fecha_de_validez__c = Date.today() + 10;
            opp.Tipo_de_Pago__c = 	'101';
            opp.Destinatario_Factura__c = ctaFactura.Id;
            opp.Destinatario_Mercanc_a__c = ctaMercancia.Id;
            opp.Pagador__c = ctaPagador.Id;
            opp.Titular_prendario__c = ctaPrendario.Id;
            opp.Codigo_Tercero_SAP__c = ctaNatural1.Id;
            opp.Codigo_Usuario_SAP__c = ctaNatural1.Id;
            opp.OwnerId = Userinfo.getUserId();
            opp.Motivo_de_Oportunidad_Vendida__c = 'Otras';
            opp.Averigu_sobre_otras_marcas__c = 'No';
            insert opp;
            
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //Aqui primero retornará error de quote no sincronizada
            
            Pricebook2 pricebk = new Pricebook2();
            pricebk.Name = 'PB test';
            pricebk.IsActive = true;
            insert pricebk;
            
            Pricebook2 standardPricebook = new Pricebook2(  
                Id = Test.getStandardPricebookId(),
                IsActive = true
            );
            Update standardPricebook;
            
            Product2 producto = new Product2();
            producto.Name = 'Honda CRV Test';
            producto.ProductCode = '001';
            producto.IsActive = true;
            producto.RecordTypeId = rtProductoMotos.Id;
            insert producto; 
            
            PriceBookEntry pbentry = new PriceBookEntry();
            pbentry.Pricebook2Id = pricebk.Id;
            pbentry.Product2Id = producto.Id;
            pbentry.IsActive = true; 
            pbentry.UnitPrice = 123;
            insert pbentry;
            
    
            Order ord = new Order();
            ord.AccountId = ctaNatural1.Id;
            ord.OpportunityId = opp.Id;
            ord.Pricebook2Id = standardPricebook.Id;
            ord.EffectiveDate = Date.newInstance(2031, 12, 30);
            ord.Status = 'Draft';
            insert ord;

            Quote q = new Quote();
            q.OpportunityId = opp.Id;
            q.Pricebook2Id = pricebk.Id;
            q.RecordTypeId = [select Id from RecordType where developerName =: Label.Cotizacion_Motos].Id;
            q.Name = 'Nombre';
            q.Tipo_de_Pago__c = '101';
            q.Status = 'Cotización aceptada';
            q.Quote_PDF_Generado__c = true;
            q.Realizo_consulta_de_precios__c = true;
            insert q;
            
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
           
            
            Concesionario__c con = new Concesionario__c();
            con.Agencia__c = 'Unico';
            con.Name = 'Palermo';
            con.OwnerId = opp.ownerId;
            insert con;
            
            Miembro_de_Concesionario__c mem =  new Miembro_de_Concesionario__c();
            mem.Nombre_de_asesor__c = opp.ownerId;
            mem.Concesionario__c = con.Id;
            insert mem;
            
            Profile p = [SELECT Id FROM Profile WHERE Name in ('System Administrator','Administrador del Sistema')]; 
            User u = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                EmailEncodingKey='UTF-8', LastName='Integraciones', LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', ProfileId = p.Id, 
                TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.fanalcaSandbox');
            
            Test.startTest();
            System.runAs(u) {
                opp.SyncedQuoteId = q.Id;
                update opp;
            }
            //Test.startTest();
            
            
            Test.setMock(WebServiceMock.class, new FanalcaCrearModificarClientesSAP_Mock(1));
            MotosCreacionPedidoEnSAP.CrearPedido(opp.Id); //1ro retornará error de 
            
            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }
}