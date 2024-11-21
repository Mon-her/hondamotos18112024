import { LightningElement, track,wire } from 'lwc';
import getDatos from '@salesforce/apex/clsMotosVentasAyer.getDatos';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import reportId from '@salesforce/label/c.ReporteOpsVendidasAyer';
export default class MotosVentasAyer extends NavigationMixin(LightningElement) {
    totalVentasAyer;
    @track errortotalVentasAyer;
    datos;

    renderedCallback(){
        const style = document.createElement('style');
        //style.innerText = `c-motos-ventas-mes-pasado .slds-card__body, .slds-card__footer {
        style.innerText = `c-motos-ventas-ayer .slds-card {
            background-color: #091b3e; //background-color: #54C2B2;
            color: white;
            font-family: "SalesforceSans-Regular", Arial, sans-serif;
        }`;
        this.template.querySelector('lightning-card').appendChild(style);

        getDatos()
        .then(result => {
            this.datos = result;
            console.log(this.datos);
            this.datos= JSON.parse(this.datos);
            this.totalVentasAyer = this.datos.totalOppsYestarday.toLocaleString(); 
        })
        .catch(error => {
            this.errortotalVentasAyer = error;
            console.log(error);
            this.tostar('Error al Obtener los Datos',error);
        });
    }



    verReporte(event) {
        // Make sure the event is only handled here
        event.stopPropagation();
    
        // Navigate to the Report. Ventas_del_Mes_Pasado
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: reportId, 
                objectApiName: 'Report',
                actionName: 'view'
            },
            state: { 
                fv0: this.datos.codigosConcesionariosUsuario.join(','),
            //   fv1: event.target.dataset.id
            } 
        }).then(url => { window.open(url) });
    }

    tostar(titulo, mensaje){
        const event = new ShowToastEvent({
            title: titulo,
            message: mensaje.toString(),
        });
        this.dispatchEvent(event);
    }
}