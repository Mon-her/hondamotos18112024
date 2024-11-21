@isTest(SeeAllData=true)
public with sharing class fan_UpdateOrderItemSummaryTest {
   


    @IsTest
    static void updateItemSummary(){
        String pricebookId = Test.getStandardPricebookId();

        Account account = fan_B2BTestDataFactory.createAccount('5311581', 'NIT');
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('Test WebStore');
        WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, 'contado');
        Order order = fan_B2BTestDataFactory.createOrder(account.Id, pricebookId);
        Product2 product = fan_B2BTestDataFactory.createProduct('sku1', 'Product1', null);
        PricebookEntry pricebookEntry = [Select id from PricebookEntry where Product2Id =:product.id and Pricebook2Id = :pricebookId];
        fan_B2BTestDataFactory.createOrderItem(order.Id, product.Id, pricebookEntry.Id, 31, 434, 14);
        OrderDeliveryMethod odm  = TestDataGenerator.createOrderDeliveryMethod('001');
        insert odm;
        String firstName = 'Codey';
        String lastName = ' Bear';
        String fullName = firstName + lastName;
        String testEmail = 'test1@salesforce.com';
        String testPhone = '555-555-5777';
        OrderDeliveryGroup orderDeliveryGroup = TestDataGenerator.createOrderDeliveryGroup(order.Id, odm.Id, testEmail, fullName);
        insert orderDeliveryGroup;
        OrderItem oi = [select id from OrderItem Where orderId = :order.id];
        oi.OrderDeliveryGroupId = orderDeliveryGroup.id;
        update oi;
        order.status = 'Activated';
        update order;




        List<fan_UpdateOrderItemSummary.updateItemRequest> requestList = new List<fan_UpdateOrderItemSummary.updateItemRequest>();
        fan_UpdateOrderItemSummary.updateItemRequest requestData = new fan_UpdateOrderItemSummary.updateItemRequest();
        requestList.add(requestData);
        requestData.orderId = order.id;
        requestData.orderSummaryId = TestDataGenerator.createOrderSummary(order.Id);
        
        fan_UpdateOrderItemSummary.updateItemSummary(requestList);
    }

}