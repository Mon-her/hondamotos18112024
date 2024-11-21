import { LightningElement, track,wire } from 'lwc';
//import getOppsLastMonth from '@salesforce/apex/clsMotosVentasMesPasado.getOppsLastMonth';
//import getTotalOppsLastMonth from '@salesforce/apex/clsMotosVentasMesPasado.getTotalOppsLastMonth';
import getDatos from '@salesforce/apex/clsMotosVentasMesPasado.getDatos';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import reportId from '@salesforce/label/c.ReporteOpsVendidasMesPasado';
export default class MotosVentasMesPasado extends NavigationMixin(LightningElement) {
    totalVentasMesPasado;
    @track errorTotalVentasMesPasado;
    datos;

    renderedCallback(){
        const style = document.createElement('style');
        //style.innerText = `c-motos-ventas-mes-pasado .slds-card__body, .slds-card__footer {
        style.innerText = `c-motos-ventas-mes-pasado .slds-card {
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
            this.totalVentasMesPasado = this.datos.totalOppsLM.toLocaleString(); 

            //let algo = this.datos.codigosConcesionariosUsuario.join(',');
            //console.log(algo);
            
        })
        .catch(error => {
            this.errorTotalVentasMesPasado = error;
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
                recordId: reportId, //'00O1F000001SY9UUAW',//reportId,//recordId: this.settings.businessStrikesReportId,
                objectApiName: 'Report',
                actionName: 'view'
            },
            state: { 
                //fv0: 'CEIBA,Florencia,CEIBA,Florencia,CEIBA,Florencia,Italia1,Italia2,Italia3,Italia4,Italia5,Italia6,Italia7,Italia8,Italia9,Italia10,Italia11,Italia12,Italia13,Italia14,Italia15,Italia16', //&fv0=CEIBA%2Cflorencia
                fv0: this.datos.codigosConcesionariosUsuario.join(','),
            //   fv1: event.target.dataset.id
            } 
        }).then(url => { window.open(url) });
    }
    /*
    verDatos(event) {
        // Make sure the event is only handled here
        event.stopPropagation();
    
        // Navigate to the Report. Ventas_del_Mes_Pasado
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Ventas_del_Mes_Pasado'
            },
           
        }).then(url => { window.open(url) });
    }
    */
    tostar(titulo, mensaje){
        const event = new ShowToastEvent({
            title: titulo,
            message: mensaje.toString(),
        });
        this.dispatchEvent(event);
    }
}