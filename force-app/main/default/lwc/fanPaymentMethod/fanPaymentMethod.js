import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

import { paymentMethodLabels } from 'c/fanLabels';

import updateMetodoPago from '@salesforce/apex/fan_B2BCartCtrl.updateMetodoPago';
import registerPayment from '@salesforce/apex/fan_B2BPaymentController.registerPayment';
//Import image for payment method Cash
import cashPaymentImage from '@salesforce/resourceUrl/CashPaymentPhoto';
import cashPaymentBcoBogotaImage from '@salesforce/resourceUrl/CashPaymentBcoBogotaPhoto';

// Custom Enums.
const Payment = {
    CARD: 'TARJETA',
    PSE: 'PSE',
    RED_AVAL: 'RED_AVAL',
    BCO_BOGOTA_OFC: 'BCO_BOGOTA_OFC'
};
const TransactionStatus = {
    CAPTURED: 'CAPTURED',
    ABANDONED: 'ABANDONED',
    WAITING_FOR_PAYMENT: 'WAITING_FOR_PAYMENT'
};
const validTransactionStatus = new Set(Object.values(TransactionStatus));

const VADS = {
    TRANS_STATUS: 'vads_trans_status',
    CARD_BRAND: 'vads_card_brand'
};

/**
 * @fires FlowNavigationNextEvent
 */
export default class fanPaymentMethod extends LightningElement {

    /**
     * The cartId for the current WebCart.
     * @return {string} The WebCart Id.
     */
    @api
    cartId;

    /**
     * Client identifier
     */
    @api
    idTercero;

    @api
    operationCenterBillData;

    @api
    documentType;

    @api
    documentNumber;

    @api
    amountToPay;

    @api
    hideCashPaymentOption = false;

    @api
    disabledPayButton=false;

    /**
     * @type {string}
     */
    selectedPaymentMethod = Payment.CARD;

    /**
     * @type {URL}
     */
    url = new URL(window.location.href);

    /**
     * Payment method enum.
     * @type {Object}
     */
    payment = Payment;

    // Spinner flag.
    isLoading;

    /**
     * @return {string}
     */
    get urlReturn() {
        return this.url.origin + this.url.pathname;
    }

    /**
     * @return {boolean}
     */
    get isTransactionStatusInvalid() {
        return this.transactionStatus && !validTransactionStatus.has(this.transactionStatus);
    }

    /**
     * @return {string}
     */
    get transactionStatus() {
        return this.url.searchParams.get(VADS.TRANS_STATUS) ?? JSON.parse(localStorage.getItem(this.cartId))?.transactionStatus;
    }

    /**
     * @return {string}
     */
    get cardBrand() {
        return this.url.searchParams.get(VADS.CARD_BRAND) ?? JSON.parse(localStorage.getItem(this.cartId))?.cardBrand;
    }

    /**
     * @return {boolean}
     */
    get isCardPaymentSelected() {
        return this.selectedPaymentMethod === Payment.CARD;
    }

    /**
     * @return {boolean}
     */
    get isPsePaymentSelected() {
        return this.selectedPaymentMethod === Payment.PSE;
    }

    /**
     * @return {boolean}
     */
    get isRedAvalPaymentSelected() {
        return this.selectedPaymentMethod === Payment.RED_AVAL;
    }

     /**
     * @return {boolean}
     */
    get isBcoBogotaPaymentSelected() {
        return this.selectedPaymentMethod === Payment.BCO_BOGOTA_OFC;
    }

    /**
     * The object of labels used in the cmp. 
     * @return {Object}
     */
    get labels() {
        return paymentMethodLabels();
    }

    //get image for Cash payment
    get imageFotPaymentCast(){
        return cashPaymentImage;
    }

    //get image for Cash payment Banco de Bogotá
    get imageForPaymentCastBcoBogota(){
        return cashPaymentBcoBogotaImage;
    }

    connectedCallback() {
        if(this.transactionStatus) {
            this.handleTransactionStatus();
        }

    }

    async handlePaymentButton() {
        try {
            this.isLoading = true;
           
            if(this.cartId) await updateMetodoPago({ cartId: this.cartId, metodoPago: this.selectedPaymentMethod });

            if(this.cartId && (this.isRedAvalPaymentSelected || this.isBcoBogotaPaymentSelected)) {
                await registerPayment({
                    cartId: this.cartId,
                    parameters: { gatewayRefDetails: {} }
                });
                this.dispatchEvent(new FlowNavigationNextEvent());
            } else {
                await this.template.querySelector('c-fan-payzen-form').submitForm();
            }
        } catch (error) {
            this.isLoading = false;
            console.log('Error in handlePaymentButton -->', error);
        }
    }

    handlePaymentMethodSelected(event) {
        this.selectedPaymentMethod = event.target.value;
    }

    extractPayzenParameters(searchParams) {
        return [
            'vads_trans_date',
            'vads_card_brand',
            'vads_auth_number',
            'vads_card_number',
            'vads_acquirer_network',
            'vads_contract_used'
        ]
        .reduce((accumulator, key) => ({
            ...accumulator,
            [key]: searchParams.get(key)
        }), {});
    }

    buildPaymentParameters(searchParams) {
        const { vads_trans_status, vads_trans_date, vads_card_brand, vads_auth_number,
            vads_card_number, vads_acquirer_network, vads_contract_used
        } = this.extractPayzenParameters(searchParams);

        const lastFourDigits = vads_card_number?.slice(vads_card_number?.length - 4);
        const gatewayRefDetails = {
            [Payment.CARD]: `${vads_card_brand}${lastFourDigits}`,
            [Payment.PSE]: `${vads_acquirer_network}${vads_contract_used}`
        };
        return {
            authNumber: vads_auth_number,
            transactionStatus: vads_trans_status, 
            transactionDate: vads_trans_date,
            gatewayRefDetails
        };
    }

    async handleTransactionStatus() {
        try {
            if(this.cartId){
                this.isLoading = true;
                const { searchParams } = this.url;

                if(this.transactionStatus === TransactionStatus.CAPTURED) {
                    localStorage.removeItem(this.cartId ? 'PagoFacturas' : this.orderId);
                    await registerPayment({
                        cartId: this.cartId,
                        parameters: this.buildPaymentParameters(searchParams)
                    });
                    this.dispatchEvent(new FlowNavigationNextEvent());
                } else if(searchParams.has(VADS.TRANS_STATUS)) {
                    // Save vads_trans_status and clean the search params of the url.
                    this.cacheVads();
                    window.history.replaceState(null, null, this.urlReturn);
                }
            }
        } catch (error) {
          this.showErrorRegisteringPaymentMessage();
          console.log('Error in handleTransactionStatus -->', error);
        } finally {
            this.isLoading = false;
        }
    }

    showErrorRegisteringPaymentMessage() {
        this.dispatchEvent(new ShowToastEvent({
            title: this.labels.errorRegisteringPayment,
            variant: 'error'
        }));
    }

    cacheVads() {
      // this.cartId ? 'PagoFacturas' : this.orderId
        localStorage.setItem(this.cartId, JSON.stringify({
            transactionStatus: this.transactionStatus,
            cardBrand: this.cardBrand
        }));
    }
}