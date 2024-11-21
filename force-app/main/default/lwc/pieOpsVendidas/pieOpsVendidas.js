import { LightningElement, track, wire } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import chartjs2 from '@salesforce/resourceUrl/Chartjs294';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Segmentos from '@salesforce/label/c.GraphSegmentosOpsVendidos';
import Colores from '@salesforce/label/c.GraphSegmentosOpsVendidosColores';
import TituloGrafico from '@salesforce/label/c.GraphPieTitle';
import reportId from '@salesforce/label/c.ReporteOpsVendidasVistaJefe';
import ColorDataLabels from '@salesforce/label/c.GraphSegmentosColorDataLablesOpsVendidos';
//import { refreshApex } from '@salesforce/apex';
import usuariosXSegmento from '@salesforce/apex/clsGraphOpsVendidas.getUsuariosXSegmento'; 
import getTotalUsuarios from '@salesforce/apex/clsGraphOpsVendidas.getTotalUsuarios'; 
import { NavigationMixin } from 'lightning/navigation';
//export default class PieOpsVendidas extends LightningElement {
export default class PieOpsVendidas extends NavigationMixin(LightningElement) {
    @track isChartJsInitialized;
    //@wire(usuariosXSegmento) datosGrafico;
    @track datosGrafico;
    @track error;
    @track errorTotalUsuarios;
    totalUsuarios;
    
    url;
    label = {
        TituloGrafico,
        Segmentos,
        Colores
    }
    renderedCallback(){
        

        if (this.isChartJsInitialized) {
            let valoresSegmentos = Segmentos.split(';');
            let etiquetas = Segmentos.split(';');
            for (let i=0;i<etiquetas.length;i++) {
                if (i === etiquetas.length - 1)
                    etiquetas[i] = 'Rango ' + (i + 1) + ' >= ' + (Number(valoresSegmentos[i-1]) + 1) + ': ' + this.datosGrafico[i];
                else{
                    if (i == 0) etiquetas[i] = 'Rango ' + (i + 1) +' de 1 a ' + etiquetas[i] + ': ' + this.datosGrafico[i];
                    else etiquetas[i] = `Rango ${Number(i+1)} de ${Number(valoresSegmentos[i -1]) +1} a ${valoresSegmentos[i]} : ${this.datosGrafico[i]}`;
                }
                    //etiquetas[i] = '<= ' + etiquetas[i] + ': ' + this.datosGrafico[i];
            }

            //alert(etiquetas);
            //let datos;
            this.loadChart(Colores.split(';'), etiquetas, this.datosGrafico);
        }
        //this.isChartJsInitialized=true;
        loadScript(this, chartjs)//2 + '/Chart.min.js')
        .then(() => {
            loadScript(this, chartjs2 + '/chartjs-plugin-datalabels.js')
            .then(() => {
                usuariosXSegmento()
                .then(result => {
                    this.datosGrafico = result;
                    
                    

                    //this.isChartJsInitialized = true;

                    getTotalUsuarios()
                        .then(result => {
                            this.totalUsuarios = result;
                            //this.tostar('totalUsuarios','result: ' + result);
                            this.isChartJsInitialized = true;
                        })
                        .catch(error => {
                            this.errorTotalUsuarios = error;
                            this.tostar('Error totalUsuarios',this.errorTotalUsuarios);
                        });
                })
                .catch(error => {
                    this.error = error;
                    alert(error);
                });
            }).catch(err => alert(err))


            
            
            
        }).catch(err => alert(err));
        
    }

    loadChart(colores, etiquetas, datos){
        var canvas = this.template.querySelector('canvas.chart');//document.getElementById("oilChart");

        Chart.defaults.global.defaultFontFamily = "Lato";
        Chart.defaults.global.defaultFontSize = 15;
        Chart.defaults.global.legend.position = 'left';
        const event = new ShowToastEvent({
            title: 'Mensaje',
            message: 'hola de nuevo',
        });
        //this.dispatchEvent(event);
        var oilData = {
            labels: etiquetas,
            //labels: [
            //    "Saudi Arabia",
            //    "Russia",
            //    "Iraq",
            //    "United Arab Emirates",
            //    "Canada"
            //],
            datasets: [
                {
                    data: datos,//[133.3, 86.2, 52.2, 51.2, 50.2,12],//[133.3, 86.2, 52.2, 51.2, 50.2],
                    backgroundColor: colores
                    //backgroundColor: [
                    //    "#FF6384",
                    //    "#63FF84",
                    //    "#84FF63",
                    //    "#8463FF",
                    //    "#6384FF"
                    //]
                }]
        };

        var pieChart = new Chart(canvas, {
        type: 'pie',
        data: oilData,


        options: {
            responsive: true,
            maintainAspectRatio: true,
            title: {
              display: false,//true,
              text: 'Total de usuarios a Cargo: 20',
              fontStyle: 'bold',
              fontSize: 20
            },
            plugins: {
                datalabels: {
                    display: true,
                    align: 'bottom',
                    //backgroundColor: '#ccc',
                    borderRadius: 3,
                    font: {
                      size: 30,//25,
                      Style: 'bold'
                    },
                    color: ColorDataLabels,
                }
            },
            tooltips: {
              callbacks: {
                // this callback is used to create the tooltip label
                label: function(tooltipItem, data) {
                  // get the data label and data value to display
                  // convert the data value to local string so it uses a comma seperated number
                  var dataLabel = data.labels[tooltipItem.index];
                  var value = ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index].toLocaleString();
        
                  // make this isn't a multi-line label (e.g. [["label 1 - line 1, "line 2, ], [etc...]])
                  if (Chart.helpers.isArray(dataLabel)) {
                    // show value on first line of multiline label
                    // need to clone because we are changing the value
                    dataLabel = dataLabel.slice();
                    //dataLabel[0] += value;
                  } else {
                    //dataLabel += value;
                  }
        
                  // return the text to display on the tooltip
                  return dataLabel;
                }
              }
            }
            
        }


        });
    }

    
    verReporte(event) {
        // Make sure the event is only handled here
        event.stopPropagation();
    
        // Navigate to the Report.
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: reportId,//recordId: this.settings.businessStrikesReportId,
                objectApiName: 'Report',
                actionName: 'view'
            },
            //state: { 
            //    fv0: this.account.data.fields.Id.value,
            //   fv1: event.target.dataset.id
            //} 
        }).then(url => { window.open(url) });
    }

    tostar(titulo, mensaje){
        const event = new ShowToastEvent({
            title: titulo,
            message: mensaje,
        });
        this.dispatchEvent(event);
    }
}