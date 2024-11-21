import { LightningElement, wire, api } from 'lwc';
import { MessageContext, subscribe } from 'lightning/messageService';
import CART_CHANGED from '@salesforce/messageChannel/lightning__commerce_cartChanged';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import {NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import fetchCheckOutValidation from "@salesforce/apex/fan_CheckoutButtonController.fetchCheckOutValidation";

import ORDER_TYPE_FIELD from '@salesforce/schema/WebCart.fan_TipoPedido__c';
import NUMERO_VIN_FIELD from '@salesforce/schema/WebCart.fan_CodigoVIN__c';
import PAYMENT_CONDITION_FIELD from '@salesforce/schema/WebCart.fan_FormaPago__c';
import UNIQUE_PRODUCT_COUNT_FIELD from '@salesforce/schema/WebCart.UniqueProductCount';


import {checkoutButtonLabels} from 'c/fanLabels';

const MESSAGE_ORIGIN = {
    FAN_CART_CONTENTS: 'fanCartContents',
    FAN_ORDER_TYPE: 'fanOrderType',
    FAN_CART_SUMMARY: 'fanCartSummary'
};

const Fields = [
    ORDER_TYPE_FIELD,
    NUMERO_VIN_FIELD,
    PAYMENT_CONDITION_FIELD,
    UNIQUE_PRODUCT_COUNT_FIELD
]; 

const ORDERTYPEGARANTIA = 'RMT_Garantia';

export default class FanCheckoutButton extends NavigationMixin(LightningElement) {

    /**
     * The recordId provided by the cart detail flexipage.
     *
     * @type {string}
     */
    @api
    recordId;

    /**
     * The selected order type.
     * @type {String}
     */
    _orderType;


    /**
     * Contain the checkout validations
     * @type {Object}
     */
    _validationsForCheck = [];

    /**
     * The numeroVIN value.
     * @type {Number}
     */
    _numVIN;
     /**
     * gand total amount value.
     * @type {Number}
     */
     _totalAmount;

    /**
     * gand sub total amount value.
     * @type {Number}
     */
    _subtotalAmount

    /**
     * the condition Pedido value
     *
     * @type {String}
     */
    _paymentCondition;

    /**
     * Unique product Count
     */
    uniqueProductCount;
    
    /** Set if cart items dont have stock */
    _hasStock;
    
    url;
    /** If there was a change in the paymentCondition button is disabled until activation in fanCartContents Subscription */
    buttonDisabled = false;

    //value to disable the final order button and show cart limit message
    get isDisabled() {
        return this.buttonDisabled || 
        !this._hasStock || 
        !this._orderType || 
        !this._paymentCondition || 
        !this._totalAmount || 
        (this._orderType === ORDERTYPEGARANTIA && (this._numVIN ?? '').length < 17) || 
        this.showCartLimit(this.uniqueProductCount) ||
        this.isNotValidOrder;
    }

    @wire(MessageContext)
    messageContext;

    /*
    * fetch the record
    */
   @wire(getRecord, {recordId: '$recordId', fields: Fields})
   fetchRecord({data, error}){
    if(data){
        this._orderType = getFieldValue(data, ORDER_TYPE_FIELD);
        this._paymentCondition = getFieldValue(data, PAYMENT_CONDITION_FIELD);
        this._numVIN = getFieldValue(data, NUMERO_VIN_FIELD);
        this.uniqueProductCount = getFieldValue(data, UNIQUE_PRODUCT_COUNT_FIELD);
    } else if(error){
        console.log('Error en el fetch del record >>> ', error);
    }
   }

   async checkOutValidations() {
    try {
      this._validationsForCheck = await fetchCheckOutValidation();
    } catch (error) {
      console.error('Error en el fetch de validaciones >>> ', error);
      this._validationsForCheck = []
    }
   }
    
    subscribeToMessageChannel(){
        // This event is called in 2 components: OrderType & CartContents
        if(!this.subscription){
            this.subscription = subscribe(
                this.messageContext,
                CART_CHANGED,
                (data = {}) => {
                    const { origin, type } = data;
                    if(origin === MESSAGE_ORIGIN.FAN_CART_CONTENTS && type == undefined && data.cartItemDeleted === undefined) {
                        this._hasStock = data.hasStock;
                    } else if(origin === MESSAGE_ORIGIN.FAN_CART_CONTENTS && type == 'cartItemPricesUpdate') {
                        this.buttonDisabled = data.checkoutButtonDisabled;
                    } 
                    else if(origin === MESSAGE_ORIGIN.FAN_ORDER_TYPE) {
                        const { paymentCondition, orderType, vinCode } = data;
                        this._paymentCondition = paymentCondition;
                        this._orderType = orderType;
                        this._numVIN = vinCode;
                        this.buttonDisabled = data.checkoutButtonDisabled;
                    } else if(origin === MESSAGE_ORIGIN.FAN_CART_SUMMARY) {
                        this._totalAmount = data.totalAmount;
                        this._subtotalAmount = data.subtotalAmount;
                    }
                    else if(origin === MESSAGE_ORIGIN.FAN_CART_CONTENTS && data.cartItemDeleted != undefined){
                        this.uniqueProductCount = data.cartItemDeleted;
                        this.buttonDisabled = this.showCartLimit(this.uniqueProductCount);
                    }
                    console.log('CART_CHANGED data --> ',data);
                }
            )
        }
    }

    handleClick(){
        this.url = "/checkout/" + this.recordId;
        console.log('url ---> ', this.url);
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": `${this.url}`
            }
        });
    }

    async connectedCallback(){
        this.subscribeToMessageChannel();
        await this.checkOutValidations();
    }

    //label
    get label(){
        return checkoutButtonLabels();
    }

   getValidationResult(valueA,operator, valueB){
        const operations = {
            '>': valueA > valueB,
            '<': valueA < valueB,
            '==': valueA === valueB,
            '>=': valueA >= valueB,
            '<=': valueA <= valueB,
        }

        return operations[operator];
   }

   validatePaymentCondition(paymentConditions){
        paymentConditions = paymentConditions.split('/');
        return paymentConditions.some(condition => condition === this._paymentCondition)
   }

    get isNotValidOrder() {
        const priceValidations = this._validationsForCheck.filter(({fan_Order_Type__c }) => fan_Order_Type__c === this._orderType);
        if (priceValidations.length  === 0) {
            return false;
        }

        return priceValidations.some(({fan_Price__c,fan_Operator__c,fan_Payment_Condition__c}) => 
            (this.getValidationResult(fan_Price__c,fan_Operator__c,this._subtotalAmount)) && 
            this.validatePaymentCondition(fan_Payment_Condition__c))
    }

    showCartLimit(cartUniqueCount){
        if(cartUniqueCount > 200){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: '',
                    label: '',
                    message: this.label.limiteCarrito.replace('{1}', cartUniqueCount),
                    variant: 'error',
                })
            );
            return true;
        }
        return false;
    }
}