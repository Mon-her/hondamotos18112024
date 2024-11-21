public without sharing abstract class fan_ShippingCalculator {

    public abstract Map<String, Decimal> calculateShipping(String accountId, String webStoreId, Set<String> productIds, Product[] products);

    protected Set<String> getBuyerGroupIds(String accountId, String webStoreId) {

        Set<String> buyerGroupIds = new Set<String>();

        for(BuyerGroupMember buyer : [SELECT BuyerGroupId FROM BuyerGroupMember WHERE BuyerId = :accountId AND BuyerGroupId IN
                                        (SELECT BuyerGroupId FROM WebStoreBuyerGroup WHERE WebStoreId = :webStoreId)]) {
            buyerGroupIds.add(buyer.BuyerGroupId);
        }
        return buyerGroupIds;
    }

    public class Product {
        public String id;
        public Decimal quantity;
        // Fields for Posventa .
        public Decimal totalAmount;
        public String segmentationGroup;
        public String paymentCondition;
        // Fields for Motos.
        public String deliveryGroupId;

        public Product() {}

        public Product(CartItem cartItem) {
            this.id = cartItem.Product2Id;
            this.segmentationGroup = cartItem.Product2.fan_OrderSegmentationGroup__c;
            this.paymentCondition = cartItem.fan_PaymentCondition__c;
            this.quantity = cartItem.fan_quantityAvailable__c;
            this.deliveryGroupId = cartItem.CartDeliveryGroupId;
            this.totalAmount = cartItem.UnitAdjustedPrice * quantity;
        }

        public Product(OrderItemSummary orderItemSummary) {
            this.id = orderItemSummary.Product2Id;
            this.segmentationGroup = orderItemSummary.fan_OrderSegmentationGroup__c;
            this.paymentCondition = orderItemSummary.OriginalOrderItem.fan_PaymentCondition__c;
            this.quantity = orderItemSummary.Quantity;
            this.deliveryGroupId = orderItemSummary.OrderDeliveryGroupSummaryId;
            this.totalAmount = orderItemSummary.AdjustedLineAmount;
        }

        public Product(FulFillmentOrderLineItem fulFillmentOrderLineItem) {
            this.id = fulFillmentOrderLineItem.Product2Id;
            this.segmentationGroup = fulFillmentOrderLineItem.OrderItemSummary.fan_OrderSegmentationGroup__c;
            this.paymentCondition = fulFillmentOrderLineItem.OrderItemSummary.fan_FormattedPaymentCondition__c;
            this.quantity = fulFillmentOrderLineItem.Quantity;
            this.deliveryGroupId = fulFillmentOrderLineItem.OrderItemSummary.OrderDeliveryGroupSummaryId;
            this.totalAmount = fulFillmentOrderLineItem.TotalPrice;
        }
    }
}