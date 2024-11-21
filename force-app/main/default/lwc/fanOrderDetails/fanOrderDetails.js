import { LightningElement, api, wire } from 'lwc';
import getCartDeliveryGroups from '@salesforce/apex/fan_B2BCartCtrl.getCartDeliveryGroups';
import { orderDetailsLabels } from 'c/fanLabels';

export default class FanOrderDetails extends LightningElement {

	@api
	recordId;

	cartDeliveryGroups = [];
	activeAccordionSections = [];

	connectedCallback(){
		this.fetchCartDeliveryGroups();
	}

	fetchCartDeliveryGroups() {
		getCartDeliveryGroups({ 
			orderSummaryOrCartId: this.recordId 
		}).then(response => {
			this.cartDeliveryGroups = response;
			this.activeAccordionSections = this.cartDeliveryGroups.map((cartDeliveryGroup) => cartDeliveryGroup.Id);
		}).catch(error => {
			console.log('Error in fetchCartDeliveryGroups --> ', error);
		});
	}

	// Get the labels to display.
	get label() {
		return orderDetailsLabels();
	}
}