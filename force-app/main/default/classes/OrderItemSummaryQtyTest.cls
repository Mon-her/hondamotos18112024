@isTest
public class OrderItemSummaryQtyTest {

    @isTest static void validateDataOrderItemSustituteQty(){
        OrderItemSustituteQty item = new OrderItemSustituteQty();
        item.OrderItemQty = 0;
        item.OrderItemQtyATF = 0;
        item.OrderItemSummary = null;
        item.OrderItemSummaryId = null;
        item.SKUSustituteQty = 0;
        item.SustituteId = null;
        item.SustituteName = null;
        item.SustituteSKU = null;
    }
    
    @isTest static void validateDataOrderItemSummaryQty(){
        OrderItemSummaryQty item = new OrderItemSummaryQty();
        item.OrderSummaryId = null;
        item.OrderItemQuantity = null;
        item.Quantity = null;
        item.QuantityToCancel = null;
        item.HasBackorder = null;
    }
}