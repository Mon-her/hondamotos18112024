import { api, LightningElement } from 'lwc';

import buildSignature from '@salesforce/apex/fan_B2BPaymentController.buildSignature';
import getPayzenParameters from '@salesforce/apex/fan_B2BPaymentController.getPayzenParameters';

// Data id value.
const FORM_IDENTIFIER = 'payzen-form';

const PaymentMethod = {
    CARD: 'TARJETA',
    PSE: 'PSE',
    RED_AVAL: 'RED_AVAL',
    BCO_BOGOTA_OFC: 'BCO_BOGOTA_OFC'
};
export default class FanPayzenForm extends LightningElement {

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
    get documentType() {
        return this._documentType ?? '';
    }

    set documentType(value) {
        this._documentType = value;
    }

    @api
    get documentNumber() {
        return this._documentNumber ?? '';
    }

    set documentNumber(value) {
        this._documentNumber = value;
    }

    @api
    amountToPay;

    amountToPayCart;

    @api
	get isLoading() {
        return this._isLoading;
    }

    set isLoading(value) {
        this._isLoading = value;
    }

    @api
    paymentMethod;

    @api
    urlReturn;

    // Form inputs. For more information -> https://payzen.io/lat/form-payment/reference/sitemap.html
    /**
     * @type {string}
     */
    orderId;

    /**
     * @type {string}
     */
    transactionId;

    get paymentCards() {
        return {
            [PaymentMethod.CARD]: this.payzenConfig.paymentCards,
            [PaymentMethod.PSE]: PaymentMethod.PSE,
            [PaymentMethod.RED_AVAL]: PaymentMethod.RED_AVAL,
            [PaymentMethod.BCO_BOGOTA_OFC]: PaymentMethod.BCO_BOGOTA_OFC
        }[this.paymentMethod];
    }

    /**
     * fan_PayzenConfig__c CustomSetting Values.
     * @name ctxMode - @type {string}
     * @name paymentCards - @type {string}
     * @name redirectErrorTimeout - @type {number}
     * @name redirectSuccessTimeout - @type {number}
     * @name siteId - @type {string}
     * @name accountNumber - @type {string}
     * @name operationCenter - @type {string}
     */
    payzenConfig = {};

    _isLoading;
    _documentType;
    _documentNumber;

    connectedCallback() {
        this.fetchPayzenParameters();
    }

    extractFormParameters(formElement) {
        return [...new FormData(formElement)]
        .filter(([key]) => key.startsWith('vads_'))
        .reduce((accumulator, [key, value]) => {
            accumulator[key] = value;
            return accumulator;
        }, {});
    }

    async fetchPayzenParameters() {
        try {
            this._isLoading = true;
            const data = await getPayzenParameters({ cartId: this.cartId })
            const { amount, ctxMode, orderId, paymentCards, siteId, transactionId, redirectErrorTimeout, redirectSuccessTimeout, urlCheck } = data;

            const operationCenter = data.operationCenter ?? this.operationCenterBillData;
            const accountNumber = data.accountNumber ?? this.idTercero;
            this.orderId = orderId ?? 'PagoFacturas-' + accountNumber;
            this.transactionId = transactionId;
            this.amountToPayCart = amount;
            this.payzenConfig = { siteId, ctxMode, paymentCards, redirectErrorTimeout, redirectSuccessTimeout, accountNumber, operationCenter, urlCheck };
        } catch (error) {
            console.log('Error in fetchPayzenParameters -->', error);
        } finally {
            this._isLoading = false;
        }
    }


    /**
     * Fill in the signature and vads_trans_date inputs.
     * @param signatureResult Object containing signature and vads_trans_date.
     */
    fillMissingInputs(signatureResult, formElement) {
        [
            'signature',
            'vads_trans_date'
        ].forEach((field) => {
            this.setInputValue(formElement, field, signatureResult[field])
        });
    }

    setInputValue(formElement, inputName, value) {
        formElement.querySelector(`[name="${inputName}"]`).value = value;
    }

    @api
    async submitForm() {
        try {
            const formElement = this.template.querySelector(`[data-id="${FORM_IDENTIFIER}"]`);
            const formParameters = this.extractFormParameters(formElement);

            const signatureResult = await buildSignature({ formParameters });
            this.fillMissingInputs(signatureResult, formElement);

            formElement.submit();
        } catch (error) {
            console.log('Error in submitForm -->', error);
        }
    }

    get amount () {
        return this.amountToPayCart ?? this.amountToPay
    }
}