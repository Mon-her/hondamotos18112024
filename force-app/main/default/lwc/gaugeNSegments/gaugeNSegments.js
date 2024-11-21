import { LightningElement, track, wire } from 'lwc';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import chartjs2 from '@salesforce/resourceUrl/Chartjs294';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Segmentos from '@salesforce/label/c.GraphSegmentosOpsVendidos';
import Colores from '@salesforce/label/c.GraphSegmentosOpsVendidosColores';
import BGDataLabels from '@salesforce/label/c.GraphSegmentosBGDataLablesOpsVendidos';
import ColorDataLabels from '@salesforce/label/c.GraphSegmentosColorDataLablesOpsVendidos';
import TituloGrafico from '@salesforce/label/c.GraphGaugeTitle';


import opsVendidas from '@salesforce/apex/clsGraphOpsVendidas.getOpsVendidas'; 
import reportId from '@salesforce/label/c.ReporteOpsVendidasVistaUsuario';
import { NavigationMixin } from 'lightning/navigation';
//import chartBundle from '@salesforce/resourceURL/Chartjs294/Chart.bundle.min.js';
//import chartGauge from '@salesforce/resourceURL/Chartjs294/chartjs-gauge.js';
//import chartDataLabel from '@salesforce/resourceURL/Chartjs294/chartjs-plugin-datalabels.js';
export default class GaugeNSegments extends NavigationMixin(LightningElement) {
//export default class GaugeNSegments extends LightningElement {
    @track isChartJsInitialized;
    chart;

    label = {
        TituloGrafico,
        Segmentos,
        Colores,
        BGDataLabels
        
    }

    @wire(opsVendidas) opis;
    
    loadChart(valor){
        //const event = new ShowToastEvent({
        //    title: 'Mensaje',
        //    message: 'valor:' + valor,
        //});
        //this.dispatchEvent(event);
        let datos = Segmentos.split(';');
        let config = {
            type: 'gauge',
            data: {
                //labels: ['Success', 'Warning', 'Warning', 'Error'],
                datasets: [{
                    data: datos,
                    value: valor,
                    backgroundColor: Colores.split(';'),
                    borderWidth: 2
                }]
            },
            options: {
            responsive: true,
            title: {
                display: false,//true,
                text: 'Indicador de Progreso: Oportunidades Vendidas vs Meta Mensual'//'Gauge chart with datalabels plugin'
            },
            layout: {
                padding: {
                bottom: 30
                }
            },
            needle: {
                // Needle circle radius as the percentage of the chart area width
                radiusPercentage: 2,
                // Needle width as the percentage of the chart area width
                widthPercentage: 3.2,
                // Needle length as the percentage of the interval between inner radius (0%) and outer radius (100%) of the arc
                lengthPercentage: 80,
                // The color of the needle
                color: 'rgba(0, 0, 0, 1)'
            },
            valueLabel: {
                formatter: Math.round ,
                fontSize: 20,
                //formatter: function (value, context) {
                //    return  Math.round(value) /1000 + ' k';
                //},
                //color: ColorDataLabels,//'rgba(255, 255, 255, 1.0)',
                //backgroundColor: 'rgba(255, 255, 255, 1.0)',//'rgba(0, 0, 0, 1.0)',
            },
            plugins: {
                datalabels: {
                    display: true,
                    formatter: function (value, context) {
                        //if (value == datos[datos.length -1])
                        if (context.dataIndex == datos.length -1)
                            return '>= ' + Math.round(Number(datos[datos.length - 2])+1);
                        else{
                            if (context.dataIndex == 0) return '1 a ' + Math.round(value);
                            else return `${Number(datos[context.dataIndex -1]) +1} a ${value}`; //'Entre datos[datos.length -1] ' + Math.round(value);//value;//'< ' + Math.round(value) /1000 + ' k';//Math.round(value);
                        }
                        //return '<= ' + Math.round(value);//value;//'< ' + Math.round(value) /1000 + ' k';//Math.round(value);    
                            
                    },
                    //color: function (context) {
                    //    return context.dataset.backgroundColor;
                    //},
                    color: ColorDataLabels,//'rgba(255, 255, 255, 1.0)',
                    backgroundColor: BGDataLabels,//'rgba(255, 255, 255, 1.0)',//'rgba(0, 0, 0, 1.0)',
                    borderWidth: 0,
                    borderRadius: 5,
                    font: {
                        weight: 'bold',
                        size: 17,
                    }
                }
            }
            }
        };

        const ctx = this.template.querySelector('canvas.gauge').getContext('2d');
        this.chart = new Chart(ctx, config);
        this.chart.canvas.parentNode.style.height = '100%';
        this.chart.canvas.parentNode.style.width = '100%';
        
    }

 
    renderedCallback() {
        
        //const event = new ShowToastEvent({
        //    title: 'Mensaje',
        //    message: 'this.opis.data:' + this.opis.data,
        //});
        //this.dispatchEvent(event);
        if ( this.opis.data==null || this.opis.data==undefined ){
        
            return;
        }
        this.isChartJsInitialized=true; 
        
        loadScript(this, chartjs)
        .then(() => {
            loadScript(this, chartjs2 + '/chartjs-gauge.js')
            .then(() => {
                loadScript(this, chartjs2 + '/chartjs-plugin-datalabels.js')
                .then(()=>{
                    this.loadChart(this.opis.data);
                })
            }).catch(err => alert(err))
        }).catch(err => alert(err));
        


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
        }).then(url => { window.open(url) });
    }
}