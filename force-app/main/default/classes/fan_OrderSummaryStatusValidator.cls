public with sharing class fan_OrderSummaryStatusValidator implements Database.batchable<AccountOrder>, Database.AllowsCallouts, Schedulable {

	@TestVisible
	static OrderSummary[] testOrderSummaries;

	public Iterable<AccountOrder> start(Database.BatchableContext bc){

		Map<String, AccountOrder> accountOrders = new Map<String, AccountOrder>();

		OrderSummary[] orderSummaries = [SELECT Status, GrandTotalAmount, fan_TipoPedido__c, Total_Valor_Pendiente_Impuestos__c, Account.AccountNumber, Account.Parent.AccountNumber,
												(SELECT Id FROM OrderItemSummaries WHERE TypeCode =: fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name() AND QuantityAvailableToFulfill > 0)
											FROM OrderSummary
											WHERE (OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OriginalOrder.fan_EsAnticipo__c = true)
											AND Status IN (:fan_Constants.OrderSummaryStatus.APROBADO.name(), :fan_Constants.OrderSummaryStatus.LOCKED.name(), :fan_Constants.OrderSummaryStatus.PENDING.name())
											AND fan_ScheduleStatus__c = :fan_Constants.OrderSummaryScheduleStatus.COMPLETED.name()
											AND Id IN (SELECT OrderSummaryId FROM OrderItemSummary WHERE fan_IsBackorder__c = true)
											ORDER BY CreatedDate];

		for(OrderSummary orderSummary : Test.isRunningTest() ? testOrderSummaries : orderSummaries) {

			String accountNumberResolved = fan_B2BUtils.resolveAccountNumber(orderSummary.Account);
			AccountOrder accountOrder = accountOrders.get(accountNumberResolved) ?? new AccountOrder();

			accountOrder.accountNumberResolved = accountNumberResolved;
			accountOrder.orderSummaries.add(orderSummary);
			accountOrders.put(accountNumberResolved, accountOrder);
		}
		return accountOrders.values();
	}

	public void execute(Database.BatchableContext bc, AccountOrder[] accountOrders){

		OrderSummary[] orderSummariesToUpdate = new List<OrderSummary>();

		for(AccountOrder accountOrder : accountOrders) {

			String accountNumberResolved = accountOrder.accountNumberResolved;
			fan_CuentasExcepcionCupo__mdt accountException = fan_CuentasExcepcionCupo__mdt.getInstance('X' + accountOrder.accountNumberResolved);
			fan_ConsultaCupo.row_element[] quotaResponse = fan_ConsultaCupoHandler.getData(accountOrder.accountNumberResolved);

			OrderSummary[] orderSummaries = resolveOrderSummariesStatus(accountException, quotaResponse, accountOrder.orderSummaries);
			orderSummariesToUpdate.addAll(orderSummaries);
		}

		if(!Test.isRunningTest()) UPDATE orderSummariesToUpdate;
	}

	public void finish(Database.BatchableContext bc){}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new fan_OrderSummaryStatusValidator(), 1);
	}

	OrderSummary[] resolveOrderSummariesStatus(fan_CuentasExcepcionCupo__mdt accountException, fan_ConsultaCupo.row_element[] quotaResponse, OrderSummary[] orderSummaries) {

		for(OrderSummary orderSummary : orderSummaries) {
			String status;

			if(orderSummary.OrderItemSummaries.isEmpty()) {
				if(orderSummary.GrandTotalAmount == 0) {
					status =  fan_Constants.OrderSummaryStatus.CANCELADO.name() ;
				} else if(orderSummary.GrandTotalAmount > 0) {
					status = fan_Constants.OrderSummaryStatus.ACTIVADO.name();
				}
			} else {
				fan_ConsultaCupoHandler.Order order = new fan_ConsultaCupoHandler.Order(orderSummary);
				status = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(accountException, quotaResponse, order);
			}
			orderSummary.Status = status;
		}
		return orderSummaries;
	}

	class AccountOrder {
		String accountNumberResolved;
		OrderSummary[] orderSummaries;

		AccountOrder() {
			this.orderSummaries = new List<OrderSummary>();
		}
	}
}