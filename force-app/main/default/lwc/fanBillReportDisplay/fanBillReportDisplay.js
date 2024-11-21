import { LightningElement, api } from "lwc";
import { billReportLabels } from "c/fanLabels";

export default class FanBillReportDisplay extends LightningElement {
  @api
  billInfoData;

  @api
  isSheetLibraryLoaded;

  @api
  idTercero;

  billsToPay = {
    billId: [],
    operationCenter: [],
    documentType: [],
    documentNumber: []
  };

  amountToPay = 0;
  creditToPay = null;
  optionToPay = "total";

  hasBillSelected = false;

  sortBy;

  sortAsc;

  filterBy;

  filterFor;

  initDate = "";
  endDate = "";
  filterData = [];

  displayPaymentMethodModal = false;

  connectedCallback() {
    this.filterData = JSON.parse(JSON.stringify(this.billInfoData));
  }

  get label() {
    return billReportLabels();
  }

  get currentSortBy() {
    return {
      sortByBillId: this.sortBy !== "billId",
      sortByBuyingOrderId: this.sortBy !== "buyingOrderId",
      sortByBillDate: this.sortBy !== "billDate",
      sortByExpirationDate: this.sortBy !== "expirationDate",
      sortByBranchStore: this.sortBy !== "branchStore",
      sortByPaymentCondition: this.sortBy !== "paymentCondition",
      sortByOrderNumber: this.sortBy !== "orderNumber",
      sortByNetValue: this.sortBy !== "netValue"
    };
  }

  get arrowDirection() {
    return this.sortAsc ? "utility:arrowup" : "utility:arrowdown";
  }

  get isDownloadBtnDisabled() {
    return !this.isSheetLibraryLoaded;
  }

  /**
   * Handles the filter logic and fires a filterupdate event to the parent component
   * @param {*} event
   */
  onHandleFilter(event) {
    this.filterFor = event.target.value;
    this.filterBy = event.target.title;

    const filterupdate = new CustomEvent("filterupdate", {
      detail: {
        filter_by: this.filterBy,
        filter_for: this.filterFor
      }
    });

    this.dispatchEvent(filterupdate);
  }

  /**
   * Handles the sorting logic and fires a sortupdate event to the parent component
   * @param {*} event
   */
  onHandleSort(event) {
    let selectedSortBy = event.target.title;
    let isNewSortBy = selectedSortBy !== this.sortBy;

    this.sortAsc = isNewSortBy ? true : !this.sortAsc;
    this.sortBy = isNewSortBy ? selectedSortBy : this.sortBy;

    const sortupdate = new CustomEvent("sortupdate", {
      detail: {
        sort_by: this.sortBy,
        sort_asc: this.sortAsc
      }
    });

    this.dispatchEvent(sortupdate);
  }

  handleDownloadClick(event) {
    this.dispatchEvent(
      new CustomEvent("downloadinvoice", {
        detail: event.target.name // Bill id
      })
    );
  }

  // Individual payment button
  handlePaymentClick(event) {
    // Clears any selected bill
    this.resetBillsToPay();

    const billId = event.target.name;

    this.addBillsToPay(billId);

    this.displayPaymentMethodModal = true;
  }

  // Multiple bill payment button
  onHandlePaySelectedBills() {
    this.displayPaymentMethodModal = true;
  }

  onHandleSearch() {
    const event = new CustomEvent("search", {
      detail: {
        initDate: this.initDate,
        endDate: this.endDate
      }
    });
    console.log("event >> ", event);
    this.dispatchEvent(event);
  }

  onHandleClear() {
    this.initDate = "";
    this.endDate = "";
    this.billInfoData = this.filterData;
    this.resetBillsToPay();
  }

  handleInputInitDateChange(event) {
    this.initDate = event.detail.value;
  }

  handleInputEndDateChange(event) {
    this.endDate = event.detail.value;
  }

  handleClosePaymentMethodModal() {
    // If there is no bill selected (ergo is individual payment) then clear data
    if (!this.hasBillSelected) this.resetBillsToPay();

    this.displayPaymentMethodModal = false;
  }

  // Collects selected bills for multiple payment
  handleBillSelection(event) {
    const billId = event.target.value;

    if (event.target.checked) {
      this.addBillsToPay(billId);
      this.hasBillSelected = true;
    } else {
      this.RemoveBillsToPay(billId);
    }
  }

  addBillsToPay(billId) {
    const billDocumentCodeSplit = billId.split("-");

    const billData = this.billInfoData.find((bill) => bill.billId === billId);

    this.billsToPay.billId.push(billData.billId);
    this.billsToPay.operationCenter.push(billData.operationCenter);
    this.billsToPay.documentType.push(billDocumentCodeSplit[0]);
    this.billsToPay.documentNumber.push(billDocumentCodeSplit[1]);
    //Format amount to be accepted by Payzen Service
    this.amountToPay +=
      billData.netValue.includes(".") == true
        ? Number(billData.netValue.replace(".", ""))
        : Number(billData.netValue.concat("", "00"));
  }

  RemoveBillsToPay(billId) {
    const billData = this.billInfoData.find((bill) => bill.billId === billId);
    const billIndex = this.billsToPay.billId.findIndex(
      (bill) => bill === billId
    );

    this.billsToPay.billId.splice(billIndex, 1);
    this.billsToPay.operationCenter.splice(billIndex, 1);
    this.billsToPay.documentType.splice(billIndex, 1);
    this.billsToPay.documentNumber.splice(billIndex, 1);

    this.amountToPay -=
      billData.netValue.includes(".") == true
        ? Number(billData.netValue.replace(".", ""))
        : Number(billData.netValue.concat("", "00"));

    if (this.billsToPay.billId.length === 0) this.hasBillSelected = false;
  }

  resetBillsToPay() {
    const checkboxList = this.template.querySelectorAll(
      `input[data-name="billToPay"]`
    );

    checkboxList.forEach((checkbox) => {
      checkbox.checked = false;
    });

    this.billsToPay.billId = [];
    this.billsToPay.operationCenter = [];
    this.billsToPay.documentType = [];
    this.billsToPay.documentNumber = [];

    this.amountToPay = 0;

    this.hasBillSelected = false;
  }

  get billDataDetail() {
    return {
      operationCenter: this.billsToPay.operationCenter.join(";"),
      documentType: this.billsToPay.documentType.join(";"),
      documentNumber: this.billsToPay.documentNumber.join(";"),
      amountToPay: this.amountToSend
    };
  }

  get amountToSend() {
    let amountToPay = 0;
    if (this.optionToPay === "total") {
      amountToPay = this.amountToPay;
    }

    if (this.optionToPay === "credit" && this.creditToPay) {
      if (this.creditToPay.toString().includes(".")) {
        amountToPay = Number(this.creditToPay.toString().replace(".", ""));
      } else {
        amountToPay = Number(this.creditToPay.toString().concat("", "00"));
      }
    }

    return amountToPay;
  }

  get amountToPayLabel() {
    return this.label.totalAmountToPay.replace(
      "{0}",
      " " +
        new Intl.NumberFormat("es-CO", {
          style: "currency",
          currency: "COP"
        }).format(this.maxAmountToPay)
    );
  }

  get isTotalSelected() {
    return this.optionToPay === "total";
  }

  get isCreditSelected() {
    return this.optionToPay === "credit";
  }

  get maxAmountToPay() {
    const amount = Number(
      this.amountToPay.toString().slice(0, -2) +
        "." +
        this.amountToPay.toString().slice(-2)
    );
    return amount;
  }

  get isNotValidToPay() {
    return (
      this.optionToPay === "credit" &&
      (this.creditToPay === null ||
        this.creditToPay === 0 ||
        this.creditToPay > this.maxAmountToPay)
    );
  }

  handleClickOptionToPay(event) {
    this.optionToPay = event.target.value;
    if (this.optionToPay === "total") {
      this.creditToPay = null;
    }
  }

  handleChangeCreditToPay(event) {
    this.creditToPay = Number(event.target.value);
  }
}