import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Labels.
import { capacityReportLabels as getLabel } from "c/fanLabels";

// To handle files.
import { loadSheetJS, exportToXLSX } from "c/fanFileManager";

import getAccountNumber from "@salesforce/apex/fan_B2BAccountCtrl.getAccountNumber";
import getQuotaDetails from "@salesforce/apex/fan_ConsultaCupoController.getQuotaDetails";
import getAccountState from "@salesforce/apex/fan_AccountStateController.getAccountState";

const CURRENCY_FORMAT = "[$$-es-CO] #,##0";

export default class FanCapacityReport extends LightningElement {
  details = [];
  accountStateData = [];
  invoicesTotals = {
    invoicesTotal: 0,
    expiredInvoicesTotal: 0
  }
  // Totals without taking into account negative values.
  formattedInvoicesTotals = {
    invoicesTotal: 0,
    expiredInvoicesTotal: 0
  }

  /** Current effective account Id.
   * @type {'string'} */
  @api
  effectiveAccountId;

  _isLoadingData = false;
  _invoicesData = [];

  connectedCallback() {
    this.loadSheetJS();
    this.loadServicesData();
  }

  async loadServicesData() {
    this._isLoadingData = true;

    try {
      let accountNumber = await getAccountNumber({
        accountId: this.effectiveAccountId
      });
  
      this.details = await this.getDetails(accountNumber);
      this.accountStateData = await this.getAccountState();
      this.setInvoicesTotals();
    } catch (error) {
      console.log('Error in loadServicesData --> ',error);
    } finally {
      this._isLoadingData = false;
    }
  }

  /** Gets quota details */
  async getDetails(nitCliente) {
    let response = [];
    try {
      response = await getQuotaDetails({
        nitCliente: nitCliente
      });
    } catch (error) {
      console.log('Error in getDetails --> ',error);
    } finally {
      return response;
    }
  }

  /** Get invoices details from account state service */
  async getAccountState() {
    let accountSummaryResponse = [];
    try {
      accountSummaryResponse = await getAccountState({
        accountId: this.effectiveAccountId
      });
      accountSummaryResponse = this.accountStateFormatData(accountSummaryResponse);
    } catch (error) {
      console.log('Error in getAccountState --> ', error)
    } finally {
      return accountSummaryResponse;
    }
  }

  /** Private properties. */
  _isExportFileDisabled = false;
  /** The SheetJS container. */
  _XLSX;

  /** Header for the spreadsheet. */
  get _worksheetHeader() {
    const label = getLabel();

    return [
      label.bill,
      label.expirationDate,
      label.orderTypeBillInfo,
      label.expiredDays,
      label.billValue,
      label.expiredBillValue
    ];
  }

  /** Gets or sets the order type by which to order the table
   * @type {'boolean'} */
  @track
  sortAsc = true;

  /** Gets or sets the field by which to order the table
   * @type {'string'} */
   @track
  sortBy;

  /** Gets or sets the value by which to filter the table
   * @type {'boolean'} */
  filterFor;

  /** Gets or sets the field by which to filter the table
   * @type {'string'} */
  filterBy;

  /** * Gets or sets the flag to control the visibility of export file button.
   * The value of this property is updated in response to user interactions with the export file button. */
  set isExportFileDisabled(value) {
    this._isExportFileDisabled = value;
  }

  get isExportFileDisabled() {
    return (
      !this._XLSX ||
      !this.sortedAccountStateData?.length ||
      this._isExportFileDisabled
    );
  }

  /** Configures which fields to export. */
  get _resolveDataToExport() {
    return this.sortedAccountStateData
    .map(({document, expirationDate, code, docuExpired, expiredInvoice, total}) => [
      document,
      expirationDate,
      code,
      docuExpired,
      { v: expiredInvoice ? 0 : total, t: "n", z: CURRENCY_FORMAT },
      { v: expiredInvoice ? total : 0, t: "n", z: CURRENCY_FORMAT }
    ]);
  }

  /** Sort the invoices data. */
  get sortedAccountStateData() {
    const sortedTable = this.accountStateData.sort((a, b) => {
      let order = a[this.sortBy] - b[this.sortBy];
      if (isNaN(order)) {
        if (a[this.sortBy] > b[this.sortBy]) {
          order = 1;
        } else if (a[this.sortBy] < b[this.sortBy]) {
          order = -1;
        } else {
          order = 0;
        }
      }
      return order;
    });

    return this.sortAsc ? sortedTable : sortedTable.reverse();
  }

  /** Filters the invoices data. */
  get filteredAccountStateData() {
    if (!this.filterFor) {
      return this.sortedAccountStateData;
    }
    try {
      return this.sortedAccountStateData.filter((data) => {
        const fieldValue = data[this.filterBy] + '';
        return new RegExp(this.filterFor, 'gi')
          .test(fieldValue);
      });
    } catch (error) {
      console.log('Error in filteredAccountStateData --> ', error);
      return [];
    }
  }

  /** Format information to the account state service data */
  accountStateFormatData(accountStateData) {
    let dataToReturn = accountStateData.map((x) => {
      let rowData = { ...x };
      rowData.expiredDaysTotal =
        Number(x.expiryAmountShort) +
        Number(x.expiryAmountMedium) +
        Number(x.expiryAmountLong) +
        Number(x.expiryAmountMax)
      rowData.expiredInvoice = (rowData.expiredDaysTotal > 0);
      rowData.total = Number(x.total);
      return rowData
    });
    return dataToReturn;
  }

  /** Sets the totals of expired invoices and current invoices */
  setInvoicesTotals() {
    this.accountStateData.forEach(({ expiredInvoice, total }) => {

      const field = expiredInvoice ? 'expiredInvoicesTotal' : 'invoicesTotal';
      this.invoicesTotals[field] += total;
      this.formattedInvoicesTotals[field] += Math.max(total, 0);
    });
  }

  /** Handler for child component's custom event "sortupdate". Sorts the table with the column selected
   * @param {*} event */
  handleSortUpdate(event) {
    this.sortBy = event.detail.sort_by;
    this.sortAsc = event.detail.sort_asc;
  }

  /** Handler for child component's custom event "filterupdate". Filter the table with the column selected
   * @param {*} event */
  handleFilterUpdate(event) {
    this.filterBy = event.detail.filter_by;
    this.filterFor = event.detail.filter_for;
  }

  /** Loads the SheetJS library to export files. */
  loadSheetJS() {
    loadSheetJS(this)
      .then(() => {
        this._XLSX = window.XLSX;
      })
      .catch((error) => {
        console.log("Error in loadSheetJS --> ", error);

        this.dispatchEvent(
          new ShowToastEvent({
            title: getLabel().libraryLoad,
            message: error.message,
            variant: "error"
          })
        );
      });
  }

  /** Generates an XLSX file with the sorted account state data. */
  handleExportFile() {
    this.isExportFileDisabled = true;
    try {
      // Data for the last row in the table
      const totalRow = [
        getLabel().total,
        null,
        null,
        null,
        ...Object.values(this.invoicesTotals)
        .map((total) => ({ v: total, t: "n", z: CURRENCY_FORMAT }))
      ];

      exportToXLSX(
        this._XLSX,
        this._worksheetHeader,
        this._resolveDataToExport,
        getLabel().exportCapacityLabel,
        totalRow
      );
    } catch (error) {
      console.log("Error in handleExportFile --> ", error);

      this.dispatchEvent(
        new ShowToastEvent({
          title: error.message,
          variant: "error"
        })
      );
    } finally {
      this.isExportFileDisabled = false;
    }
  }
}