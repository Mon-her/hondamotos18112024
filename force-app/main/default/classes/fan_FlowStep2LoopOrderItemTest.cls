@isTest(SeeAllData=true)
public class fan_FlowStep2LoopOrderItemTest {
    
    @isTest
    static void test(){
        
        OrderDeliveryMethod odm  = fan_TestDataGenerator.createOrderDeliveryMethod('001');
        insert odm;
        fan_TestDataGenerator.seedLocationData();
        List<OrderItemSummary> orderItemSummaries = seedOrderItemSummaries(odm);
         
        
        SkuQuantity substituteSkuQuantity = new SkuQuantity();
        substituteSkuQuantity.SKU = 'Substitute-1';
        substituteSkuQuantity.Quantity = 5;
        List<SkuQuantity> lstSkuQuantity = new SkuQuantity[] { substituteSkuQuantity };
                
        List<OrderItemSummary> lstAux = [SELECT Id, Product2Id, Product2.StockKeepingUnit FROM OrderItemSummary where Id =:orderItemSummaries];
        String[] productIds = new List<String>();
        
        system.debug('ee: '+lstAux.size());
        
        for(OrderItemSummary oi : lstAux){
            SkuQuantity skuQuantity = new SkuQuantity();
            skuQuantity.SKU = oi.Product2.StockKeepingUnit;
            skuQuantity.quantity = 0;
            lstSkuQuantity.add(skuQuantity);
            productIds.add(oi.Product2Id);
        }

        fan_FlowStep2LoopOrderItem.Request req = new fan_FlowStep2LoopOrderItem.Request();
        
        req.lstOrderItem = orderItemSummaries;
        req.SKUQuantityList = lstSkuQuantity;
        req.originalProductIds = productIds;
        
        system.debug('ee: '+orderItemSummaries.size());
        
        fan_FlowStep2LoopOrderItem.getAvailability(new fan_FlowStep2LoopOrderItem.Request[] { req });
    }
    
    public static List<OrderItemSummary> seedOrderItemSummaries(OrderDeliveryMethod odm){
        // Create Product Data
        Product2 p1 = new Product2();
        p1.Name = 'P1';
        p1.StockKeepingUnit = 'sku1'+DateTime.now();
        p1.ProductCode = 'sku2p1';
        insert p1;

        Product2 substitute = new Product2(
            Name = 'P1',
            StockKeepingUnit = 'Substitute-1',
            ProductCode = 'Substitute-p1'
        );
        INSERT substitute;
        INSERT new fan_RelatedProducts__c(
            fan_Source__c = p1.Id,
            fan_Target__c = substitute.Id,
            fan_RelationType__c = '3'
        );
        
        Product2 p2 = new Product2();
         p2.Name = 'P2';
         p2.StockKeepingUnit = 'sku2'+DateTime.now();
         p2.ProductCode = 'sku2p2';
         insert p2;
         
         Pricebook2  pb = new Pricebook2 ();
         pb.IsActive = true;
         pb.Name = 'Test PriceBook';
         pb.Description = 'Test';
         insert pb;
         
        PriceBookEntry pbe1 = fan_B2BTestDataFactory.createPriceBookEntry2(p1.Id, pb.Id, 1.2);
        insert pbe1;

        // Test Data for Order
        String firstName = 'Codey';
        String lastName = ' Bear';
        String fullName = firstName + lastName;
        String testEmail = 'test1@salesforce.com';
        String testPhone = '555-555-5777';
		
        Account acc = null;

         if (acc == null) {
             Account a = new Account(Name='SFDX Test');
             a.AM_Tipo_de_documento__c = 'CC';
             a.AM_Numero_de_documento__c = '22222222222';
             insert a;
             
             acc = a;
         }

        Contact contact =  fan_TestDataGenerator.getContact(acc.Id);
        if (contact == null) {
            contact = fan_TestDataGenerator.createContact(firstName, lastName, testPhone, acc.Id);
        }
        
        Saleschannel sc = fan_TestDataGenerator.createSaleschannel('RoutingTest');

        // Create Order, Order Summary, and retrieve Order Delivery Group Summary
        Order order = fan_TestDataGenerator.createOrder(acc.Id, pb.Id, sc.Id, testEmail);
        insert order;
        
		OrderDeliveryGroup orderDeliveryGroup = fan_TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, testEmail, fullName);
        insert orderDeliveryGroup;
        
        List<String> locationGroupIDs = fan_TestDataGenerator.getLocationGroupIDs();
        String reservedAtLocation = locationGroupIDs[0];
        
        OrderItem oi1 =  fan_TestDataGenerator.createOrderItem(order.Id, p1.Id, pbe1.Id, orderDeliveryGroup.Id, 200.0d, reservedAtLocation);
        insert oi1;
        
        order.Status='Activated';
        update order;
        
        String orderSummaryId = fan_TestDataGenerator.createOrderSummary(order.Id);
        System.debug('Got the ID: '+ orderSummaryId);
        
        System.debug('Order Summary Id: ' + orderSummaryId);
        
        return fan_TestDataGenerator.getOrderItemSummaries(orderSummaryId);
    }
    
}