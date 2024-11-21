import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAccountState from "@salesforce/apex/fan_AccountStateController.getAccountState";

// Labels.
import { accountStateLabels as getLabel } from "c/fanLabels";

// To handle files.
import { loadSheetJS, exportToXLSX } from "c/fanFileManager";

const CURRENCY_FORMAT = "[$$-es-CO] #,##0";

export default class FanEstadoCuenta extends LightningElement {

  /**
   * Gets Effective Account Id
   * @type {'string'}
   */
  @api
  effectiveAccountId;

  data = [];

  // Private variables
  _isLoadingData = false;

  async connectedCallback() {
    this.loadSheetJS();
    this._isLoadingData = true;
    this.data = await this.getSummaryAccountState(this.effectiveAccountId);
  }

  /**
   * Gets the report of the account state
   */
  async getSummaryAccountState(accountId) {
    try {
      const response = await getAccountState({
        accountId: accountId
      });

      return response;
    } catch (error) {
      console.error("ERROR - getting account state. --> ", error);
      return [];
    } finally {
      this._isLoadingData = false;
    }
  }

  // Private properties.
  _isExportFileDisabled = false;

  /**
   * The SheetJS container.
   */
  _XLSX;

  /**
   * Header for the spreadsheet.
   */
  get _worksheetHeader() {
    const label = getLabel();

    const expiryAmountLabels = [
      label.expiryAmountShort,
      label.expiryAmountMedium,
      label.expiryAmountLong,
      label.expiryAmountMax
    ];

    const mappedExpiryAmountLabels = expiryAmountLabels.map(
      (expiryAmountLabel) => `${label.expired} ${expiryAmountLabel}`
    );

    return [
      label.codeAccountState,
      label.description,
      label.currentAmount,
      ...mappedExpiryAmountLabels,
      label.total
    ];
  }

  /**
   * Dummy data to populate the table
   */
  get accountStateData() {
    const data = [];

    for (const [index, summa] of this.data.entries()) {
      data[index] = { id: index, ...summa };
    }

    return data;
  }

  /**
   * Gets or sets the field by which to order the table
   * @type {'string'}
   */
  @track
  sortBy;

  /**
   * Gets or sets the order type by which to order the table
   * @type {'boolean'}
   */
  @track
  sortAsc;

  /**
   * Gets or sets the value by which to filter the table.
   * @type {boolean}
   */
  filterFor;

  /**
   * Gets or sets the field by which to filter the table.
   * @type {string}
   */
  filterBy;

  /**
   * Gets or sets the flag to control the visibility of export file button.
   *
   * The value of this property is updated in response to user interactions with the export file button.
   */
  set isExportFileDisabled(value) {
    this._isExportFileDisabled = value;
  }

  get isExportFileDisabled() {
    return (
      !this._XLSX ||
      !(this.sortedAccountStateData || []).length ||
      this._isExportFileDisabled
    );
  }

  /**
   * Configures which fields to export.
   */
  get _resolveDataToExport() {
    return this.sortedAccountStateData
    .map(({document, aux, current, expiryAmountShort, expiryAmountMedium, expiryAmountLong, expiryAmountMax, total}) => [
      document,
      aux,
      { v: current, t: "n", z: CURRENCY_FORMAT },
      { v: expiryAmountShort, t: "n", z: CURRENCY_FORMAT },
      { v: expiryAmountMedium, t: "n", z: CURRENCY_FORMAT },
      { v: expiryAmountLong, t: "n", z: CURRENCY_FORMAT },
      { v: expiryAmountMax, t: "n", z: CURRENCY_FORMAT },
      { v: total, t: "n", z: CURRENCY_FORMAT }
    ]);
  }

  get accountStateDataTotal() {
    return (
      this.accountStateData.map((x) => ({
        ...x,
        totalExpirationDays:
          Number(x.current) +
          Number(x.expiryAmountShort) +
          Number(x.expiryAmountMedium) +
          Number(x.expiryAmountLong) +
          Number(x.expiryAmountMax)
      })) || {}
    );
  }

  get sortedAccountStateData() {
    const sortedTable = this.accountStateDataTotal.sort((a, b) => {
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

  /**
   * Filters the account state data.
   */
  get filteredAccountStateData() {
    if(!this.filterFor) {
        return this.sortedAccountStateData;
    }
    try {
        return this.sortedAccountStateData.filter((data) =>{
            const fieldValue = data[this.filterBy] + '';
            return new RegExp(this.filterFor, 'gi')
            .test(fieldValue);
        });
    } catch(error) {
        return [];
    }
  }

  /**
   * Sets the values of the footer of the table
   */

  get footTableData() {
    // This order of properties is important to export the file.
    let total = {
      netTotal: 0
    };

    this.filteredAccountStateData.forEach((item) => {
      total.netTotal = total.netTotal + Number(item.total);
    });

    return total;
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
   * Loads the SheetJS library to export files.
   */
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

  /**
   * Generates an XLSX file with the sorted account state data.
   */
  handleExportFile() {
    this.isExportFileDisabled = true;

    try {
      // Total row (The last row in the table).
      const totalRow = [
        getLabel().total,
        null,
        null,
        null,
        null,
        null,
        null,
        { v: this.footTableData.netTotal, t: "n", z: CURRENCY_FORMAT }
      ];

      exportToXLSX(
        this._XLSX,
        this._worksheetHeader,
        this._resolveDataToExport,
        getLabel().exportFileName,
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

  /**
   * Stores the data supplied by the event, which is used to filter the account state data.
   * @param {Object} event
   */
  handleApplyFilter(event) {
    const { filterBy, filterFor } = event.detail;

    this.filterBy = filterBy;
    this.filterFor = filterFor;
  }
}