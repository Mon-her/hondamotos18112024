import { LightningElement, api, wire, track } from 'lwc';
import getDocumento from "@salesforce/apex/lwcHojaVidaVehiculo.getNoDocumento";
import getVehiculo from "@salesforce/apex/lwcHojaVidaVehiculo.getVehiculo";
import { loadStyle } from "lightning/platformResourceLoader";
import CustomStaticResource from "@salesforce/resourceUrl/hojaVidaVehiculo";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class HojaVidaVehiculo extends LightningElement {
    //@api recordId;
    data;
    showLoadingSpinner = false;
    noDocumento = '';
    placa = '';
    error;
    isCSSAppended = false;
    @api recordId;
    columns = [
       
      {
            label: "VIN",
            fieldName: "vin",
            hideDefaultActions: true,
            initialWidth: 150,
            //type: 'url',
            //typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}
        },
        {
          label: "Año",
          fieldName: "anio",
          hideDefaultActions: true
        },
        {
          label: "Línea",
          fieldName: "linea",
          hideDefaultActions: true,
          initialWidth: 120,
        },
        {
          label: "Numero orden",
          fieldName: "noOrden",
          hideDefaultActions: true,
          initialWidth: 120,
        },
       
          {
            label: "Servicios realizados",
            fieldName: "servicio",
            hideDefaultActions: true
          },
          
          {
            label: "Fechas de servicio",
            fieldName: "fechaServicio",
            hideDefaultActions: true,
            type: "date-local",
            typeAttributes:{
                month: "2-digit",
                day: "2-digit"
            },
            initialWidth: 120,
          },
          {
            label: "Descripción",
            fieldName: "descripcion",
            hideDefaultActions: true,
            initialWidth: 80,
          },
          {
            label: "Repuestos",
            fieldName: "repuestos",
            hideDefaultActions: true
          },
          {
            label: "Kilometraje",
            fieldName: "kilometraje",
            hideDefaultActions: true
          },
          {
            label: "Tipo de documento",
            fieldName: "tipoDocumento",
            hideDefaultActions: true
          },
          {
            label: "Numero de documento",
            fieldName: "noDocumento",
            hideDefaultActions: true,
            initialWidth: 80,
          },
          {
            label: "Nombre (s)",
            fieldName: "nombres",
            hideDefaultActions: true
          },
          {
            label: "Apellido (s)",
            fieldName: "apellidos",
            hideDefaultActions: true
          },
          {
            label: "Celular",
            fieldName: "celular",
            hideDefaultActions: true,
            type: 'phone',
            initialWidth: 80,
          },
          {
            label: "Email",
            fieldName: "email",
            hideDefaultActions: true,
            type: 'email'
          },
          {
            label: "Concesionario",
            fieldName: "concesionario",
            hideDefaultActions: true
          },
          {
            label: "Agencia",
            fieldName: "agencia",
            hideDefaultActions: true
          },
          {
            label: "Placa",
            fieldName: "placa",
            hideDefaultActions: true
          }
          
      ];


    hojaVidaFiltros = [
      
        {
          label: "Línea",
          fieldName: "linea",
          hideDefaultActions: true
        },
        {
          label: "Número de Orden",
          fieldName: "noOrden",
          hideDefaultActions: true
        },
        {
          label: "Fecha de Servicio",
          fieldName: "fechaServicio",
          hideDefaultActions: true,
          type: "date-local",
        },
        {
          label: "Concesionario",
          fieldName: "concesionario",
          hideDefaultActions: true
        },
      ];
    
      
    subfilterColumns = [];
    dataFilterRows = [];
    subfilter = {};
    filteredResults = [];
    isFilterApplied = false;

    obtenerDocumento(){
      getDocumento({ idCaso: this.recordId })
      .then(result => {
          window.console.log('result ===> '+result);
          this.noDocumento = result;  
      })
      .catch(error => {
          console.log(JSON.stringify(error));
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
          );     
      })
    }
    

      connectedCallback() {
        console.log('connnectedCallBack');
        if (this.recordId!=null) this.obtenerDocumento();

        let columnsForFilters = [...this.hojaVidaFiltros];//[...columnsUsados];
        this.subfilterColumns = columnsForFilters.map((c) => {
          c.editable = true;
          return c;
        });
        this.dataFilterRows.push(this.genFilterRow());
      }

      renderedCallback() {
        console.log('renderedCallback');
        //this.dateString = this.defaultDateString;
        this.loadStaticResource();
      }

      loadStaticResource() {
        if (this.isCSSAppended) {
          return;
        }
        Promise.all([loadStyle(this, CustomStaticResource)]).then(() => {console.log('cargado style');});
        this.isCSSAppended = true;
      }

      handleGetHistorial(event) {
        //event.preventDefault();
        if (!this.noDocumento && !this.placa){
          this.dispatchEvent(
            new ShowToastEvent({
                title: 'Llenar Parámetros!',
                message: 'Ingrese un valor para el Número de Documento o de Placa',
                variant: 'info',
                duration: '10000'
            })
          );  
          return null;
        }
        this.showLoadingSpinner = true;
        console.log(`noDocumento: ${this.noDocumento}. FLEET_NUM: ${this.placa}`);
        getVehiculo({ noDocumento: this.noDocumento, FLEET_NUM: this.placa })
        .then(result => {
            
            window.console.log('result ===> '+result);
            this.data = result;
            this.isTablePopulated = true;
            this.subfilterResults(this.subfilter);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Exito!',
                    message: 'Se han retornado '+ this.data.length +' registros!',
                    variant: 'success',
                    duration: '10000'
                }),
                this.showLoadingSpinner = false,
            );
            //this.dispatchEvent(new CloseActionScreenEvent());
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
            //this.dispatchEvent(new CloseActionScreenEvent());
        })
    }

    handleCerrar(event){
      this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleNoDocumentoChange(event){
      this.noDocumento = event.target.value;
    }

    handlePlacaChange(event){
      this.placa = event.target.value;
    }

    handleCellChange(event) {
      console.log(event);
    }
  
    handleSubFilterCellChange(event) {
      console.log(event);
  
      let keys = Object.keys(event.detail.draftValues[0]).filter(
        (k) => k != "Id" && k != ""
      );
      let key = keys[0];
      let value = event.detail.draftValues[0][key];
  
      if (value === "" || value === undefined) {
        delete this.subfilter[key];
      } else {
        this.subfilter[key] = value;
      }
  
      this.subfilterResults(this.subfilter);
    }
  
    subfilterResults(subfilter) {
      var self = this;
      self.isFilterApplied = false;
  
      let keys = Object.keys(subfilter);
      this.filteredResults = this.data.filter((row) => {
        let match = keys.every((key) => {
          let value = row[key]; console.log(value);
          let subfilterValue = subfilter[key]; console.log(subfilterValue);
          let contains = value && value.toString().indexOf(subfilterValue) > -1;//value.indexOf(subfilterValue) > -1; JP: Thi was Modified to filter currency values, in this case Precio Venta
          self.isFilterApplied = true;
          return contains;
        });
  
        
  
        return match ;
      });
      console.log('this.filteredResults.length',this.filteredResults.length);
      this.filteredResultCount = this.filteredResults.length;
    }

    genFilterRow() {
      return this.columns.map((c) => {
        return "";
      });
    }
  
    onSubFilterSave() {
      console.log(this.dataFilterRows);
    }
  
    onSubFilterCancel() {
      this.subfilter = this.getCurrentTableSubfilters();
      this.subfilterResults(this.subfilter);
    }
  
    getCurrentTableSubfilters() {
      let subfilter = {};
      let row = this.dataFilterRows[0];
      for (let k of row.keys()) {
        let v = row[k];
        if (v === undefined || v === "") {
        } else {
          subfilter[k] = v;
        }
      }
      return subfilter;
    }

    exportarDatos() {
      if (this.data.length <= 0) {
        return;
      }
  
      let cols = this.columns;
  
      let columnHeader = cols.map((c) => c.label);
      let jsonKeys = cols.map((c) => c.fieldName);
  
      var jsonRecordsData = this.data;
      let csvIterativeData = "";
      let csvSeperator = ",";
      let newLineCharacter = "\n";
  
      csvIterativeData += columnHeader.join(csvSeperator);
      csvIterativeData += newLineCharacter;
      for (let i = 0; i < jsonRecordsData.length; i++) {
        let counter = 0;
        for (let iteratorObj in jsonKeys) {
          let dataKey = jsonKeys[iteratorObj];
          if (counter > 0) {
            csvIterativeData += csvSeperator;
          }
          if (
            jsonRecordsData[i][dataKey] !== null &&
            jsonRecordsData[i][dataKey] !== undefined
          ) {
            csvIterativeData += '"' + jsonRecordsData[i][dataKey] + '"';
          } else {
            csvIterativeData += '""';
          }
          counter++;
        }
        csvIterativeData += newLineCharacter;
      }
  
      this.exportarCSV(csvIterativeData, "Resultados Hoja de Vida.csv");
    }

    exportarCSV(csvString, fileName) {
      var blob = new Blob([csvString], { type: "text/plain" });
      if (navigator.msSaveBlob) {
        // IE 10+
        navigator.msSaveBlob(blob, fileName);
      } else {
        var link = document.createElement("a");
        if (link.download !== undefined) {
          // feature detection
          // Browsers that support HTML5 download attribute
          var url = URL.createObjectURL(blob);
          link.setAttribute("href", url);
          link.setAttribute("download", fileName);
          link.style.visibility = "hidden";
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        }
      }
    }
}