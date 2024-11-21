import { LightningElement, wire, track } from "lwc";

import { columnsUsados } from "./columnsUsados";
import { columnsUsadosFiltros } from "./columnsUsadosFilters";
import { loadStyle } from "lightning/platformResourceLoader";
import CustomStaticResource from "@salesforce/resourceUrl/consultarInventarioUsados";
//import init from "@salesforce/apex/AM_ConsultarInventarioUsados.init";
import consultar from "@salesforce/apex/AM_ConsultarInventarioUsados.consultar";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import { NavigationMixin } from 'lightning/navigation';

export default class ConsultarInventarioUsados extends NavigationMixin(LightningElement) {
    //sfdcBaseURL;
    
    //productoId;
    //concesionarioId;
    //defaultConcesionarioId;
    //filtros
    precioMenor;
    precioMayor;
    producto;
    anioModelo;
    kilometraje;
    placa;


    isLoading = false;
    isCSSAppended = false;
    isTablePopulated = false;
    //isSearchButtonDisabled = false;//true;
    //isConcesionarioDisabled = false;
    //isAutosProfile = true;//false;
    defaultDateString = new Date().toISOString().substring(0, 10);
    columns = columnsUsados;
    subfilterColumns = [];
    dataFilterRows = [];
    subfilter = {};
    filteredResults = [];
    isFilterApplied = false;

    @track
    resultCount = 0;
    @track
    filteredResultCount = 0;
  
    @track
    searchDatetime = "";
    
    connectedCallback() {
      console.log('connnectedCallBack');
      let columnsForFilters = [...columnsUsadosFiltros];//[...columnsUsados];
      this.subfilterColumns = columnsForFilters.map((c) => {
        c.editable = true;
        return c;
      });
      this.dataFilterRows.push(this.genFilterRow());
    }

    renderedCallback() {
        console.log('renderedCallback');
        //this.sfdcBaseURL = window.location.origin;
        //console.log(this.sfdcBaseURL);
        this.dateString = this.defaultDateString;
        this.loadStaticResource();

        //this.isAutosProfile = true;
        //this.isSearchButtonDisabled = false;
        //this.columns = columnsAutos;

        /*
        let columnsForFilters = [...columnsUsados];
        this.subfilterColumns = columnsForFilters.map((c) => {
          c.editable = true;
          return c;
        });
        this.dataFilterRows.push(this.genFilterRow());
        */
    }
    
    loadStaticResource() {
        if (this.isCSSAppended) {
          return;
        }
        Promise.all([loadStyle(this, CustomStaticResource)]).then(() => {console.log('cargado style');});
        this.isCSSAppended = true;
    }

    handleRowAction(event) {
      if (event.detail.action.name === 'view') {
          //console.log(event);
          //console.log(JSON.stringify(event));
          
          this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
              recordId: event.detail.row.Id,
              actionName: 'view',
            },
        });
      }
  }
  /*  
  @wire(init) wired(results) {
    if (results && results.data) {
      let data = JSON.parse(JSON.stringify(results.data));

      if (data.Miembro_de_Concesionario__c) {
        this.defaultConcesionarioId =
          data.Miembro_de_Concesionario__c.Concesionario__c;
      }

      this.concesionarioId = this.defaultConcesionarioId;
      this.isConcesionarioDisabled = !data.isEditor;

      if (true) {
        //if (data.isAutosProfile) { // TODO: must uncomment!
        this.isAutosProfile = true;
        this.isSearchButtonDisabled = false;
        this.columns = columnsAutos;
        let columnsForFilters = [...columnsAutos];
        this.subfilterColumns = columnsForFilters.map((c) => {
          c.editable = true;
          return c;
        });
        this.dataFilterRows.push(this.genFilterRow());
      }

      this.isMotosProfile = !this.isAutosProfile;
    }
  }*/
    onChangePrecioMenor(event){
        this.precioMenor = event.detail.value ? event.detail.value : undefined;
    }
    onChangePrecioMayor(event){
        this.precioMayor = event.detail.value ? event.detail.value : undefined;
    }
    onChangeProducto(event){
        this.producto = event.detail.value;
    }
    onChangeAnioModelo(event){
        this.anioModelo = event.detail.value ? event.detail.value : undefined;
    }
    onChangeKilometraje(event){
        this.kilometraje = event.detail.value ? event.detail.value : undefined;
    }
    onChangePlaca(event){
        this.placa = event.detail.value;
    }
/*
  onChangeProducto(event) {
    this.productoId = event.detail.length > 0 ? event.detail[0] : null;
    this.toggleSearchButton();
  }

  onChangeConcesionario(event) {
    this.concesionarioId = event.detail.length > 0 ? event.detail[0] : null;
    this.isSearchButtonDisabled = false;
  }

  onDateChange(event) {
    this.dateString = event.detail;
    this.isSearchButtonDisabled = this.shouldButtonBeDisabled();
  }
*/
/*
  toggleSearchButton() {
    if (this.isAutosProfile) {
      this.isSearchButtonDisabled = !this.dateString;
    } else {
      this.isSearchButtonDisabled = !this.productoId || !this.dateString;
    }
  }
*/
  handleClick() {
    this.isLoading = true;
    console.log('cliqueado Buscar');
    consultar({
        precioMenor: this.precioMenor,
        precioMayor: this.precioMayor,
        producto: this.producto,
        anioModelo: this.anioModelo,
        kilometraje: this.kilometraje,
        placa: this.placa
    })
      .then((response) => {
        //this.handleConsultaResponse(response);
        //this.isLoading = false;

        this.searchDatetime = new Date();

    
        this.resultCount = response.length;
        //this.isSearchButtonDisabled = false;

        let tempUsadosList = []; 
            
        response.forEach((record) => {
            let tempUsadoRec = Object.assign({}, record);  
            //tempUsadoRec.AutoNumero = `/lightning/r/${tempUsadoRec.Id}/view`;//this.sfdcBaseURL + '/hondaautos/s/detail/' + tempUsadoRec.Id;
            tempUsadosList.push(tempUsadoRec);
            
        });
        
        this.data = tempUsadosList;
        //console.table(this.data);
        //this.data = response;
        this.isTablePopulated = true;
        this.subfilterResults(this.subfilter);
        this.isLoading = false;
      })
      .catch((response) => {
        
        this.resultCount = 0;

        this.isLoading = false;
        console.log(response);
        const evt = new ShowToastEvent({
            title: "La consulta ha fallado",
            message: response.body.message,//response.msg,
            variant: "error",
            mode: "sticky"
          });
          this.dispatchEvent(evt);
      });

    this.isTablePopulated = true;
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

      //let notFacturado = row.Estado_Del_Vehiculo__c != "FACTURADO";

      return match; //&& notFacturado;
    });

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

  shouldButtonBeDisabled() {
    if (this.isAutosProfile) {
      return !this.dateString;
    }

    return !this.productoId || !this.dateString;
  }
/*
  handleConsultaResponse(response) {
    this.searchDatetime = new Date();

    if (response.code === "OK") {
      this.resultCount = response.results.length;
      this.handleConsultaResponseSuccess(response);
    } else {
      this.resultCount = 0;
      this.handleConsultaResponseFailure(response);
      this.isSearchButtonDisabled = false;
    }
  }

  handleConsultaResponseSuccess(response) {
    response = this.transformResponse(response);
    this.data = response.results;
    this.isTablePopulated = true;

    this.subfilterResults(this.subfilter);
  }

  transformResponse(response) {
    let newResults = [];
    if (response.results) {
    }
    return response;
  }

  handleConsultaResponseFailure(response) {
    const evt = new ShowToastEvent({
      title: "La consulta ha fallado",
      message: response.msg,
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(evt);
  }

  genExceptionObject(result) {
    console.log("genExceptionObject: ", result);
    let errorTitle = "Server: " + result.body.exceptionType;
    let errorMessage = result.body.message + ": " + result.body.stackTrace;

    const evt = new ShowToastEvent({
      title: errorTitle,
      message: errorMessage,
      variant: "error",
      mode: "sticky"
    });
    this.dispatchEvent(evt);
  }
*/
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

    this.exportarCSV(csvIterativeData, "Resultados Consulta Inventario.csv");
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

  handleToggleSection(event) {
    // evento cuando se hace click en pestaña del acordión
  }
}