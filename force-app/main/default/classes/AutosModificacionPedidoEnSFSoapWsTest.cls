@isTest
private class AutosModificacionPedidoEnSFSoapWsTest {
    private static Map<String, Object> objects = mock();
    private static Account personaNaturalAccount;
    private static Map<String, Object> mock() {
        Map<String, Object> objects = new Map<String, Object>();
        List<Account> personaNaturalAccounts = TestDataUtilityClass.crearCuentasAutos(
            1,
            Label.AutosRecordTypeDevNameAccountNatural
        );
        personaNaturalAccount = personaNaturalAccounts[0];
        
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        
        Opportunity opp = new Opportunity();
        opp.AccountId = personaNaturalAccount.Id;
        opp.ID_de_pedido_ERP__c = '123';
        opp.Name = 'Name';
        opp.StageName = '-P0';
        opp.CloseDate = Date.newInstance(2040, 12, 30);
        insert opp;
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'PB test';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        Update standardPricebook;
        
        RecordType rt = [
            SELECT id, DeveloperName
            FROM RecordType
            WHERE
            sobjecttype = 'Product2'
            AND isActive = TRUE
            AND name like '%auto%'
            LIMIT 1
        ];
        Product2 producto = new Product2();
        producto.Name = 'Honda CRV Test';
        producto.ProductCode = '123';
        producto.IsActive = true;
        producto.RecordTypeId = rt.Id;
        insert producto;
        
        if (   [ SELECT id FROM PricebookEntry     WHERE   Product2Id = :producto.Id   AND Pricebook2Id = :Test.getStandardPricebookId() ].size() == 0    ) {
            PriceBookEntry pbentry = new PriceBookEntry();
            pbentry.Pricebook2Id = [select Id from Pricebook2 limit 1].Id;
            pbentry.Product2Id = [select Id from Product2 limit 1].Id;
            pbentry.IsActive = true; 
            pbentry.UnitPrice = 123;
            insert pbentry;
    	}
        /*
        PriceBookEntry pbentry = new PriceBookEntry();
        pbentry.Pricebook2Id = [select Id from Pricebook2 limit 1].Id;
        pbentry.Product2Id = [select Id from Product2 limit 1].Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;*/
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = [select Id from Opportunity limit 1].Id;
        oli.Product2Id = [select Id from Product2 limit 1].Id;
        oli.PricebookEntryId = [select Id from PriceBookEntry limit 1].Id;
        oli.Quantity = 12;
        oli.TotalPrice = 1200;
        insert oli;
        
        Order order1 = new Order();
        order1.AccountId = personaNaturalAccount.Id;
        order1.Status = 'Draft';
        order1.EffectiveDate = Date.today();
        order1.OpportunityId = opp.Id;
        
        insert order1;
        order1 = [SELECT Id, OrderNumber FROM Order WHERE Id = :order1.Id LIMIT 1];
        objects.put('order1', order1);
        
        return objects;
    }
    
    @isTest
    static void confirmar() {
        Order order1 = (Order) objects.get('order1');
        
        AutosModificacionPedidoEnSFSoapWs.ConfirmarInput input1 = new AutosModificacionPedidoEnSFSoapWs.ConfirmarInput();
        input1.Consecutivo_pedido = order1.OrderNumber;
        input1.Pedido_creado_ERP = true;
        input1.Estado_Pedido_en_ERP = 'Estado de Pruebaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        
        List<AutosModificacionPedidoEnSFSoapWs.ConfirmarInput> inputs = new List<AutosModificacionPedidoEnSFSoapWs.ConfirmarInput>();
        inputs.add(input1);
        
        List<AutosModificacionPedidoEnSFSoapWs.Output> outputs = AutosModificacionPedidoEnSFSoapWs.confirmar(
            inputs
        );
        System.assert(outputs.size() == inputs.size(), true);
        
        order1 = [
            SELECT Id, OrderNumber, Pedido_creado_ERP__c, Estado_Pedido_en_ERP__c
            FROM Order
            WHERE Id = :order1.Id
            LIMIT 1
        ];
        AutosModificacionPedidoEnSFSoapWs.Output output1 = outputs[0];
        //System.assert(output1.error == '', true);
        /*System.assert(
            order1.Pedido_creado_ERP__c == input1.Pedido_creado_ERP,
            true
        );
        System.assert(
            order1.Estado_Pedido_en_ERP__c == input1.Estado_Pedido_en_ERP,
            true
        );*/
        
        AutosModificacionPedidoEnSFSoapWs.ConfirmarInput input2 = new AutosModificacionPedidoEnSFSoapWs.ConfirmarInput();        
        List<AutosModificacionPedidoEnSFSoapWs.ConfirmarInput> inputs2 = new List<AutosModificacionPedidoEnSFSoapWs.ConfirmarInput>();
        input2.Consecutivo_pedido = 'order1.OrderNumber';
        input2.Pedido_creado_ERP = true;
        input2.Estado_Pedido_en_ERP = 'Estado de Pruebaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
        
        inputs.add(input2);
        
        List<AutosModificacionPedidoEnSFSoapWs.Output> outputs2 = AutosModificacionPedidoEnSFSoapWs.confirmar(
            inputs
        );
        AutosModificacionPedidoEnSFSoapWs.Output output2 = outputs2[0];
        //System.assert(output2.error == '', true);
    }
    
    @isTest
    static void modificar() {
        Order order1 = (Order) objects.get('order1');
        Test.startTest();
        AutosModificacionPedidoEnSFSoapWs.ModificarInput input1 = new AutosModificacionPedidoEnSFSoapWs.ModificarInput();
        input1.f431_referencia_item = 'UNOEE-0011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111';
        input1.f431_precio_unitario = 10.10;
        input1.f430_num_docto_referencia = order1.OrderNumber;
        
        List<AutosModificacionPedidoEnSFSoapWs.ModificarInput> inputs = new List<AutosModificacionPedidoEnSFSoapWs.ModificarInput>();
        inputs.add(input1);
        
        List<AutosModificacionPedidoEnSFSoapWs.Output> outputs = AutosModificacionPedidoEnSFSoapWs.modificar(
            inputs
        );
        System.assert(outputs.size() == inputs.size(), true);
        
        order1 = [
            SELECT
            Id,
            OrderNumber,
            Pedido_creado_ERP__c,
            Estado_Pedido_en_ERP__c,
            Precio_de_vehiculo_IVA_incluido__c
            FROM Order
            WHERE Id = :order1.Id
            LIMIT 1
        ];
        AutosModificacionPedidoEnSFSoapWs.Output output1 = outputs[0];
        /*System.assert(output1.error == '', true);
        System.assert(
            order1.Precio_de_vehiculo_IVA_incluido__c == input1.f431_precio_unitario,
            true
        );*/
        
        AutosModificacionPedidoEnSFSoapWs.ModificarInput input2 = new AutosModificacionPedidoEnSFSoapWs.ModificarInput();
        List<AutosModificacionPedidoEnSFSoapWs.ModificarInput> inputs2 = new List<AutosModificacionPedidoEnSFSoapWs.ModificarInput>();
        inputs2.add(input2);
        
        List<AutosModificacionPedidoEnSFSoapWs.Output> outputs2 = AutosModificacionPedidoEnSFSoapWs.modificar(
            inputs2
        );
        
        AutosModificacionPedidoEnSFSoapWs.Output output2 = outputs2[0];
        System.assert(output2.error == 'List has no rows for assignment to SObject', true);
        
        Test.stopTest();
    }
}