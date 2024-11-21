// File to get custom labels from Salesforce and use them in LWC

// General labels
import abbreviatedQuantity from '@salesforce/label/c.fan_abbreviatedQuantity';
import addToWishlist from '@salesforce/label/c.fan_addToWishlist'
import backorder from '@salesforce/label/c.fan_backorder';
import close from '@salesforce/label/c.fan_B2B_Close';
import color from '@salesforce/label/c.fan_color';
import createWishlist from '@salesforce/label/c.fan_createWishlist'
import cancel from '@salesforce/label/c.fan_cancel'
import dealerPrice from '@salesforce/label/c.fan_dealerPrice';
import discountedPrice from '@salesforce/label/c.fan_discountedPrice';
import invalidQuantity from '@salesforce/label/c.fan_invalidQuantity'
import save from '@salesforce/label/c.fan_save'
import results from '@salesforce/label/c.fan_results'
import success from '@salesforce/label/c.fan_success'
import error from '@salesforce/label/c.fan_error'
import quantity from '@salesforce/label/c.fan_quantity'
import publicPrice from '@salesforce/label/c.fan_publicPrice';
import sku from '@salesforce/label/c.fan_sku';
import sortBy from '@salesforce/label/c.fan_sortBy';
import updatingProductError from '@salesforce/label/c.fan_updatingProductError';
import searchFilter from '@salesforce/label/c.fan_B2B_searchFilter';
import filterHere from '@salesforce/label/c.fan_B2B_filterHere';
import download from '@salesforce/label/c.fan_B2B_download';
import shipping from '@salesforce/label/c.fan_Shipping';
import taxes from '@salesforce/label/c.fan_Taxes';
import deliveriesGenerated from '@salesforce/label/c.fan_DeliveriesGenerated';
import subtotal from '@salesforce/label/c.fan_Subtotal';
import creditCard from '@salesforce/label/c.fan_CreditCard'
import errorExportingFile from '@salesforce/label/c.fan_ErrorExportingFile';
import exportLabel from '@salesforce/label/c.fan_Export';
import inProgress from '@salesforce/label/c.fan_InProgress'
import readTimedOut from '@salesforce/label/c.fan_ReadTimedOutInformationalMessage';
import selectPlaceHolder from '@salesforce/label/c.fan_SelectPlaceHolder'
import filters from '@salesforce/label/c.fan_Filters'
import clearAll from '@salesforce/label/c.fan_ClearAll'
import category from '@salesforce/label/c.fan_Category'
import addToCartLabel from '@salesforce/label/c.fan_AddToCartLabel'
import unavailablePrice from '@salesforce/label/c.fan_UnavailablePrice'
import productHasnotPrice from '@salesforce/label/c.fan_ProductHasnotPrice'
import selectBranch from '@salesforce/label/c.fan_SelectBranch'

// Labels for CartUpload 
import processSelectedFile from '@salesforce/label/c.fan_B2B_Process_Selected_File';
import selectFiles from '@salesforce/label/c.fan_B2B_Select_Files';
import reset from '@salesforce/label/c.fan_B2B_Reset';
import filesSelected from '@salesforce/label/c.fan_B2B_Files_Selected';
import processingError from '@salesforce/label/c.fan_B2B_Upload_Processing_Error';
import pasteInputHere from '@salesforce/label/c.fan_B2B_Paste_your_input_here';
import processText from '@salesforce/label/c.fan_B2B_Process_pasted_text';
import selectInputType from '@salesforce/label/c.fan_B2B_Select_input_type';
import fileOption from '@salesforce/label/c.fan_fileOption';
import incorrectFileFormat from '@salesforce/label/c.fan_incorrectFileFormat';
import fileTypeNotSupported from '@salesforce/label/c.fan_fileTypeNotSupported';
import textArea from '@salesforce/label/c.fan_B2B_Text_area';
import showHelpDialog from '@salesforce/label/c.fan_B2B_Show_Help_Dialog';
import pleaseWait from '@salesforce/label/c.fan_B2B_Cart_Upload_please_wait';
import noTextFound from '@salesforce/label/c.fan_B2B_Text_area_no_text_found';
import fileIsEmpty from '@salesforce/label/c.fan_fileIsEmpty';
import processingOptions from '@salesforce/label/c.fan_B2B_Cart_Upload_Processing_options';
import maxUploadRowsExceeded from '@salesforce/label/c.fan_B2B_CU_Max_Upload_Rows_Exceeded';
import retrievingContent from '@salesforce/label/c.fan_B2B_Retrieving_Content';
import libraryLoad from '@salesforce/label/c.fan_libraryLoad';
import errorLoadingSheetJS from '@salesforce/label/c.fan_errorLoadingSheetJS';
import seachError from '@salesforce/label/c.fan_seachError';
import fileTooLong from '@salesforce/label/c.fan_fileTooLong';

// Labels for Product Details
import wishlistName from '@salesforce/label/c.fan_wishlistName'
import wishlistNameMissingValue from '@salesforce/label/c.fan_wishlistNameMissingValue'
import addToExistingWishlist from '@salesforce/label/c.fan_addToExistingWishlist'
import selectWishlist from '@salesforce/label/c.fan_selectWishlist'
import selectWishlistPlaceholder from '@salesforce/label/c.fan_selectWishlistPlaceholder'
import cartHasBeenUpdated from '@salesforce/label/c.fan_cartHasBeenUpdated'
import addToCartErrorPDP from '@salesforce/label/c.fan_addToCartErrorPDP'
import addToNewWishlistSucess from '@salesforce/label/c.fan_addToNewWishlistSuccess'
import addToNewWishlistError from '@salesforce/label/c.fan_addToNewWishlistError'
import addToWishlistSucess from '@salesforce/label/c.fan_addToWishlistSuccess'
import addToWishlistError from '@salesforce/label/c.fan_addToWishlistError'
import discountPerUnit from '@salesforce/label/c.fan_discountPerUnit'

// Labels for Cart Content
import addAllToWishlist from '@salesforce/label/c.fan_addAllToWishlist';
import addAllToWishlistSuccess from '@salesforce/label/c.fan_addAllToWishlistSuccess'
import cartHeader from '@salesforce/label/c.fan_cartHeader';
import clearCart from '@salesforce/label/c.fan_clearCart';
import createdDateAsc from '@salesforce/label/c.fan_createdDateAsc';
import createdDateDesc from '@salesforce/label/c.fan_createdDateDesc';
import defaultWishlistName from '@salesforce/label/c.fan_defaultWishlistName'
import emptyCartBody from '@salesforce/label/c.fan_emptyCartBody';
import emptyCartHeader from '@salesforce/label/c.fan_emptyCartHeader';
import loadingCartItems from '@salesforce/label/c.fan_loadingCartItems';
import nameAsc from '@salesforce/label/c.fan_nameAsc';
import nameDesc from '@salesforce/label/c.fan_nameDesc';
import selectAllWithBackorder from '@salesforce/label/c.fan_selectAllWithBackorder';
import unselectAllWithBackorder from '@salesforce/label/c.fan_unselectAllWithBackorder';
import contadoPaymentWarning from '@salesforce/label/c.fan_contadoPaymentWarning';
import anticipoPaymentWarning from '@salesforce/label/c.fan_anticipoPaymentWarning';

// Labels for Order Type
import orderType from '@salesforce/label/c.fan_orderType';
import codigoVIN from '@salesforce/label/c.fan_numVIN';
import paymentOption from '@salesforce/label/c.fan_paymentOption';
import ineligibleOrderType from '@salesforce/label/c.fan_ineligibleOrderType'; 

// Labels for Account State
import expired from '@salesforce/label/c.fan_B2B_expired';
import codeAccountState from '@salesforce/label/c.fan_B2B_codeAccountState';
import expiryAmountShort from '@salesforce/label/c.fan_B2B_expiryAmountShort';
import expiryAmountMedium from '@salesforce/label/c.fan_B2B_expiryAmountMedium';
import expiryAmountLong from '@salesforce/label/c.fan_B2B_expiryAmountLong';
import expiryAmountMax from '@salesforce/label/c.fan_B2B_expiryAmountMax';
import description from '@salesforce/label/c.fan_description';
import total from '@salesforce/label/c.fan_B2B_total';
import credit from '@salesforce/label/c.fan_B2B_credit';
import creditToPay from '@salesforce/label/c.fan_B2B_credit_to_pay';
import selectPayOption from '@salesforce/label/c.fan_B2B_select_pay_option';
import currentAmount from '@salesforce/label/c.fan_B2B_currentAmount';
import checkAccountState from '@salesforce/label/c.fan_CheckAccountState';
import exportFileName from '@salesforce/label/c.fan_ExportFileName';

// Labels for Capacity Report Detail
import assignedCreditCapacity from '@salesforce/label/c.fan_B2B_assignedCreditCapacity';
import availableCreditCapacity from '@salesforce/label/c.fan_B2B_availableCreditCapacity';
import advancedBalanceFavor from '@salesforce/label/c.fan_B2B_advancedBalanceFavor';
import consignedValue from '@salesforce/label/c.fan_B2B_consignedValue';
import expiredWallet from '@salesforce/label/c.fan_B2B_expiredWallet';
import dispatchmentOrder from '@salesforce/label/c.fan_B2B_dispatchmentOrder';
import pendingPaymentOrders from '@salesforce/label/c.fan_B2B_pendingPaymentOrders';
import walletTotal from '@salesforce/label/c.fan_B2B_walletTotal';
import creditCapacityDetail from '@salesforce/label/c.fan_B2B_creditCapacityDetail';
import motorcycleStore from '@salesforce/label/c.fan_B2B_motorcycleStore';
import aftermarketStore from '@salesforce/label/c.fan_B2B_aftermarketStore';
import quotaReport from '@salesforce/label/c.fan_QuotaReport';
import exportCapacityLabel from '@salesforce/label/c.fan_exportCapacityLabel';

// Labels for Capacity Report Bill Info
import bills from '@salesforce/label/c.fan_B2B_bills';
import totalAmountBills from '@salesforce/label/c.fan_B2B_totalAmountBills';
import totalAmountExpiredBills from '@salesforce/label/c.fan_B2B_totalAmountExpiredBills';
import bill from '@salesforce/label/c.fan_B2B_bill';
import expirationDate from '@salesforce/label/c.fan_B2B_expirationDate';
import orderTypeBillInfo from '@salesforce/label/c.fan_B2B_orderTypeBillInfo';
import expiredDays from '@salesforce/label/c.fan_B2B_expiredDays';
import billValue from '@salesforce/label/c.fan_B2B_billValue';
import expiredBillValue from '@salesforce/label/c.fan_B2B_expiredBillValue';

// Labels for Bill Report
import billNumber from '@salesforce/label/c.fan_B2B_billNumber';
import buyingOrderNumber from '@salesforce/label/c.fan_B2B_buyingOrderNumber';
import billDate from '@salesforce/label/c.fan_B2B_billDate';
import branchStore from '@salesforce/label/c.fan_B2B_branchStore';
import paymentCondition from '@salesforce/label/c.fan_B2B_paymentCondition';
import orderNumber from '@salesforce/label/c.fan_B2B_orderNumber';
import netValue from '@salesforce/label/c.fan_B2B_netValue';
import payOption from '@salesforce/label/c.fan_B2B_payOption';
import creditPayment from "@salesforce/label/c.fan_B2B_creditPayment";
import actions from '@salesforce/label/c.fan_B2B_actions';
import invoiceConsultation from '@salesforce/label/c.fan_InvoiceConsultation';
import invoice from '@salesforce/label/c.fan_B2B_bill';
import emptyInvoiceMessage from '@salesforce/label/c.fan_EmptyInvoiceMessage';

import initDate from '@salesforce/label/c.fan_B2B_initDate';
import endDate from '@salesforce/label/c.fan_B2B_endDate';

import sendTo from '@salesforce/label/c.fan_B2B_sendTo';
import deliveryInstruction from '@salesforce/label/c.fan_B2B_deliveryInstruction';

import paymentConfirmation from '@salesforce/label/c.fan_paymentConfirmation';
import billsToPay from '@salesforce/label/c.fan_billsToPay';
import totalAmountToPay from '@salesforce/label/c.fan_totalAmountToPay';
import continuePayment from '@salesforce/label/c.fan_continuePayment';
import successfulPayment from '@salesforce/label/c.fan_successfulPayment';
import paySelected from '@salesforce/label/c.fan_paySelected';

// Inventory Lables
import buttonLabel from '@salesforce/label/c.fan_InventoryLocationGroupBtn';
import buttonLabelClear from '@salesforce/label/c.fan_InventoryLocationGroupClearBtn';
import tabNameLabel from '@salesforce/label/c.fan_InventoryLocationGroupTabName';
import textFilterLabel from '@salesforce/label/c.fan_InventoryLocationGroupText';
import textSKUNoMessage from '@salesforce/label/c.fan_InventoryLocationGroupSKUMessage';
import textSKUText from '@salesforce/label/c.fan_InventoryLocationGroupSKUText';
import reference from '@salesforce/label/c.fan_ReferenceLabel';
import address from '@salesforce/label/c.fan_AddressLabel';
import available from '@salesforce/label/c.fan_AvailableLabel';
import concessionaire from '@salesforce/label/c.fan_ConcessionaireLabel';
import agency from '@salesforce/label/c.fan_Agency';
import model from '@salesforce/label/c.AM_AnioLBL';
import modelLine from '@salesforce/label/c.fan_ModelLine';
import hasSubstitute from '@salesforce/label/c.fan_InventoryHasSubstituteLabel';
import yes from '@salesforce/label/c.fan_B2B_Yes';
import no from '@salesforce/label/c.fan_B2B_No';
import stockSearchLabel from '@salesforce/label/c.fan_InventoryStockSearchLabel';

// Labels for Payment Method
import paymentMethod from '@salesforce/label/c.fan_PaymentMethod';
import paymentWithPSE from '@salesforce/label/c.fan_PaymentWithPSE';
import paymentWithRedAval from '@salesforce/label/c.fan_PaymentWithRedAval';
import paymentWithBancoBogota from '@salesforce/label/c.fan_PaymentWithBancoBogota';

import paymentLegend from '@salesforce/label/c.fan_PaymentLegend';
import paymentError from '@salesforce/label/c.fan_PaymentError';
import errorRegisteringPayment from '@salesforce/label/c.fan_ErrorRegisteringPayment';
import paymentInfoLabel from '@salesforce/label/c.fan_paymentInfoLabel';
import paymentInAdvance from '@salesforce/label/c.fan_PaymentInAdvance';
import paymentInAdvanceError from '@salesforce/label/c.fan_PaymentInAdvanceError';

// Labels for Invoice Builder.
import documentColumn from '@salesforce/label/c.fan_InvoiceBuilderDocumentColumn';
import referenceColumn from '@salesforce/label/c.fan_InvoiceBuilderReferenceColumn';
import descriptionColumn from '@salesforce/label/c.fan_InvoiceBuilderDescriptionColumn';
import quantityColumn from '@salesforce/label/c.fan_InvoiceBuilderQuantityColumn';
import discountColumn from '@salesforce/label/c.fan_InvoiceBuilderDiscountColumn';
import motosUnitPriceColumn from '@salesforce/label/c.fan_MotosInvoiceBuilderUnitPriceColumn';
import posventaUnitPriceColumn from '@salesforce/label/c.fan_PosventaInvoiceBuilderUnitPriceColumn';
import subtotalValueColumn from '@salesforce/label/c.fan_InvoiceBuilderSubtotalValueColumn';
import feeRateColumn from '@salesforce/label/c.fan_InvoiceBuilderFeeRateColumn';
import feeValueColumn from '@salesforce/label/c.fan_InvoiceBuilderFeeValueColumn';
import netValueColumn from '@salesforce/label/c.fan_InvoiceBuilderNetValueColumn';
import issueDateColumn from '@salesforce/label/c.fan_InvoiceBuilderIssueDateColumn';
import chassisColumn from '@salesforce/label/c.fan_InvoiceBuilderChassisColumn';
import engineColumn from '@salesforce/label/c.fan_InvoiceBuilderEngineColumn';
import modelColumn from '@salesforce/label/c.fan_InvoiceBuilderModelColumn';
import colorColumn from '@salesforce/label/c.fan_InvoiceBuilderColorColumn';
import motosGrossValueRow from '@salesforce/label/c.fan_MotosInvoiceBuilderGrossValueRow';
import posventaGrossValueRow from '@salesforce/label/c.fan_PosventaInvoiceBuilderGrossValueRow';
import subtotalValueRow from '@salesforce/label/c.fan_InvoiceBuilderSubtotalValueRow';
import discountRow from '@salesforce/label/c.fan_InvoiceBuilderDiscountRow';
import freightValueRow from '@salesforce/label/c.fan_InvoiceBuilderFreightValueRow';
import totalVATRow from '@salesforce/label/c.fan_InvoiceBuilderTotalVATRow';
import totalValueRow from '@salesforce/label/c.fan_InvoiceBuilderTotalValueRow';

// Labels for Order Details
import orderDetailsTotal from '@salesforce/label/c.fan_B2B_OrderDetails_Total';

// Attached File Downloader.
import downloadManual from '@salesforce/label/c.fan_DownloadManual';

//Label for checkout Button
import chekoutButton from '@salesforce/label/c.fan_checkoutButton';
import limiteCarrito from '@salesforce/label/c.fanLimiteCarrito';

// Backorder Products Labels
import backorderDateLabel from '@salesforce/label/c.fan_backorderDateLabel';
import backorderQuantityLabel from '@salesforce/label/c.fan_backorderQuantityLabel';
import backorderSearchBy from '@salesforce/label/c.fan_backorderSearchBy';
import backorderEstimationDate from '@salesforce/label/c.fan_EstimationDate';


//Labels for the collapse and expand buttons
import collapseButton from '@salesforce/label/c.fan_collapse';
import expandButton from '@salesforce/label/c.fan_expand';

// Labels Financial Statement
import financialStatementHeader from '@salesforce/label/c.fan_FinancialStatementHeader';
import noFinancialStatementFound from '@salesforce/label/c.fan_NoFinancialStatementFound';

// Labels Financial Statement Xlsx Builder
import fsbFileName from '@salesforce/label/c.fan_FSBFileName';
import fsbPhone from '@salesforce/label/c.fan_FSBPhone';
import fsbSir from '@salesforce/label/c.fan_FSBSir';
import fsbCode from '@salesforce/label/c.fan_FSBCode';
import fsbDearSir from '@salesforce/label/c.fan_FSBDearSir';
import fsbDateRange from '@salesforce/label/c.fan_FSBDateRange';
import fsbCurrency from '@salesforce/label/c.fan_FSBCurrency';
import fsbDate from '@salesforce/label/c.fan_FSBDate';
import fsbDocument from '@salesforce/label/c.fan_FSBDocument';
import fsbCrossingDocument from '@salesforce/label/c.fan_FSBCrossingDocument';
import fsbExpirationDate from '@salesforce/label/c.fan_FSBExpirationDate';
import fsbDocumentValue from '@salesforce/label/c.fan_FSBDocumentValue';
import fsbInitialBalance from '@salesforce/label/c.fan_FSBInitialBalance';
import fsbAppliedValue from '@salesforce/label/c.fan_FSBAppliedValue';
import fsbEndingBalance from '@salesforce/label/c.fan_FSBEndingBalance';

// Labels for FO status component
import foStatusTitle from '@salesforce/label/c.fan_foStatusTitle';
import foOrderNumber from '@salesforce/label/c.fan_foOrderNumber';
import nameToDeliver from '@salesforce/label/c.fan_nameToDeliver';
import totalAmount from '@salesforce/label/c.fan_totalAmount';
import orderStatus from '@salesforce/label/c.fan_orderStatus';
import guideNumber from '@salesforce/label/c.fan_guideNumber';

export function billReportLabels() {
  return {
    billNumber,
    buyingOrderNumber,
    billDate,
    branchStore,
    paymentCondition,
    orderNumber,
    netValue,
    payOption,
    creditPayment,
    actions,
    invoiceConsultation,
    // LABELS BORROWED FROM CAPACITY REPORT BILL INFO
    bills,
    expirationDate,
    download,
    // SEARCH AND FILTER LABELS
    searchFilter,
    sortBy,
    filterHere,

    buttonLabel,
    invoice,
    emptyInvoiceMessage,
    initDate,
    endDate,
    buttonLabelClear,
    inProgress,
    libraryLoad,
    paymentConfirmation,
    billsToPay,
    totalAmountToPay,
    continuePayment,
    cancel,
    successfulPayment,
    paySelected,
    total,
    credit,
    creditToPay,
    selectPayOption
  }
}

export function checkoutButtonLabels(){
  return {
    chekoutButton,
    limiteCarrito
  }
}

export function expandCollapseButton(){
  return{
    collapseButton,
    expandButton
  }
}

export function cartUploadLabels() {
  return {
    processSelectedFile,
    selectFiles,
    reset,
    filesSelected,
    processingError,
    pasteInputHere,
    processText,
    selectInputType,
    fileOption,
    incorrectFileFormat,
    fileTypeNotSupported,
    textArea,
    showHelpDialog,
    pleaseWait,
    noTextFound,
    fileIsEmpty,
    processingOptions,
    maxUploadRowsExceeded,
    libraryLoad,
    errorLoadingSheetJS,
    seachError,
    fileTooLong
  }
}

export function productDetailsLabels() {
  return {
    addToCartErrorPDP,
    addToNewWishlistError,
    addToNewWishlistSucess,
    addToWishlistError,
    addToWishlistSucess,
    addToExistingWishlist,
    addToWishlist,
    cancel,
    cartHasBeenUpdated,
    close,
    createWishlist,
    discountPerUnit,
    error,
    quantity,
    save,
    success,
    selectPlaceHolder,
    selectWishlist,
    selectWishlistPlaceholder,
    wishlistName,
    wishlistNameMissingValue
  }
}

export function cartContentLabels() {
  return {
    addAllToWishlist,
    addAllToWishlistSuccess,
    addToNewWishlistError,
    addToWishlist,
    addToExistingWishlist,
    cartHeader,
    cancel,
    clearCart,
    createdDateAsc,
    createdDateDesc,
    createWishlist,
    defaultWishlistName,
    emptyCartBody,
    emptyCartHeader,
    error,
    invalidQuantity,
    loadingCartItems,
    nameAsc,
    nameDesc,
    selectAllWithBackorder,
    unselectAllWithBackorder,
    selectWishlist,
    selectWishlistPlaceholder,
    wishlistName,
    wishlistNameMissingValue,
    save,
    sortBy,
    success,
    updatingProductError,
    contadoPaymentWarning,
    anticipoPaymentWarning
  };
}

export function cartItemsLabels() {
  return {
    abbreviatedQuantity,
    backorder,
    color,
    sku,
    publicPrice,
    dealerPrice,
    discountedPrice
  }
}

export function orderTypeLabels() {
  return {
    orderType,
    codigoVIN,
    paymentOption,
    ineligibleOrderType
  }
}

export function accountStateLabels() {
  return {
    codeAccountState,
    currentAmount,
    description,
    expired,
    expiryAmountShort,
    expiryAmountMedium,
    expiryAmountLong,
    expiryAmountMax,
    exportFileName,
    libraryLoad,
    total
  };
}

export function accountStateDisplayLabels() {
  return {
    expired,
    codeAccountState,
    expiryAmountShort,
    expiryAmountMedium,
    expiryAmountLong,
    expiryAmountMax,
    description,
    total,
    currentAmount,
    checkAccountState,
    exportLabel,
    // SEARCH AND FILTER LABELS
    filterHere,
    searchFilter,
    sortBy
  }
}

export function capacityReportLabels() {
  return {
    bill,
    billValue,
    expirationDate,
    expiredBillValue,
    expiredDays,
    libraryLoad,
    orderTypeBillInfo,
    quotaReport,
    exportCapacityLabel,
    total
  };
}

export function capacityReportDetailLabels() {
  return {
    assignedCreditCapacity,
    availableCreditCapacity,
    advancedBalanceFavor,
    consignedValue,
    expiredWallet,
    dispatchmentOrder,
    pendingPaymentOrders,
    walletTotal,
    creditCapacityDetail,
    motorcycleStore,
    aftermarketStore,
    quotaReport
  }
}

export function capacityReportBillInfoLabels() {
  return {
    bills,
    totalAmountBills,
    totalAmountExpiredBills,
    bill,
    expirationDate,
    orderTypeBillInfo,
    expiredDays,
    billValue,
    expiredBillValue,
    exportLabel,
    // SEARCH AND FILTER LABELS
    filterHere,
    searchFilter,
    sortBy
  }
}

export function retrieveContentLabel() {
  return retrievingContent;
}

export function closeLabel() {
  return close;
}

export function cancelLabel() {
  return cancel;
}

export function saveLabel() {
  return save;
}

export function resultsLabel() {
  return results;
}

export function addressesLabels() {
  return {
    sendTo
  }
}

export function inventoryLabels(){
  return {
    buttonLabel, 
    buttonLabelClear,
    tabNameLabel,
    textFilterLabel,
    textSKUNoMessage,
    textSKUText,
    reference,
    description,
    address,
    agency,
    available,
    concessionaire,
    modelLine,
    model,
    color,
    hasSubstitute,
    close,
    yes,
    no,
    selectPlaceHolder,
    branchStore,
    stockSearchLabel
  }
}

export function orderDetailsLabels(){
  return {
    deliveriesGenerated,
    deliveryInstruction,
    shipping,
    subtotal,
    taxes,
    total: orderDetailsTotal
  };
}

export function paymentMethodLabels() {
  return {
    creditCard,
    pay: payOption,
    paymentMethod,
    paymentLegend,
    paymentWithPSE,
    paymentWithRedAval,
    paymentWithBancoBogota,
    paymentError,
    errorRegisteringPayment,
    paymentInfoLabel,
    paymentInAdvance,
    paymentInAdvanceError
  };
}

export function fileManager() {
  return {
    errorExportingFile,
    errorLoadingSheetJS
  };
}

export function financialStatementLabels() {
  return {
    download,
    endDate,
    financialStatementHeader,
    initDate,
    noFinancialStatementFound,
    readTimedOut
  };
}

export function financialStatementXlsxBuilderLabels() {
  return {
    fileName: fsbFileName,
    phone: fsbPhone,
    sir: fsbSir,
    code: fsbCode,
    dearSir: fsbDearSir,
    dateRange: fsbDateRange,
    currency: fsbCurrency,
    date: fsbDate,
    document: fsbDocument,
    crossingDocument: fsbCrossingDocument,
    expirationDate: fsbExpirationDate,
    documentValue: fsbDocumentValue,
    initialBalance: fsbInitialBalance,
    appliedValue: fsbAppliedValue,
    endingBalance: fsbEndingBalance
  };
}

export function motosInvoiceBuilderLabels() {
  return {
    // Header
    document: documentColumn,
    reference: referenceColumn,
    issueDate: issueDateColumn,
    chassis: chassisColumn,
    engine: engineColumn,
    discount: discountColumn,
    color: colorColumn,
    model: modelColumn,
    quantity: quantityColumn,
    unitPrice: motosUnitPriceColumn,
    feeRate: feeRateColumn,

    // Total rows.
    grossValueRow: motosGrossValueRow,
    discountRow,
    freightValueRow,
    totalVATRow,
    totalValueRow,
  };
}

export function posventaInvoiceBuilderLabels() {
  return {
    // Header
    document: documentColumn,
    reference: referenceColumn,
    description: descriptionColumn,
    quantity: quantityColumn,
    discount: discountColumn,
    unitPrice: posventaUnitPriceColumn,
    subtotalValue: subtotalValueColumn,
    feeRate: feeRateColumn,
    feeValue: feeValueColumn,
    netValue: netValueColumn,

    // Total rows.
    grossValueRow: posventaGrossValueRow,
    subtotalValueRow,
    discountRow,
    freightValueRow,
    totalVATRow,
    totalValueRow,
  };
}

export function attachedFileDownloaderLabels() {
  return {
    downloadManual
  };
}

export function backorderProductsLabels() {
  return {
    branchStore,
    backorderDateLabel,
    buyingOrderNumber,
    orderType,
    reference,
    description,
    backorderQuantityLabel,
    backorderSearchBy,
    backorderEstimationDate,
  };
}

export function searchResultsLabels() {
  return {
    addToCartErrorPDP,
    branchStore,
    cartHasBeenUpdated,
    clearAll,
    error,
    filters,
    selectPlaceHolder,
    sortBy
  };
}

export function searchCardLabels() {
  return {
    addToCart: addToCartLabel,
    abbreviatedQuantity,
    productHasnotPrice,
    selectBranch,
    unavailablePrice
  };
}

export function searchCategoryLabel() {
  return {
    category
  };
}

export function foStatusLabels() {
  return {
    foStatusTitle,
    foOrderNumber,
    nameToDeliver,
    totalAmount,
    orderStatus,
    guideNumber,
    exportLabel,
    searchFilter,
    filterHere,
    sortBy
  }
}