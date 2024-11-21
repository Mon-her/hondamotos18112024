import { api, LightningElement, wire } from 'lwc';
import getCartTotals from '@salesforce/apex/fan_B2BCartCtrl.getCartTotals';
import { MessageContext, publish, subscribe, unsubscribe} from 'lightning/messageService';
import CART_CHANGED from '@salesforce/messageChannel/lightning__commerce_cartChanged';
import toDefined from '@salesforce/label/c.fan_ToDefine';

const CREDIT_PAYMENT_CONDITION = 'credito';

export default class FanCartSummary extends LightningElement {

    @api
    recordId;
    /** Labels for compenent added through Experience Builder */
	@api
	cartTotalLabel;
	@api
	grossLabel;
	@api
	discountsLabel;
	@api
	subtotalLabel;
	@api
	freightLabel;
	@api
	IVALabel;
	@api
	valueToFinanceLabel;
	@api
	showValueToFinance;
	@api
	totalToPayLabel;

    /** Fields to display. */
	cartSummary = {};

    /**
     * The isValueToFinanceDisplayable evaluates when it is possible to display valueToFinance.
     * @type {boolean}
     */
    get isValueToFinanceDisplayable() {
        return this.showValueToFinance && this.cartSummary.paymentCondition === CREDIT_PAYMENT_CONDITION;
    }

    get shipValueLabel(){
        return toDefined;
    }

    @wire(MessageContext)
    messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
        this.getTotals();
    }

    subscribeToMessageChannel() {
        if(this.subscription) return;

        this.subscription = subscribe(this.messageContext, CART_CHANGED,
            ({ origin } = {}) => {
                if(origin === 'fanCartContents') {
                    this.getTotals();
                }
            }
        );
    }

    disconnectedCallback() {
        this.unsubscribeFromMessageChannel();
    }

    unsubscribeFromMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    getTotals() {
        getCartTotals({  cartId: this.recordId })
        .then(response => {
            console.log('fetchCartTotals response --> ', response);
            this.cartSummary = response;
            publish(this.messageContext, CART_CHANGED, { origin: 'fanCartSummary', totalAmount: this.cartSummary.totalToPay,  subtotalAmount: this.cartSummary.subtotal  });
        }).catch(error => {
			console.log('Error in fetchCartTotals --> ', error);
        });
    }
}