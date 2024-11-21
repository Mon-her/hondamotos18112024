import { LightningElement, track, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
//import callUpdateU from '@salesforce/apex/LWCExampleController.callUpdateUser';
import procesarAccts from '@salesforce/apex/ChangeAccountOwnerCSV.processAccounts';
import readCSV from '@salesforce/apex/ChangeAccountOwnerCSV.readCSVFile';
import title from '@salesforce/label/c.lwc_CAOCSV_Titulo';
import boton from '@salesforce/label/c.lwc_CAOCSV_Boton';
import subtitle from '@salesforce/label/c.lwc_CAOCSV_Subtitulo';


const columns = [
    //{ label: 'Documento', fieldName: 'sDocument' }, 
    //{ label: 'Nuevo Propietario', fieldName: 'sNewOwner' },  
    //{ label: 'Cuenta', fieldName: 'sAccount' }   
    { label: 'Documento', fieldName: 'numeroDocumento',sortable: true },   
    { label: 'Cuenta Nombre', fieldName: 'accountName' ,sortable: true},   
    { label: 'Cuenta Id', fieldName: 'accountId' },   
    { label: 'Cuenta Propietario', fieldName: 'oldOwner',sortable: true },   
    { label: 'Nuevo Propietario', fieldName: 'newOwner' ,sortable: true},   
    { label: 'Nuevo Propietario Id', fieldName: 'newOwnerId' }   
];


export default class ChangeAccountOwnerCSV extends LightningElement {
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
        try {
            // Get the list of uploaded files
            const uploadedFiles = event.detail.files;
            this.showLoadingSpinner = true;
            console.log('ploadedFiles[0].documentId: ' + uploadedFiles[0].documentId);
            // calling apex class
            readCSV({idContentDocument : uploadedFiles[0].documentId})
            .then(result => {
                window.console.log('result ===> '+result);
                this.data = result;
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Exito!!',
                        message: 'Archivo validado correctamente!!!',
                        variant: 'success',
                    }),
                );
            })
            .catch(error => {
                this.error = error;
                console.log(error);
                let strError = error.body!=null ? JSON.stringify(error.body.message) : JSON.stringify(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: strError,//JSON.stringify(error),
                        variant: 'error',
                    }),
                );     
            })
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: JSON.stringify(error),
                    variant: 'error',
                }),
            );  
            console.log(JSON.stringify(error));
        }
        
       
    }


    @track accounts;
    @track errorU;
    handleUpdateRecords() {
        this.showLoadingSpinner = true;
        procesarAccts({lstDatosCuentas : this.data})
            .then(result => {
                //this.accounts = result;   
                console.log(result);
                this.showLoadingSpinner = false;    
                let mensaje = `Cuentas a Procesar: ${result.nCuentas} \n ||
                    Contactos a Procesar: ${result.nContactos} \n ||
                    Cuentas Relacionadas a Procesar: ${result.nCuentasRelacionadas} \n ||
                    Tareas a Procesar: ${result.nTareas} \n ||
                    Oportunidades a Procesar: ${result.nOportunidades}`;         
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!!',
                        message: mensaje,//'Registros Procesándose',
                        variant: 'success',
                    }),
                );
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch(error => {
                this.errorU = error;
                console.log(error);
                let strError = error.body!=null ? JSON.stringify(error.body) : JSON.stringify(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: strError,//JSON.stringify(error),
                        variant: 'error',
                    }),
                ); 
            });
          
    }

    
   
}