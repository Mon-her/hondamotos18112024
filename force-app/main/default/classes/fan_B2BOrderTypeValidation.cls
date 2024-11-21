public class fan_B2BOrderTypeValidation {

	@AuraEnabled
	public final String orderType { get; private set; }
	@AuraEnabled
	public final String paymentCondition { get; private set; }
	@AuraEnabled
	public final Boolean isPaymentConditionChangeable { get; private set; }
    // Used to notify that the order type changed due to a validation.
	@AuraEnabled
	public final Boolean applied { get; private set; }
	@AuraEnabled
	public final Boolean show { get; private set; }
	@AuraEnabled
	public final String title { get; private set; }
	@AuraEnabled
	public final String message { get; private set; }

    public fan_B2BOrderTypeValidation() {
        this.applied = false;
        this.show = false;
    }

    fan_B2BOrderTypeValidation(Builder builder) {
        this.orderType = builder.orderType;
        this.paymentCondition = builder.paymentCondition;
        this.title = builder.title;
        this.message = builder.message;
        this.applied = builder.applied;
        this.show = builder.show;
        this.isPaymentConditionChangeable = builder.isPaymentConditionChangeable;
    }

    public class Builder {
		String orderType;
        String paymentCondition;
        Boolean isPaymentConditionChangeable = true;
		String title;
		String message;
		Boolean applied;
		Boolean show;

        public Builder(String orderType) {
            this.orderType = orderType;
            this.applied = false;
            this.show = false;
        }

        public Builder setOrderType(String orderType) {
            this.orderType = orderType;
            return this;
        }

        public Builder setPaymentCondition(String value) {
            this.paymentCondition = value;
            return this;
        }

        public Builder setIsPaymentConditionChangeable(Boolean value) {
            this.isPaymentConditionChangeable = value;
            return this;
        }

        public Builder setTitle(String title) {
            this.title = title;
            return this;
        }

        public Builder setMessage(String message) {
            this.message = message;
            return this;
        }

        public Builder setShow(Boolean show) {
            this.show = show;
            return this;
        }

        public Builder setApplied(Boolean applied) {
            this.applied = applied;
            return this;
        }

        public fan_B2BOrderTypeValidation build() {
            return new fan_B2BOrderTypeValidation(this);
        }
    }
}