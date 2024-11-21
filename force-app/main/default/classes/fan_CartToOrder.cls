public with sharing class fan_CartToOrder {

    public class CartToOrderRequest {
        
        @InvocableVariable(required=true)
        public ID checkoutSessionId;
        
        @InvocableVariable(required=true)
        public ID cartId;
    }
    
    /** Maps a cart to an order. Activates it, and closes the cart. Returns the resulting order summary id.
     * @param request The checkout session and cart id.
     * @return The OrderId that resulted from this class.
     */
    @InvocableMethod(label='Method to map Cart to Order' description='Maps the cart and related data to an order' category='B2B Commerce')
    public static void cartToOrder(List<CartToOrderRequest> request) {
        // screen flows do not run in bulk
        Id cartId = request[0].cartId;
        Id checkoutSessionId = request[0].checkoutSessionId;
        
        // load the primary delivery group (only one supported at this time)
        List<CartDeliveryGroup> cartDeliveryGroups = [SELECT Id, Name, DesiredDeliveryDate, DeliverToName, ShippingInstructions, DeliverToStreet, DeliverToCity,                    
                                                      DeliverToState, DeliverToPostalCode, DeliverToCountry, DeliverToLatitude, DeliverToLongitude,                    
                                                      DeliveryMethodId, fan_CPACode__c,
                                                      Cart.AccountId FROM CartDeliveryGroup WHERE CartId = :cartId];
        System.debug(LoggingLevel.DEBUG, 'cartDeliveryGroups >>> '+cartDeliveryGroups);
        Id orderId = mapAndInsertCartToOrder(cartId);
       
        Map<String,OrderDeliveryGroup> deliveryGroupsIds = mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(cartDeliveryGroups, orderId);

        mapAndInsertCartItems(cartId, deliveryGroupsIds, orderId);

        List<ID> orderIds = new List<ID>();
        orderIds.add(orderId);
        updateCheckoutSession(checkoutSessionId, orderId);
    }
    
    private static void updateCheckoutSession(Id checkoutSessionId, Id orderId) {
        try {
            CartCheckoutSession checkoutSession = [SELECT OrderId,WebCart.fan_EsAnticipo__c FROM CartCheckoutSession WHERE Id = :checkoutSessionId LIMIT 1];
            checkoutSession.OrderId = orderId;
            UPDATE checkoutSession;
            if(checkoutSession.WebCart.fan_EsAnticipo__c == true){
                fan_B2BPaymentController.registerAnticipoPayment(checkoutSession.WebCart.Id);
            }
        } catch (Exception e) {
            System.debug('An error occurred updating checkout session with the draft order Id');
        }
    }
    
    private static Id mapAndInsertCartToOrder(Id cartId) {
        // Get the cart data needed to populate the order
        List<WebCart> carts = [SELECT Id, AccountId, OwnerId, WebStoreId, PoNumber, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                               BillingCountry, BillingLatitude, BillingLongitude,fan_TipoPedido__c, fan_EsAnticipo__c  FROM WebCart WHERE Id = :cartId];
        WebCart cart = carts[0];          

        // Create the order
        Date today = Date.today(); 
        Datetime now = Datetime.now();   
        Order order = new Order(
            AccountId = cart.AccountId,
            OwnerId = cart.OwnerId,
            SalesStoreId = cart.WebStoreId,
            PoNumber = cart.PoNumber,
            BillingStreet = cart.BillingStreet,
            BillingCity = cart.BillingCity,
            BillingState = cart.BillingState,
            BillingPostalCode = cart.BillingPostalCode,
            BillingCountry = cart.BillingCountry,
            BillingLatitude = cart.BillingLatitude,
            BillingLongitude = cart.BillingLongitude,
            EffectiveDate = today,
            OrderedDate = now,
            fan_TipoPedido__c = cart.fan_TipoPedido__c,
            Status = 'Draft',
            fan_EsAnticipo__c = cart.fan_EsAnticipo__c
        );
        INSERT order;
        return order.Id;
    }
    
    private static Map<String,OrderDeliveryGroup> mapAndInsertCartDeliveryGroupToOrderDeliveryGroup(List<CartDeliveryGroup> cartDeliveryGroups, Id orderId) {
        // Save CartDeliveryGroupId with their matching OrderDeliveryGroup
        Map<String,OrderDeliveryGroup> orderDeliveryGroupId = new Map<String,OrderDeliveryGroup>();
        //Save Accounts Names and Ids
        Map<String,Id> mapAccounts = new Map<String,Id>();

        //Get the accounts Ids
        for(Account cuenta : [SELECT Name FROM Account WHERE Parent.Id =: cartDeliveryGroups[0].Cart.AccountId]){
            mapAccounts.put(cuenta.Name, cuenta.Id);
        }

        // Create the order delivery group
        for (CartDeliveryGroup cartDeliveryGroup : cartDeliveryGroups) {
            Date desiredDeliveryDate = toDate(cartDeliveryGroup.DesiredDeliveryDate);
            OrderDeliveryGroup orderDeliveryGroup = new OrderDeliveryGroup(
                DesiredDeliveryDate = desiredDeliveryDate,
                DeliverToName = cartDeliveryGroup.DeliverToName,
                DeliveryInstructions = cartDeliveryGroup.ShippingInstructions,
                DeliverToStreet = cartDeliveryGroup.DeliverToStreet,
                DeliverToCity = cartDeliveryGroup.DeliverToCity,
                DeliverToState = cartDeliveryGroup.DeliverToState,
                DeliverToPostalCode = cartDeliveryGroup.DeliverToPostalCode,
                DeliverToCountry = cartDeliveryGroup.DeliverToCountry,
                DeliverToLatitude = cartDeliveryGroup.DeliverToLatitude,
                DeliverToLongitude = cartDeliveryGroup.DeliverToLongitude,
                OrderDeliveryMethodId = cartDeliveryGroup.DeliveryMethodId,
                fan_Code__c = cartDeliveryGroup.fan_CPACode__c,
                OrderId = orderId,
                fan_Cuenta__c = mapAccounts.get(cartDeliveryGroup.DeliverToName)
            );
            orderDeliveryGroupId.put(cartDeliveryGroup.Id, orderDeliveryGroup);
        }

        INSERT orderDeliveryGroupId.values();

        System.debug(LoggingLevel.DEBUG, 'Created orderDeliveryGroupId >>> '+orderDeliveryGroupId);

        return orderDeliveryGroupId;
    }
    
    private static void mapAndInsertCartItems(String cartId, Map<String,OrderDeliveryGroup> deliveryGroupsIds, Id orderId) {
        // Get the cart items needed to populate the order items and adjustments
        List<CartItem> cartItems = [SELECT Product2Id, Type, Quantity, fan_QuantityOrdered__c, ListPrice, CartDeliveryGroupId, fan_PaymentCondition__c,
                                    TotalTaxAmount, fan_IsBackorder__c,fan_OrderSegmentationGroup__c FROM CartItem WHERE CartDeliveryGroupId IN :deliveryGroupsIds.keySet()
                                    AND (Type = :fan_Constants.CartItemType.CHARGE.name() OR (fan_QuantityOrdered__c > 0 AND ListPrice > 0))];
        System.debug(LoggingLevel.DEBUG, 'cartItems >>> '+cartItems);

        Map<Id, OrderItem> cartItemOrder = new Map<Id, OrderItem>();

        // For each item, map it to an order, then add adjustments
        for (CartItem cartItem : cartItems) {
            String orderDeliveryGroupId = deliveryGroupsIds.get(cartItem.CartDeliveryGroupId).Id;
            OrderItem orderItemToAdd = mapCartItemToOrderItem(cartItem, orderId, orderDeliveryGroupId);
            cartItemOrder.put(cartItem.Id, orderItemToAdd);
        }

        System.debug(LoggingLevel.DEBUG, 'cartItemOrder map >>> '+cartItemOrder);
        INSERT cartItemOrder.values();

        // Create the adjustments for cart y order, and taxes
        createAdjustments(orderId, cartItemOrder);
        createTaxes(cartItemOrder);
    }
    
    private static OrderItem mapCartItemToOrderItem(CartItem cartItem, Id orderId, Id orderDeliveryGroupId) {
        String orderItemType = getOrderItemType(cartItem.Type);
        Decimal quantity = cartItem.Type == fan_Constants.CartItemType.PRODUCT.name() ? cartItem.fan_QuantityOrdered__c : cartItem.Quantity;

        OrderItem orderItem = new OrderItem(
            Product2Id = cartItem.Product2Id,
            Type = orderItemType,
            Quantity = quantity,
            ListPrice = cartItem.ListPrice.setScale(2, System.RoundingMode.HALF_UP),
            UnitPrice = cartItem.ListPrice.setScale(2, System.RoundingMode.HALF_UP),
            OrderId = orderId,
            fan_OrderSegmentationGroup__c = cartItem.fan_OrderSegmentationGroup__c,
            OrderDeliveryGroupId = orderDeliveryGroupId,
            TotalLineAmount = (cartItem.ListPrice * quantity).setScale(2, System.RoundingMode.HALF_UP),
            fan_IsBackorder__c = cartItem.fan_IsBackorder__c,
            fan_PaymentCondition__c = cartItem.fan_PaymentCondition__c
        );
        
        return orderItem;
    }
    
    private static String getOrderItemType(String cartItemType) {
        if (cartItemType == 'Product')  return 'Order Product';
        if (cartItemType == 'Charge')  return 'Delivery Charge';
        
        return null;
    }
    
    private static Date toDate(DateTime dt) {
        return dt != null ?  Date.newinstance(dt.year(), dt.month(), dt.day()) : null;
    }

    private static void createAdjustments(String orderId, Map<Id,OrderItem> cartItemOrder){
        // Get items adjustments data
        List<CartItemPriceAdjustment> cartItemsAdjustments = [SELECT Name, Description, CartItemId, PriceAdjustmentCauseId, AdjustmentValue , AdjustmentSource, AdjustmentType
                                                              FROM CartItemPriceAdjustment WHERE CartItemId IN :cartItemOrder.keySet()];
        System.debug(LoggingLevel.DEBUG, 'cartItemsAdjustments >>> '+cartItemsAdjustments);

        // Objects to insert
        Map<Id,OrderItemAdjustmentLineItem> orderItemsAdjustmentsToInsert = new Map<Id,OrderItemAdjustmentLineItem>();
        Map<String, OrderAdjustmentGroup> orderAdjustmentGroups = createOrderAdjustmentGroups(orderId, cartItemsAdjustments);

        for (CartItemPriceAdjustment cartItemPriceAdjustment : cartItemsAdjustments) {
            String orderAdjustmentGroupId = orderAdjustmentGroups.get(cartItemPriceAdjustment.PriceAdjustmentCauseId).Id;
            OrderItem orderItem = cartItemOrder.get(cartItemPriceAdjustment.CartItemId);
            if (!orderItemsAdjustmentsToInsert.containsKey(orderItem.Id)) {
                orderItemsAdjustmentsToInsert.put(orderItem.Id,buildOrderItemAdjustment(orderAdjustmentGroupId, cartItemPriceAdjustment, orderItem));
            }
        }
        System.debug(LoggingLevel.DEBUG, 'orderItemsAdjustmentsToInsert >>> '+orderItemsAdjustmentsToInsert.values());
        INSERT orderItemsAdjustmentsToInsert.values();
    }

    static Map<String, OrderAdjustmentGroup> createOrderAdjustmentGroups(String orderId, CartItemPriceAdjustment[] cartItemPriceAdjustments) {
        Map<String, OrderAdjustmentGroup> orderAdjustmentGroups = new Map<String, OrderAdjustmentGroup>();

        for (CartItemPriceAdjustment cartItemPriceAdjustment : cartItemPriceAdjustments) {
            String priceAdjustmentCauseId = cartItemPriceAdjustment.PriceAdjustmentCauseId;
            orderAdjustmentGroups.put(priceAdjustmentCauseId, new OrderAdjustmentGroup(
                OrderId = orderId,
                // Picklist: Header, SplitLine
                Type = 'Header',
                Name = orderId,
                AdjustmentCauseId = priceAdjustmentCauseId,
                // Picklist: Discretionary, Promotion, System
                AdjustmentSource = cartItemPriceAdjustment.AdjustmentSource,
                // Picklist: AdjustmentAmount, AdjustmentPercentage
                AdjustmentType = cartItemPriceAdjustment.AdjustmentType
            ));
        }
        INSERT orderAdjustmentGroups.values();
        return orderAdjustmentGroups;
    }

    static OrderItemAdjustmentLineItem buildOrderItemAdjustment(String orderAdjustmentGroupId, CartItemPriceAdjustment cartItemPriceAdjustment, OrderItem orderItem) {
        Decimal adjustmentValue = cartItemPriceAdjustment.AdjustmentValue;

        return new OrderItemAdjustmentLineItem(
            Amount = -adjustmentValue * orderItem.Quantity,
            AdjustmentCauseId = cartItemPriceAdjustment.PriceAdjustmentCauseId,
            Description = cartItemPriceAdjustment.Description,
            Name = cartItemPriceAdjustment.Name,
            OrderItemId = orderItem.Id,
            OrderAdjustmentGroupId = orderAdjustmentGroupId
        );
    }

    static void createTaxes(Map<Id, OrderItem> orderItemsByCartItemId) {
        Date currentDate = Date.today();
        OrderItemTaxLineItem[] taxes = new List<OrderItemTaxLineItem>();

        for (CartTax cartTax : [SELECT Amount, CartItemId FROM CartTax WHERE CartItemId IN :orderItemsByCartItemId.keySet()]) {
            String cartItemId = cartTax.CartItemId;
            taxes.add(new OrderItemTaxLineItem(
                Amount = cartTax.Amount,
                Name = cartItemId,
                OrderItemId = orderItemsByCartItemId.get(cartItemId).Id, 
                Type = 'Actual',
                TaxEffectiveDate = currentDate
            ));
        }
        System.debug(LoggingLevel.DEBUG, 'taxes to add >>> ' + taxes);
        INSERT taxes;
    }
}