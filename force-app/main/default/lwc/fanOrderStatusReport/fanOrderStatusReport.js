import { LightningElement, api, track } from 'lwc';
import { foStatusLabels } from 'c/fanLabels';
import { NavigationMixin } from 'lightning/navigation';
import getStatusF0s from '@salesforce/apex/fan_OrderStatusCtrl.getStatusF0s';

export default class FanOrderStatusReport extends NavigationMixin(LightningElement) {

  @api effectiveAccountId;
  @api orderSummaryId;
  @track ordersData = [];

  // Private variables
  _sortBy = 'FulfillmentOrderNumber';
  _sortAsc = true;
  _filterBy = '';
  _filterFor = '';
  _loading;

  connectedCallback() {
    this._loading = true;
    this.getOrdersReport();
  }

  getOrdersReport() {
    getStatusF0s({ 
      effectiveAccountId: this.effectiveAccountId,
      orderSummaryId: this.orderSummaryId
    }).then(result => {
      this.ordersData = result;
    }).catch(error => {
      console.log('Error in getOrdersReport --> ', error.body);
    }).finally(() => this._loading = false);
  }

  handleSort(event) {
    let selectedSortBy = event.target.title;
    let isNewSortBy = selectedSortBy != this._sortBy;

    this._sortAsc = isNewSortBy ? true : !this._sortAsc;
    this._sortBy = isNewSortBy ? selectedSortBy : this._sortBy;
  }

  // Filter data when user write on filter field
  handleFilter(event) {
    this._filterBy = event.target.dataset.property;
    this._filterFor = event.target.value;
    return this.filteredAccountStateData;
  }

  handleShowFoDetails(event) {
    console.log('eventDetails --> ',event.target.dataset.value)
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: event.target.dataset.value,
        actionName: 'view'
      }
  });
  }
  get currentSortBy() {
    return {
      sortByOrderNumber : this._sortBy != "FulfillmentOrderNumber",
      sortByOrderName : this._sortBy != "FulfilledToName",
      sortByTotal : this._sortBy != "TotalAmount",
      sortByStatus : this._sortBy != "Status",
      sortByGuideNumber : this._sortBy != "GuideNumber",
    };
  }

  get arrowDirection() {
    return this._sortAsc ? 'utility:arrowup' : 'utility:arrowdown';
  }

  get labels() {
    return foStatusLabels();
  }

  // Method to sort data asc/desc
  get sortedOrdersData() {
    const sortedTable = this.ordersData.sort((a, b) => {
      let order = a[this._sortBy] - b[this._sortBy];

      if (isNaN(order)) {
        if (a[this._sortBy] > b[this._sortBy]) {
          order = 1;
        } else if (a[this._sortBy] < b[this._sortBy]) {
          order = -1;
        } else {
          order = 0;
        }
      } else { 
        order = a[this._sortBy] - b[this._sortBy];
      }
      return order;
    });

    return this._sortAsc ? sortedTable : sortedTable.reverse();
  }

  get filteredAccountStateData() {
    if(!this._filterFor) {
      return this.sortedOrdersData;
    }
    try {
      return this.sortedOrdersData.filter((data) =>{
        const fieldValue = data[this._filterBy] + '';
        return new RegExp(this._filterFor, 'gi').test(fieldValue);
      });
    } catch(error) {
      return [];
    }
  }
}