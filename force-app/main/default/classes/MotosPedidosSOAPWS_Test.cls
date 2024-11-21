/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for MotosPedidosSOAPWS integration.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     11/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     12/11/2020      Juan Ansaldi            Class finished testing succesfully 100% class MotosPedidosSOAPWS.
*********************************************************************************************************/
@isTest
public class MotosPedidosSOAPWS_Test {
     
    private static testmethod void TestModificarPedido(){
        list<MotosPedidosSOAPWS.MotosPedidosWS> lstPedidosWS = new list<MotosPedidosSOAPWS.MotosPedidosWS>();
        MotosPedidosSOAPWS.MotosPedidosWS PedidoWS = new MotosPedidosSOAPWS.MotosPedidosWS();
        
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Account acc = [select Id, Codigo_ERP__c from Account limit 1];
        acc.Codigo_ERP__c = '1234';
        update acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
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
                AND name like '%moto%'
                LIMIT 1
            ];
            Product2 producto = new Product2();
            producto.Name = 'Honda CRV Test';
            producto.ProductCode = '123';
            producto.IsActive = true;
        	producto.RecordTypeId = rt.Id;
            insert producto;

		PriceBookEntry pbentry = new PriceBookEntry();
        pbentry.Pricebook2Id = [select Id from Pricebook2 limit 1].Id;
        pbentry.Product2Id = [select Id from Product2 limit 1].Id;
        pbentry.IsActive = true; 
        pbentry.UnitPrice = 123;
        insert pbentry;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = [select Id from Opportunity limit 1].Id;
        oli.Product2Id = [select Id from Product2 limit 1].Id;
        oli.PricebookEntryId = [select Id from PriceBookEntry limit 1].Id;
        oli.Quantity = 12;
        oli.TotalPrice = 1200;
        insert oli;
        
        Order ord = new Order();
		ord.AccountId = [select Id from Account limit 1].Id;
        ord.OpportunityId = [select Id from Opportunity limit 1].Id;
        ord.Pricebook2Id = standardPricebook.Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        insert ord;
        
        OrderItem oItem = new OrderItem();
        oItem.OrderId = [select Id from Order limit 1].Id;
        oItem.PricebookEntryId = [select Id from PriceBookEntry limit 1].Id;
        oItem.Product2Id = [select Id from Product2 limit 1].Id;
        oItem.Quantity = 12;
        oItem.UnitPrice = 1200;
        insert oItem;
        
        PedidoWS.VBAK_VBELN = '123';
        PedidoWS.VBAK_ABRVW = '08';
        PedidoWS.VBAK_BNDDT = '2020-12-31';
        PedidoWS.VBAP_MATNR = '001';
        PedidoWS.VBAP_NETWR = '123';
        PedidoWS.VSOAT = '233';
        PedidoWS.VMATRI = '123';
        PedidoWS.VCINIC = '123';
        PedidoWS.VSEGR = '123';
        PedidoWS.VDESC = '123';
        PedidoWS.VBAK_KUNAG = '123';
        PedidoWS.VBAK_KUNNG = '123';
        PedidoWS.VBAK_PERNR1 = '123';
        PedidoWS.VBAK_PERNR2 = '123';
    	lstPedidosWS.add(PedidoWS);
        test.startTest();
        MotosPedidosSOAPWS.ModificarPedido(lstPedidosWS);
		test.stopTest();
        //Enviar pedido vacío para ocasionar error que entra al catch
        MotosPedidosSOAPWS.MotosPedidosWS pedidoVacio = new MotosPedidosSOAPWS.MotosPedidosWS();
        list<MotosPedidosSOAPWS.MotosPedidosWS> lstPedidoVacio = new list<MotosPedidosSOAPWS.MotosPedidosWS>();
        
        PedidoWS.VBAK_VBELN = '123';
        pedidoVacio.VBAK_BNDDT = '2023302-12-31';
        pedidoVacio.VBAK_KUNAG = '324432344322433223';
        pedidoVacio.VSOAT = '2333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333';
        lstPedidoVacio.add(pedidoVacio);
        MotosPedidosSOAPWS.ModificarPedido(lstPedidoVacio);

    }
}