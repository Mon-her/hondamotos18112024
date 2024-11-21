/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for MotosModificarFacturaSOAPWS integration.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     11/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     12/11/2020      Juan Ansaldi            Class finished testing succesfully 100% class MotosModificarFacturaSOAPWS.
*********************************************************************************************************/
@isTest
public class MotosModificarFacturaSOAPWS_Test {
     
    private static testmethod void TestModificarFatura(){
        list<MotosModificarFacturaSOAPWS.MotosFacturaWS> lstFacturaWS = new list<MotosModificarFacturaSOAPWS.MotosFacturaWS>();
        MotosModificarFacturaSOAPWS.MotosFacturaWS FacturaWS = new MotosModificarFacturaSOAPWS.MotosFacturaWS();
        
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
        Opportunity opp = new Opportunity();
        opp.AccountId = [select Id from Account limit 1].Id;
        opp.Name = 'Name';
        opp.StageName = '-P0';
        opp.CloseDate = Date.newInstance(2040, 12, 30);
        opp.ID_de_pedido_ERP__c = '123';
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
        
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
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

		/*PriceBookEntry pbentry = new PriceBookEntry();
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
        
        Order ord = new Order();
		ord.AccountId = [select Id from Account limit 1].Id;
        ord.OpportunityId = [select Id from Opportunity limit 1].Id;
        ord.EffectiveDate = Date.newInstance(2031, 12, 30);
        ord.Status = 'Draft';
        insert ord;
        
        FacturaWS.VBAK_BSTKD = '123';
		FacturaWS.VBRK_VBELN_VF = '83271987';
        FacturaWS.VBRK_FKDAT = '31/12/1997';
        FacturaWS.VBRK_FSKTO = '3242';
        FacturaWS.VBRK_ZZANUL = '22';
        
    	lstFacturaWS.add(FacturaWS);
        test.startTest();
        MotosModificarFacturaSOAPWS.ModificarPedido(lstFacturaWS);

        lstFacturaWS[0].VBRK_FSKTO = '32892989633333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333424675321';
        MotosModificarFacturaSOAPWS.ModificarPedido(lstFacturaWS);
        test.stopTest();
        lstFacturaWS[0].VBRK_ZZANUL = '32892989633333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333424675321';
        MotosModificarFacturaSOAPWS.ModificarPedido(lstFacturaWS);
        
        //Enviar pedido vacío para ocasionar error que entra al catch
        MotosModificarFacturaSOAPWS.MotosFacturaWS pedidoVacio = new MotosModificarFacturaSOAPWS.MotosFacturaWS();
        list<MotosModificarFacturaSOAPWS.MotosFacturaWS> lstPedidoVacio = new list<MotosModificarFacturaSOAPWS.MotosFacturaWS>();
        lstPedidoVacio.add(pedidoVacio);
        
        MotosModificarFacturaSOAPWS.MotosFacturaWS pedidoVacio1;
        MotosModificarFacturaSOAPWS.ModificarPedido(new list<MotosModificarFacturaSOAPWS.MotosFacturaWS>{pedidoVacio1});
        
        lstFacturaWS[0].VBAK_BSTKD = '32893229896424675321';
        MotosModificarFacturaSOAPWS.ModificarPedido(lstFacturaWS);

    }
}