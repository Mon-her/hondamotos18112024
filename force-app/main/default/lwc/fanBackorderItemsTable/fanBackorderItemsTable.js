import { LightningElement, track, api } from 'lwc';
import { backorderProductsLabels } from 'c/fanLabels';
import getBackorderItems from '@salesforce/apex/fan_BackorderItemsCtrl.getBackorderItems';

const COLUMNS = [
  { label: backorderProductsLabels().branchStore, fieldName: 'store', sortable: true},
  { label: backorderProductsLabels().backorderDateLabel, fieldName: 'orderedDate', type: 'date-local', typeAttributes: {month: '2-digit', day: '2-digit'}, sortable: true},
  { label: backorderProductsLabels().buyingOrderNumber, fieldName: 'orderNumber', sortable: true},
  { label: backorderProductsLabels().orderType, fieldName: 'orderType', sortable: true},
  { label: backorderProductsLabels().reference, fieldName: 'reference', sortable: true},
  { label: backorderProductsLabels().description, fieldName: 'name', sortable: true},
  { label: backorderProductsLabels().backorderQuantityLabel, fieldName: 'backorderQty', type: 'number', sortable: true},
  { label: backorderProductsLabels().backorderEstimationDate, fieldName: 'estimationDate', sortable: true},
];

export default class FanBackorderItemsTable extends LightningElement {
  @api storeName;
  @api effectiveAccountId;
  @track itemsData = [];
  @track filteredData = [];
  columnsData = [];
  isLoadingData = false;

  connectedCallback(){
    this.isLoadingData = true;
    this.columnsData = COLUMNS;
    getBackorderItems({ effectiveAccountId: this.effectiveAccountId, storeName: this.storeName})
    .then(items => {
      console.log('Items Response --> ',items);
      this.itemsData = items.map(item => ({
        id: item.Id,
        store: item.OrderDeliveryGroupSummary.DeliverToName,
        orderedDate: item.OrderSummary.OrderedDate,
        orderNumber: item.OrderSummary.OrderNumber,
        orderType: item.OrderSummary.OriginalOrder.fan_TipoPedido__c,
        reference: item.Product2.Referencia__c,
        name: item.Product2.Name,
        backorderQty: item.Quantity - (item.QuantityAllocated - item.QuantityCanceled),
        estimationDate: item.Product2.Fecha_Estimada__c
      }));
      this.filteredData = [...this.itemsData];
      this.isLoadingData = false;
      console.log('filteredData ->> ',this.filteredData);
    }).catch(error => {
      console.log('Error in getBackorderItems >>> ',error);
    })
  }

  handleSort(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;

    this.filteredData = [...this.itemsData].sort(this.sortImplementation(this.sortBy, this.sortDirection));
  }

  sortImplementation(fieldName, sortDirection) {
    const isReverse = sortDirection === 'asc' ? 1 : -1;
    return (a, b) => {
      a = a[fieldName] ?? '';
      b = b[fieldName] ?? '';
      return isReverse * ((a > b) - (b > a));
    };
  }

  updateSearch(event){
    let value = event.target.value;
    this.filteredData = [...this.itemsData].filter(item => {
      return (new RegExp(value, 'gi').test(item.store) || new RegExp(value, 'gi').test(item.orderNumber) || new RegExp(value, 'gi').test(item.reference))
    });
  }

  get labels(){
    return backorderProductsLabels();
  }

}