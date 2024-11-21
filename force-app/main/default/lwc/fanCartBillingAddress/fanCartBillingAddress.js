import { LightningElement, api } from 'lwc';

import { addressesLabels } from 'c/fanLabels';

import getCartDeliveryGroupByCartId from '@salesforce/apex/fan_CartBillingAddressController.getCartDeliveryGroupByCartId';

export default class FanCartBillingAddess extends LightningElement {

    shippingAddresses = [];
    shippingAddressIds = [];

    @api cartId = '';

    get label(){
        return addressesLabels();
    }

    connectedCallback(){
        this.getCartDeliveryGroup();
    }

    getCartDeliveryGroup(){
        getCartDeliveryGroupByCartId({
            cartId: this.cartId
        }).then(data => {
            this.shippingAddresses = data.map((cartDeliveryGroup) => ({ label: cartDeliveryGroup.Name, value: cartDeliveryGroup.Id }));
            this.shippingAddressIds = data.map((cartDeliveryGroup) => cartDeliveryGroup.Id);
            console.log('Shipping Addresses object -->', this.shippingAddresses);

        }).catch(error => {
            console.log('Error in getCartDeliveryGroupByCartId --> ', error);
        });
    }
}