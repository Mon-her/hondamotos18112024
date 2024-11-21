import { LightningElement, wire, api } from 'lwc';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { MessageContext, publish, subscribe, unsubscribe } from 'lightning/messageService';

// SObject Fields.
import ORDER_TYPE_FIELD from '@salesforce/schema/WebCart.fan_TipoPedido__c'
import PAYMENT_CONDITION_FIELD from '@salesforce/schema/WebCart.fan_FormaPago__c'
import CODIGO_VIN_FIELD from '@salesforce/schema/WebCart.fan_CodigoVIN__c'
import WEB_STORE_ID_FIELD from '@salesforce/schema/WebCart.WebStoreId'
import TOTAL_COUNT from '@salesforce/schema/WebCart.TotalProductCount';
import ACCOUNT_ID from '@salesforce/schema/WebCart.AccountId';
import IS_ANTICIPO from '@salesforce/schema/WebCart.fan_EsAnticipo__c';


// Lightning message service channels.
import CART_CHANGED from '@salesforce/messageChannel/lightning__commerce_cartChanged';
import TO_FAN_CART_CONTENTS from '@salesforce/messageChannel/toFanCartContents__c';
import INPUT_CHANNEL from '@salesforce/messageChannel/toFanOrderType__c';

// Labels
import { orderTypeLabels } from 'c/fanLabels'

// Apex methods.
import updateOrderType from '@salesforce/apex/fan_B2BCartCtrl.updateOrderType';
import updatePaymentCondition from '@salesforce/apex/fan_B2BCartCtrl.updatePaymentCondition';
import updateCodigoVIN from '@salesforce/apex/fan_B2BCartCtrl.updateCodigoVIN';
import accountOptions from '@salesforce/apex/fan_B2BAccountCtrl.accountOptions';
import getValorAnticipo from '@salesforce/apex/fan_B2BPaymentController.getValorAnticipo';
import setAnticipo from '@salesforce/apex/fan_B2BCartCtrl.setAnticipo';

// Fields of the WebCart to query.
const FIELDS = [
    ORDER_TYPE_FIELD,
    PAYMENT_CONDITION_FIELD,
    CODIGO_VIN_FIELD,
    WEB_STORE_ID_FIELD,
    TOTAL_COUNT,
    ACCOUNT_ID,
    IS_ANTICIPO
];

const CUENTA_REPUESTERO = 'REPUESTERO';
const PEDIDOS_REPUESTERO = new Set(['Normal', 'Emergencia', 'Dotación', 'Insumos', 'Herramientas', 'Remate', 'Im Aereo', 'Im Courier']);
const PAGO_CONTADO = 'CON';

export default class FanTipoPedido extends LightningElement {

    /**
     * The recordId provided by the cart detail flexipage.
     *
     * @type {string}
     */
    @api
    recordId;

    /** The id to fetch the picklist values. */
    recordTypeId;

    /** The selected order type. */
    orderTypeValue;

    /** The fan_CodigoVIN__c value. */
    codigoVIN;

    /** The selected payment option. */
    paymentConditionValue;

    /** Order type options for combobox. */
    optionsTipoPedido;

    /** Payment condition options for combobox. */
    optionsCondicionPago;

    /** Validate if cart has products */
    noItemsInCart;

    /** Payment condition for this account */
    paymentConditionAllowed;

    /**Activate spinner until all the process in fanCartContent is complete */
    cartLoadedActivateSpinner = true;

    /**Valor anticipo of the Account */
    valorAnticipo;

    /** Flag that defines whether to show VIN input field. */
    get showCodigoVIN() {
        return this.orderTypeValue?.includes('Garantia');
    }

    // Spinner flag.
    get loading() {
        console.log('Activado---->', this.cartLoadedActivateSpinner);
        return this.cartLoadedActivateSpinner || (!this.someError &&
            (
                !this.webStoreId ||
                !this.optionsTipoPedido ||
                !this.optionsCondicionPago ||
                this._loading
            ) 
        );
    }
    /** User interactions. */
    _loading;
    /** Errors wiring data. */
    someError;

    isPaymentConditionChangeable = true;

    get isPaymentConditionDisabled() {
        return this.noItemsInCart == true ? this.noItemsInCart : !this.isPaymentConditionChangeable; 
    }

    @wire(MessageContext)
    messageContext;

    /**
     * Fetch the default record.
     */
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    async fetchWebCart(result) {
        // Store state to refresh later
        this.datos = result;
        const { data, error } = result;

        if(data) {
            await this.getAccountOptions(getFieldValue(data, ACCOUNT_ID));
            this.recordTypeId = data.recordTypeId;
            // Set values for the comboboxes
            this.orderTypeValue = getFieldValue(data, ORDER_TYPE_FIELD);
            this.paymentConditionValue = getFieldValue(data,IS_ANTICIPO) === true? 'anticipo': getFieldValue(data, PAYMENT_CONDITION_FIELD);
            this.codigoVIN = getFieldValue(data, CODIGO_VIN_FIELD);
            this.webStoreId = getFieldValue(data, WEB_STORE_ID_FIELD);
            this.noItemsInCart = getFieldValue(data, TOTAL_COUNT) == 0;
            if(this.loading) { // For cache refresh calls.
                this._loading = false; 
            }

            publish(this.messageContext, TO_FAN_CART_CONTENTS, { payment: this.paymentConditionValue, orderType: this.orderTypeValue });
        } else if(error) {
            console.log('Error in fetchWebCart --> ', error);
            this.someError = true;
        }
    }

    /**
     * Fetch the values for order type picklist.
     */
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName:  ORDER_TYPE_FIELD})
    getOrderTypeValues({ data, error }) {
        if(data) {
            const orderTypeOptions = data.values.map(({ label, value}) => ({ label, value }));

            this.optionsTipoPedido = this._planCL1 === CUENTA_REPUESTERO
            ? orderTypeOptions.filter(({ label }) => PEDIDOS_REPUESTERO.has(label))
            : orderTypeOptions;
        } else if(error) {
            console.log('Error in getOrderTypeValues --> ', error);
            this.someError = true;
        }
    }

    /**
     * Fetch the values for payment option picklist.
     */
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: PAYMENT_CONDITION_FIELD})
    getPaymentConditionValues({ data, error }) {
        if(data) {
            this.optionsCondicionPago = (data.values || []).map((option) => {
                if(option.value =='anticipo'){
                    return ({label: option.label + ` (${this.formatearComoPesoColombiano(this.valorAnticipo)})`, value: option.value})
                }
                return ({ label: option.label, value: option.value });
            }
                
            );
        } else if(error) {
            console.log('Error in getPaymentConditionValues --> ', error);
            this.someError = true;
        }
    }

    // Get payment conditions picklist for this account
    get getPaymentConditions(){
        if (this.optionsCondicionPago != null && this.paymentConditionAllowed == PAGO_CONTADO) {
            this.optionsCondicionPago = this.optionsCondicionPago.filter(option => option.value == 'contado' || option.value == 'anticipo');
        }
        return this.optionsCondicionPago;
    }

    // Centralized order type labels
    get label(){
        return orderTypeLabels();
    }

    connectedCallback() {
        this.subscribeToInputChannel();
    }

    async getAccountOptions(accountId) {
        const { fan_condicionPago__c, fan_plan_CL1__c } = await accountOptions({ accountId });
        this.paymentConditionAllowed = fan_condicionPago__c;
        this._planCL1 = fan_plan_CL1__c;

        const valorAnticipo = await getValorAnticipo({ cartId: this.recordId });

        if(valorAnticipo){
            this.valorAnticipo = valorAnticipo >= 0 && valorAnticipo != null ? valorAnticipo : 0;//Avoid to show negative quantities to the user
        }

    }

    /**
     * Handle order type changes.
     * @param {Event} event 
     */
    handleChangeTipoPedido(event) {
        this.notifyPaymentConditionChanged();

        this._loading = true;
        this.orderTypeValue = event.detail.value;
        console.log('orderTypeValue  from event --> ', this.orderTypeValue);

        const cart = {
            Id: this.recordId,
            fan_TipoPedido__c: this.orderTypeValue,
            WebStoreId: this.webStoreId
        };

        this.notifyCartChanged();
        this.resolveOrderType(cart);
        //Activate spinner again until the fanCartContentFinishLoading
        this.cartLoadedActivateSpinner = true;
    }

    validateCodigoVINInput(event) {
        const { currentTarget, data } = event;
        const { selectionStart, selectionEnd, value } = currentTarget;

        const nextValue = `${value.slice(0, selectionStart)}${data ?? ''}${value.slice(selectionEnd)}`;

        if((!/^[a-z0-9]{0,17}$/i.test(nextValue))) {
            event.preventDefault();
        }
    }

    /**
     * Handle codigo VIN changes.
     * @param {Event} event 
     */
    handleChangeCodidoVIN({ target }) {
        this.notifyPaymentConditionChanged();

        const { value } = target;
        if(this.codigoVIN !== value) {
            this._loading = true;
            this.codigoVIN = value;
            updateCodigoVIN({
                cartId: this.recordId,
                codigoVIN: this.codigoVIN
            }).catch(this.handleCodigoVINErrors.bind(this))
            .finally(() => {
                console.log('codigoVIN --> ',this.codigoVIN);
                this._loading = false;
                // Notify about cart changes 
                this.notifyCartChanged();
            });
        }
    }

    /**
     * Handle payment condition changes.
     * @param {Event} event 
     */
    handleChangeCondicionPago(event) {
        this.notifyPaymentConditionChanged();
        this._loading = true;
        this.paymentConditionValue = event.detail.value; 
        let condicionPago = this.paymentConditionValue == 'anticipo' ? 'credito' : event.detail.value;
        //Set anticipo to true/false
        setAnticipo({anticipo: this.paymentConditionValue == 'anticipo', cartId: this.recordId});

        updatePaymentCondition({
            cartId: this.recordId,
            paymentCondition: condicionPago
        })
        .then(() => {
            // Notify about cart changes .
            this.notifyCartChanged();
            // Update items prices using the new payment condition
            publish(this.messageContext, TO_FAN_CART_CONTENTS, { payment: this.paymentConditionValue, orderType: this.orderTypeValue });
        })
        .catch((error) => console.log('Error in updatePaymentCondition --> ', error))
        .finally(() => {
            this._loading = false;
            this.cartLoadedActivateSpinner = true;
        });
    }

    /**
     * Manage the subscription to input channel.
     */
    subscribeToInputChannel() {
        if(!this.subscription) {
            this.subscription = subscribe(this.messageContext, INPUT_CHANNEL,
                (data ={}) => {
                    if(data.type === 'cartLoadCompleted'){
                        this.cartLoadedActivateSpinner = false;
                    } else {
                        this._loading = true;
                        this.isPaymentConditionChangeable = data.isPaymentConditionChangeable;
                        // Refresh LDS.
                        getRecordNotifyChange([{ recordId: this.recordId }]);
                    }
                }
            );
        }
    }

    /**
     * Unsubscribe to input channel.
     */
    unsubscribeToInputChannel() {
        unsubscribe(this.subscription);
         this.subscription = null;
    }

    disconnectedCallback() {
        this.unsubscribeToInputChannel();
    }

    /**
     * Update the WebCart fan_TipoPedido__c and validate if the order type is eligible.
     * @param {Object} cart The cart with the Id, fan_TipoPedido__c and WebStoreId.
     */
    resolveOrderType(cart) {
        updateOrderType({ cart })
        .then(({ isPaymentConditionChangeable, message, orderType, show, title }) => {
            this.isPaymentConditionChangeable = isPaymentConditionChangeable;
            // Show validation result .
            if(show) {
                this.dispatchEvent(new ShowToastEvent({
                    title: title,
                    variant: 'error',
                    mode: 'dismissible',
                    message: message
                }));
            }

            // Update cartItem prices.
            if(orderType.includes('_')) {
                publish(this.messageContext, TO_FAN_CART_CONTENTS, { payment: this.paymentConditionValue, orderType: this.orderTypeValue });
            }

            // Refresh LDS.
            getRecordNotifyChange([{ recordId: this.recordId }]);
        }).catch(error => {
            console.log('Error in updateOrderType --> ', error);
            this._loading = false;
        });
    }

    handleCodigoVINErrors(error) {
        if(error.body?.message?.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
            this.dispatchEvent(new ShowToastEvent({
                title: error.body.message.split(':')[1].replace(/.*, /, ''),
                variant: 'error',
                mode: 'dismissible'
            }));
        } else {
            console.log('Error in updateCodigoVIN --> ', error);
        }
    }

    notifyCartChanged() {
        publish(this.messageContext, CART_CHANGED, { origin: 'fanOrderType',checkoutButtonDisabled: false,  paymentCondition: this.paymentConditionValue, orderType: this.orderTypeValue, vinCode: this.codigoVIN });
    }
    /**Disabled the checkout button until*/
    notifyPaymentConditionChanged(){
        publish(this.messageContext, CART_CHANGED, {origin: 'fanCartContents', type: 'cartItemPricesUpdate', checkoutButtonDisabled: true});
    }

    formatearComoPesoColombiano(numero) {
        try {
            // Verificar si el número es un decimal válido
            const numeroDecimal = parseFloat(numero);

            // Verificar si el número es un valor válido y no es cero
            if (isNaN(numeroDecimal) || numeroDecimal === 0) {
                return '$ 0,00';
            }

    
            // Formatear el número a formato de peso colombiano
            const formato = new Intl.NumberFormat('es-CO', {
                style: 'currency',
                currency: 'COP',
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            }).format(numeroDecimal);
        // Eliminar el código de moneda al final
        return formato.replace(/\s?[A-Z]{3}$/, '');

        } catch (error) {
            return 'Número no válido';
        }
    }
    
}