import { api, LightningElement, wire } from 'lwc';

import getOrderInformation from '@salesforce/apex/fan_B2BOrderSummaryCtrl.getOrderInformation';
import getPaymentExpirationDate from '@salesforce/apex/fan_B2BOrderSummaryCtrl.getPaymentExpirationDate';

import cashPaymentTemplate from './fanCashPayment.html';
import orderStatusValidationTemplate from './fanOrderStatusValidation.html';

export default class FanOrderStatusValidation extends LightningElement {

	@api
	orderSummaryId;

	@api
	get orderStatus() {
		return this._orderStatus;
	}

	set orderStatus(value) {
		this._orderStatus = value.split(';')
		.reduce((accumulator, orderStatus) => { // Generate key(Order status) and content(Text to display).
			const [status, content] = orderStatus.split(':');

			accumulator[status] = content;
			return accumulator;
		}, {});
	}

	@api
	get backgroundColor() {
		return this._backgroundColor;
	}

	set backgroundColor(value) {
		this._backgroundColor = `background-color: ${value};`;
	}

	@api
	get fontColor() {
		return this._fontColor;
	}
	set fontColor(value) {
		this._fontColor = `color: ${value};`;
	}

	@api
	get fontSize() {
		return this._fontSize;
	}

	set fontSize(value) {
		this._fontSize = `font-size: ${value}px;`;
	}

	get isValidStatus() {
		return Object.prototype.hasOwnProperty.call(this.orderStatus, this.fetchedOrderStatus);
	}

	get isMessageViewable() {
		return Object.prototype.hasOwnProperty.call(this.orderStatus, this.fetchedOrderStatus);
	}

	get message() {
		return this.orderStatus[this.fetchedOrderStatus];
	}

	get messageStyle() {
		return `${this.backgroundColor} ${this.fontColor} ${this.fontSize}`;
	}

    get urlReturn() {
		const { origin, pathname } = new URL(window.location.href);
        return origin + pathname;
    }

	_orderStatus;
	_backgroundColor;
	cartId;
	_fontColor;
	_fontSize;
	fetchedOrderStatus;
	isLoading;
	paymentDate;
	paymentTime;
	paymentMethod;

	@wire(getOrderInformation, { orderSummaryId: '$orderSummaryId' } )
	getOrderInformation({error, data}) {
		if (data) {
			const { cartId, orderSummaryStatus, paymentMethod } = data;
			this.fetchedOrderStatus = orderSummaryStatus;
			this.cartId = cartId;
			this.paymentMethod = paymentMethod;

			if(this.message === 'CashPaymentTemplate') {
				// eslint-disable-next-line @lwc/lwc/no-async-operation
				this.timeoutID = setTimeout(this.executePayment.bind(this), 30000);
			}
		} else if (error) {
			console.log('Error in getOrderSummary -->', error);
		}
	}

	@wire(getPaymentExpirationDate, { orderSummaryId: "$orderSummaryId" })
	getExpirationDateForPayment({ data, error }) {
		if(data) {
			const [paymentDate, paymentTime] = data.split(';');

			this.paymentDate = paymentDate;
			this.paymentTime = paymentTime;
		} else if(error) {
			console.log('Error in getExpirationDateForPayment -->', error);
		}
	}

	async executePayment() {
		try {
			this.isLoading = true;
			await this.template.querySelector('c-fan-payzen-form').submitForm();
		} catch (error) {
			this.isLoading = false;
			console.log('Error in executePayment -->', error);
		}
	}

	handlePayClick() {
		clearTimeout(this.timeoutID);
		this.executePayment();
	}

	render() {
		return this.message === 'CashPaymentTemplate' ? cashPaymentTemplate : orderStatusValidationTemplate;
	}
}