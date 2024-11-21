public class fan_Constants {
    public enum ContactPointAddressType { BILLING, SHIPPING }

    public enum StoreDeveloperName { MOTOS, POSVENTA }
	public enum OrderType { RMT_NORMAL, RMT_GARANTIA, EMM_EMERGENCIA }
    public enum FormaPago { CONTADO, CREDITO }
    public enum CartItemType { PRODUCT, CHARGE }
    public enum AdjustmentType { ADJUSTMENT_AMOUNT, ADJUSTMENT_PERCENTAGE }
    public enum AdjustmentSource { PROMOTION, DISCRETIONARY }

    public enum LoadConfiguration { CLIENTS }

    public enum OCIInteractionOrderSummaryStatus { COMPLETED_SUCCEED, REQUESTED }
    public enum OCIInteractionOrderSummaryType { CREATE_RESERVATION, RELEASE, TRANSFER_ROUTING }

    public enum OrderSummaryStatus { ACTIVADO, APROBADO, CANCELADO, LOCKED, PENDING, WAITING_FOR_PAYMENT }
    public enum OrderSummaryScheduleStatus { ABANDONED, SCHEDULE, COMPLETED }

    public enum OrderItemSummaryType { DELIVERY_CHARGE, ORDER_PRODUCT }
    public enum OrderItemSummaryTypeCode { PRODUCT, CHARGE }

    public enum ProcessExceptionCategory { FULFILLMENT }
    public enum ProcessExceptionPriority { HIGH }
    public enum ProcessExceptionSeverity { HIGH }

    public enum MotorcycleClassifaction { CKD, CBU }
    public enum OperationCenter { HRC, HMC, HOC } // (HRC) -> Posventa, (HMC, HOC) -> Motos

    public enum UserType { GUEST }

    public fan_Constants() {}
}