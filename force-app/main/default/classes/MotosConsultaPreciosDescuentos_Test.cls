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
* @version  1.1     20/11/2020      Juan Ansaldi            Class finished testing succesfully class MotosCreacionPedidoEnSAP. 
*********************************************************************************************************/
@isTest
public class MotosConsultaPreciosDescuentos_Test {
    @isTest
    static void TestConsultaPrecioDescuento(){
          	Triggerhandler.bypass('OpportunityTriggerHandler');
            Triggerhandler.bypass('QuoteTriggerHandler');
            Triggerhandler.bypass('AccountTriggerHandler');
        
            List<Account> acc = TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);
            Opportunity opp = new Opportunity();
            opp.AccountId = acc[0].Id;
            opp.Name = 'Name';
            opp.StageName = '-P0';
            opp.CloseDate = Date.newInstance(2010, 12, 30);
            opp.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
            opp.Fecha_de_validez__c = Date.newInstance(2010, 10, 30);
            opp.Tipo_de_Pago__c = 	'101';
            opp.Destinatario_Factura__c = acc[0].Id;
            opp.Destinatario_Mercanc_a__c = acc[0].Id;
            opp.Pagador__c = acc[0].Id;
            opp.Titular_prendario__c = acc[0].Id;
            opp.Codigo_Tercero_SAP__c = acc[0].Id;
            opp.Codigo_Usuario_SAP__c = acc[0].Id;
            opp.OwnerId = [select Id, OwnerId from account Limit 1].OwnerId;
        	opp.Convenio__c = 'Empresarial';
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
            
			PriceBookEntry pbe = [select Id from PriceBookEntry limit 1];
        
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
            oli.Product2Id = producto.Id;
            oli.PricebookEntryId = pbe.Id;
            oli.Quantity = 12;
            oli.Valor_soat__c = '234902';
            oli.Valor_matrcula__c = 1234;
            oli.Cuota_Inicial__c = 1234;
            oli.Valor_seguro_robo__c = 1234;
            oli.Discount = 12;
            oli.UnitPrice = 1234;
            insert oli;
            
            Quote quo = new Quote();
            quo.OpportunityId = opp.Id;
            quo.Name = 'Test 1';
            quo.Fecha_de_validez__c = Date.newInstance(2031, 12, 30);
        	quo.Fecha_de_determinacion_del_precio__c = Date.newInstance(2031, 12, 30);
            quo.Tipo_de_Pago__c = '101';
            insert quo;
        
        	Soat__c s = new Soat__c();
        	s.Name = '123';
        	s.Valor_soat__c = 123;
        	insert s;
        
        	QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = quo.Id;
            qli.Product2Id = producto.Id;
            qli.PricebookEntryId = pbe.Id;
            qli.Quantity = 132;
        	qli.Soat__c = s.Id;
        	qli.Valor_soat__c = s.Valor_soat__c;
            qli.Valor_matrcula__c = 12334;
            qli.Cuota_Inicial__c = 12334;
            qli.Valor_seguro_robo__c = 12334;
            qli.Discount = 12;
            qli.UnitPrice = 12334;
        	qli.Descuento_aplicado_antes_de_impuesto__c = 12;
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
        
        	Test.startTest();
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new FanalcaConsultaPreciosDescuentos_Mock(1));
            // Call the method that invokes a callout
            MotosConsultaPreciosDescuentos.ConsultaPreciosDescuentos(quo.Id);        	
 
       		Test.setMock(WebServiceMock.class, new FanalcaCreacionPedidosSAP_Mock(2));
            // Call the method that invokes a callout
            MotosConsultaPreciosDescuentos.ConsultaPreciosDescuentos(quo.Id);
            Test.stopTest();  
    }

    
    @isTest
    static void testearError(){
        try{
            Test.startTest();
            // This causes a fake response to be generated
            Test.setMock(WebServiceMock.class, new FanalcaCreacionPedidosSAP_Mock(3));
            // Call the method that invokes a callout
            MotosConsultaPreciosDescuentos.ConsultaPreciosDescuentos('234');
            Test.stopTest();    
        }catch(Exception ex){
            
        }
        
    }
}