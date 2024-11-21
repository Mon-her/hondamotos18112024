import { LightningElement, api , wire, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import updateOwner from '@salesforce/apex/ChangeAccountOwner.changeOwner';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ChangeAccountOwner extends LightningElement {
    @api recordId;
    @api objectApiName;
    newAutosOwner;
    @track error;
    @track data;
    @track showLoadingSpinner = false;

    handleSubmitButton(event) {
        //event.preventDefault();
        this.showLoadingSpinner = true;
        //console.log('handleSubmitButton');
        console.log(`recordId: ${this.recordId}. newAutosOwner: ${this.newAutosOwner}`);
        updateOwner({ accountId: this.recordId, newOwner: this.newAutosOwner })
        .then(result => {
            
            window.console.log('result ===> '+result);
            this.data = result;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exito!',
                    message: 'Se ha actualizado el dueño de la Cuenta y sus registros relacionados con exito!',
                    variant: 'success',
                    duration: '10000'
                }),
                this.showLoadingSpinner = false,
            );
            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            console.log(JSON.stringify(error));
            console.log(error);
            this.error = error;
            let mensaje;
            if (error.body != undefined && error.body.message!=null) mensaje = error.body.message;
            else mensaje = JSON.stringify(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: mensaje,
                    variant: 'error',
                    duration: '10000'
                }),
                this.showLoadingSpinner = false,
            );     
            this.dispatchEvent(new CloseActionScreenEvent());
        })
    }

    handleCancel(event) {
        // Add your cancel button implementation here
        this.dispatchEvent(new CloseActionScreenEvent());
     }

    handleChangedAutosOwner(event){
        //console.log('handleChangedAutosOwner');
        this.newAutosOwner = event.target.value;
        //console.log(`newAutosOwner: ${this.newAutosOwner}`);
    }
}