import { LightningElement, track, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import callUpdateU from '@salesforce/apex/LWCExampleController.callUpdateUser';
import readCSV from '@salesforce/apex/LWCExampleController.readCSVFile';
import title from '@salesforce/label/c.msmEtiqueta';
import boton from '@salesforce/label/c.msmCambiarUsuaios';
import subtitle from '@salesforce/label/c.msmReasignacion';


const columns = [
    { label: 'Documento', fieldName: 'sDocument' }, 
    { label: 'Nuevo Propietario', fieldName: 'sNewOwner' },  
    { label: 'Cuenta', fieldName: 'sAccount' }   
];


export default class ReadCSVFileInLWC extends LightningElement {
    @api recordId;
    @track error;
    @track columns = columns;
    @track data;
    @track showLoadingSpinner = false;
    
    label = {        
        title,
        boton,
        subtitle
    };

    // accepted parameters
    get acceptedFormats() {
        return ['.csv'];
    }
    
    handleUploadFinished(event) {
        // Get the list of uploaded files
        const uploadedFiles = event.detail.files;
        this.showLoadingSpinner = true;
        
        // calling apex class
        readCSV({idContentDocument : uploadedFiles[0].documentId})
        .then(result => {
            window.console.log('result ===> '+result);
            this.data = result;
            this.showLoadingSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exito!!',
                    message: 'Fichero validado correctamente!!!',
                    variant: 'success',
                }),
            );
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: JSON.stringify(error),
                    variant: 'error',
                }),
            );     
        })
       
    }


    @track accounts;
    @track errorU;
    handleUpdateRecords() {
        this.showLoadingSpinner = true;
        callUpdateU()
            .then(result => {
                this.accounts = result;   
                this.showLoadingSpinner = false;             
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!!',
                        message: 'Registros actualizados',
                        variant: 'success',
                    }),
                );
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch(error => {
                this.errorU = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: JSON.stringify(error),
                        variant: 'error',
                    }),
                ); 
            });
          
    }
   
}