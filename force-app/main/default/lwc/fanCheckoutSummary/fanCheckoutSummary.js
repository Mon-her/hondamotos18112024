import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


//Apex methods 
import getCheckoutSummary from '@salesforce/apex/fan_CheckoutSummaryCtrl.getCheckoutSummary';
import getValorAnticipo from '@salesforce/apex/fan_B2BPaymentController.getValorAnticipo';

import isCartAnticipo from '@salesforce/apex/fan_CheckoutSummaryCtrl.isCartAnticipo';

import { FlowNavigationNextEvent } from 'lightning/flowSupport';

//LABELS
import { paymentMethodLabels } from 'c/fanLabels';

export default class FanCheckoutSummary extends LightningElement {

	@api
	recordId;

	@api
	currentState;

	@api
	availableActions = [];

	@api
	titleHeader;
	@api
	shippingHeader;
	@api
	subtotalHeader;
	@api
	taxHeader;
	@api
	totalHeader;

	// Totals.
	subtotal;
	freight;
	estimatedTaxes;
	total;

	//Anticipo
	valorAnticipo;

	//WebCart es Anticipo
	isAnticipo;

	get isButtonVisible(){
		if(this.currentState === 'Checkout Summary' && this.currentState != null){
			return true;
		}
		return false;
	}
	/**
    * The object of labels used in the cmp. 
    * @return {Object}
    */
	get labels() {
		return paymentMethodLabels();
	}

	

	connectedCallback() {
		getCheckoutSummary({ recordId: this.recordId })
		.then(({ subtotal, freight, estimatedTaxes, total }) => {
			this.subtotal = subtotal;
			this.freight = freight;
			this.estimatedTaxes = estimatedTaxes;
			this.total = total;
		}).catch((error) => console.error('Error in getCheckoutSummary -->', error));

		getValorAnticipo({cartId: this.recordId})
		.then((result => {
			this.valorAnticipo = result;
		}))
		.catch(error => console.log('There was an error in getting the anticipo value', error));

		isCartAnticipo({cartId : this.recordId})
		.then((result) => {
			this.isAnticipo = result;
		})
		.catch(error => console.log('There was an error in getting anticipo', error));
	}

	handleNext(){
		if((this.valorAnticipo  >= this.total) && this.isAnticipo == true){ 
			if (this.availableActions.find((action) => action === 'NEXT')) {
				// navigate to the next screen
				const navigateNextEvent = new FlowNavigationNextEvent();
				this.dispatchEvent(navigateNextEvent);
			}
		} else if(this.isAnticipo == false){
			if (this.availableActions.find((action) => action === 'NEXT')) {
				// navigate to the next screen
				const navigateNextEvent = new FlowNavigationNextEvent();
				this.dispatchEvent(navigateNextEvent);
			}
		}else {
			this.handleAlert(this.labels.paymentInAdvanceError.replace('{1}', this.formatearComoPesoColombiano(this.valorAnticipo)),'error');
		}
	}

	handleAlert(title, variant) {
        this.dispatchEvent(
          new ShowToastEvent({
            title,
            variant
          })
        );
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