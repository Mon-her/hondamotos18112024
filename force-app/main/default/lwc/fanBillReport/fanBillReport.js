import { api, LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { loadScript } from 'lightning/platformResourceLoader';

import { billReportLabels as getLabel } from "c/fanLabels";
import { buildMotosInvoiceData } from "./fanMotosInvoiceBuilder";
import { buildPosventaInvoiceData } from "./fanPosventaInvoiceBuilder";

import SHEETJS_STYLE_ZIP from '@salesforce/resourceUrl/fan_sheetjs_style';

import getAccountNumber from "@salesforce/apex/fan_B2BAccountCtrl.getAccountNumber";
import getInvoices from "@salesforce/apex/fan_BillReportController.getInvoices";
import getInvoiceItems from "@salesforce/apex/fan_ConsultaFacturasItemController.getInvoiceItems";

const XLSX_FILE_EXTENSION = 'xlsx';

// VADS_TRANS_STATUS field name.
const VADS_TRANS_STATUS = 'vads_trans_status';

export default class FanBillReport extends LightningElement {
  /**
   * Gets or sets the order type by which to order the table
   * @type {'boolean'}
   */
  @track
  sortAsc = true;

  /**
   * Gets or sets the field by which to order the table
   * @type {'string'}
   */
  @track
  sortBy;

  /**
   * Gets or sets the value by which to filter the table
   * @type {'boolean'}
   */
  @track
  filterFor;

  /**
   * Gets or sets the field by which to filter the table
   * @type {'string'}
   */
  @track
  filterBy;

  /**
   * Current account Id.
   * @type {'string'}
   */
  @api
  effectiveAccountId;

  data = [];

  idTercero;

  _isLoadingData = false;

  url = new URL(window.location.href);

  @wire(getAccountNumber, { accountId: "$effectiveAccountId"})
  async salesOrderItemSync({ error, data }) {
    this. _isLoadingData = true;
    if (data) {
      this.idTercero = data;
      this.data = await this.getInvoicesData(
        this.idTercero,
        this.getDate(1),
        this.getDate()
      );
    }
    this. _isLoadingData = false;

    if (error) {
      console.error(error.message || "ERROR", error);
    }
  }

  async getInvoicesData(idTercero, startDate, endDate) {
    try {
      const response = await getInvoices({
        idTercero: idTercero,
        startDate: startDate,
        endDate: endDate
      });
      return response;
    } catch (error) {
      console.error(error.message || "Error getting Invoices.", error);
      return [];
    }
  }

  getDate(monthsAgo = 0) {
    const today = new Date();
    if (monthsAgo) {
      today.setMonth(today.getMonth() - monthsAgo);
    }
    const DD = String(today.getDate()).padStart(2, "0");
    const MM = String(today.getMonth() + 1).padStart(2, "0"); //January is 0!
    const YYYY = today.getFullYear();

    return `${YYYY}-${MM}-${DD}`;
  }

  async handleSearch(event) {
    this._isLoadingData = true;
    this.data = await this.getInvoicesData(this.idTercero, event.detail.initDate, event.detail.endDate);
    this._isLoadingData = false;
  }

  get billInfoData() {
    return this.data;
  }

  get billInfoDataExpiration() {
    return (
      this.billInfoData.map((x) => ({
        ...x,
        expiredDays: 0,
        expiredBillValue: Math.floor(x.billValue * 1.2),
        paymentGreaterThanZero: x.netValue <= 0? false : true
      })) || {}
    );
  }

  get filteredBillInfoData() {
    if(!this.filterFor) {
      return this.billInfoDataExpiration;
    }
    try {
        return this.billInfoDataExpiration.filter((data) =>{
            const fieldValue = data[this.filterBy] + '';
            return new RegExp(this.filterFor, 'gi')
            .test(fieldValue);
        });
    } catch(error) {
        return [];
    }
  }

  get sortedBillInfoData() {
    const sortedTable = this.filteredBillInfoData.sort((a, b) => {
      let order = a[this.sortBy] - b[this.sortBy];
      // If the order by field is text
      if (isNaN(order)) {
        if (a[this.sortBy] > b[this.sortBy]) {
          order = 1;
        } else if (a[this.sortBy] < b[this.sortBy]) {
          order = -1;
        } else {
          order = 0;
        }
      }
      // If the order by field is number
      else {
        order = a[this.sortBy] - b[this.sortBy];
      }

      return order;
    });

    return this.sortAsc ? sortedTable : sortedTable.reverse();
  }

  //Gets the flag to control the visibility of download file button.
  get isSheetLibraryLoaded() {
    return window.XLSX;
  }

  connectedCallback() {
    this.loadSheetJS();

    if(this.url.searchParams.has(VADS_TRANS_STATUS) && this.url.searchParams.get(VADS_TRANS_STATUS) === 'CAPTURED')
      this.showSuccessPaymentMessage();
  }

  /**
   * Loads the SheetJS library to export files.
   */
  loadSheetJS() {
    loadScript(this, SHEETJS_STYLE_ZIP + '/xlsx.bundle.js')
    .catch((error) => {
      this.handleAlert(getLabel().libraryLoad, "error");
      console.log("Error in loadSheetJS --> ", error);
    });
  }

  /**
   * Handler for child component's custom event "sortTable"
   * Sorts the table with the column selected
   * @param {*} event
   */
  handleSortUpdate(event) {
    this.sortBy = event.detail.sort_by;
    this.sortAsc = event.detail.sort_asc;
  }

  /**
   * Handler for child component's custom event "filterTable"
   * Sorts the table with the column selected
   * @param {*} event
   */
  handleFilterUpdate(event) {
    this.filterBy = event.detail.filter_by;
    this.filterFor = event.detail.filter_for;
  }

  handleDownloadInvoice(event) {

    const documentIdentifier = event.detail;
    // Activate spinner
    this.data = this.updateDownloadAvailability(documentIdentifier, true);

    getInvoiceItems({ factura: documentIdentifier })
    .then((invoiceItems) => {
      if(invoiceItems.length) {
        this.exportToXLSX(documentIdentifier, invoiceItems);
      } else {
        this.handleAlert(getLabel().emptyInvoiceMessage, 'error');
        this.data = this.updateDownloadAvailability(documentIdentifier, false);
      }
    }).catch((error) => {
      this.data = this.updateDownloadAvailability(documentIdentifier, false);
      console.log('Error in getInvoiceItems --> ', error);
    });
  }

  buildWorkbook(sheetJS, invoiceData) {

    const worksheet = sheetJS.utils.aoa_to_sheet([
      invoiceData.header,
      ...invoiceData.items,
      ...Array(invoiceData.separators).fill([]), // Separator(s).
      ...invoiceData.totals
    ]);
    // Set height to header, items and separator(s) rows.
    if(invoiceData.rowHeight) {
      worksheet['!rows'] = Array(1 + invoiceData.items.length + invoiceData.separators).fill(invoiceData.rowHeight);
    }
    // Set width to columns.
    worksheet['!cols'] = invoiceData.columnWidth.map((length) => ({ wch: length }));

    const workbook = sheetJS.utils.book_new();
    sheetJS.utils.book_append_sheet(workbook, worksheet);
    return workbook;
  }

  buildInvoiceData(invoiceItems) {
    // Build data for Motos or else for Posventa.
    return invoiceItems.some((invoiceItem) => invoiceItem.chassis)
    ? buildMotosInvoiceData(invoiceItems)
    : buildPosventaInvoiceData(invoiceItems);
  }

  exportToXLSX(document, invoiceItems) {

    const sheetJS = window.XLSX;
    try {
      const invoiceData = this.buildInvoiceData(invoiceItems);
      const workbook = this.buildWorkbook(sheetJS, invoiceData);

      const fileName = `${getLabel().invoice} - ${document}.${XLSX_FILE_EXTENSION}`;

      sheetJS.writeFile(workbook, fileName);
    } catch (error) {
      this.handleAlert(error?.message, "error");
      console.log("Error in handleExportFile --> ", error);
    } finally {
      this.data = this.updateDownloadAvailability(document, false);
    }
  }

  handleAlert(title, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        variant
      })
    );
  }

  updateDownloadAvailability(documentIdentifier, available) {
    return this.billInfoData.map((billInfo) => ({
      ...billInfo,
      isAvailableToDownload: billInfo.billId === documentIdentifier ? available : billInfo.isAvailableToDownload
    }));
  }

  showSuccessPaymentMessage() {
    this.dispatchEvent(new ShowToastEvent({
        title: getLabel().successfulPayment,
        variant: 'success'
    }));
  }
}