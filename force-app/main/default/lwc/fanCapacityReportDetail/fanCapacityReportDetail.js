import { LightningElement, api } from "lwc";
import { capacityReportDetailLabels } from "c/fanLabels";

/*
    fan_assignedCreditCapacity = Cupo de crédito asignado
    fan_availableCreditCapacity = Cupo crédito Disponible
    fan_advancedBalanceFavor = Anticipos Saldo a Favor
    fan_consignedValue = Valor a Consignar
    fan_expiredWallet = Cartera vencida
    fan_walletTotal = Total cartera
    fan_dispatchmentOrder = Pedidos para despacho
    fan_pendingPaymentOrder = Pedidos pendientes por pago
*/

export default class FanCapacityReportDisplay extends LightningElement {
  @api details;

  get quotaDetails() {
    return {
      assignedCreditCapacity: this.details.assignedCreditCapacity || 0,
      availableCreditCapacity: this.details.availableCreditCapacity || 0,
      advancedBalanceFavor: this.details.advancedBalanceFavor || 0,
      consignedValue: this.details.consignedValue || 0
    };
  }

  get storeCreditCapacities() {
    const { storeCreditCapacities } = this.details;

    if (!storeCreditCapacities) {
      return [
        {
          store: this.label.motorcycleStore,
          expiredWallet: 0,
          walletTotal: 0,
          dispatchmentOrder: 0,
          pendingPaymentOrders: 0
        },
        {
          store: this.label.aftermarketStore,
          expiredWallet: 0,
          walletTotal: 0,
          dispatchmentOrder: 0,
          pendingPaymentOrders: 0
        }
      ];
    }

    const { motorcycleStore, aftermarketStore } = storeCreditCapacities;

    return [
      {
        store: this.label.motorcycleStore,
        expiredWallet: motorcycleStore.expiredWallet,
        walletTotal: motorcycleStore.walletTotal,
        dispatchmentOrder: motorcycleStore.dispatchmentOrder,
        pendingPaymentOrders: motorcycleStore.pendingPaymentOrders
      },
      {
        store: this.label.aftermarketStore,
        expiredWallet: aftermarketStore.expiredWallet,
        walletTotal: aftermarketStore.walletTotal,
        dispatchmentOrder: aftermarketStore.dispatchmentOrder,
        pendingPaymentOrders: aftermarketStore.pendingPaymentOrders
      }
    ];
  }

  get label() {
    return capacityReportDetailLabels();
  }
}