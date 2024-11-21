import { LightningElement, wire, track } from "lwc";
import { columnsMotos } from "./columnsMotos";
import { columnsAutos } from "./columnsAutos";
import { loadStyle } from "lightning/platformResourceLoader";
import CustomStaticResource from "@salesforce/resourceUrl/consultarInventario";
import init from "@salesforce/apex/AM_ConsultarInventario.init";
import consultar from "@salesforce/apex/AM_ConsultarInventario.consultar";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ConsultarInventario extends LightningElement {
  productoId;
  concesionarioId;
  defaultConcesionarioId;
  isLoading = false;
  isCSSAppended = false;
  isTablePopulated = false;
  isSearchButtonDisabled = true;
  isConcesionarioDisabled = false;
  isAutosProfile = false;
  defaultDateString = new Date().toISOString().substring(0, 10);
  columns = columnsMotos;
  subfilterColumns = [];
  dataFilterRows = [];
  subfilter = {};
  filteredResults = [];
  isFilterApplied = false;

  autosProductOptions = [];
  autosProduct = "";

  @track
  resultCount = 0;
  @track
  filteredResultCount = 0;

  @track
  searchDatetime = "";

  renderedCallback() {
    this.dateString = this.defaultDateString;
    this.loadStaticResource();
  }

  loadStaticResource() {
    if (this.isCSSAppended) {
      return;
    }
    Promise.all([loadStyle(this, CustomStaticResource)]).then(() => {});
    this.isCSSAppended = true;
  }

  @wire(init) wired(results) {
    if (results && results.data) {
      let data = JSON.parse(JSON.stringify(results.data));
      if (data.Miembro_de_Concesionario__c) {
        this.defaultConcesionarioId =
          data.Miembro_de_Concesionario__c.Concesionario__c;
      }

      this.concesionarioId = this.defaultConcesionarioId;
      this.isConcesionarioDisabled = !data.isEditor;

      
      if (data.isAutosProfile) {
        this.defaultConcesionarioId = null;
        this.concesionarioId = null;
        this.isAutosProfile = true;
        this.isSearchButtonDisabled = false;
        this.columns = columnsAutos;
        let columnsForFilters = [...columnsAutos];
        this.subfilterColumns = columnsForFilters.map((c) => {
          c.editable = true;
          return c;
        });
        this.autosProductOptions = data.autosPricebookEntries.map((p) => {
          return {
            label: p.Product2.Referencia_comercial__c,
            value: p.Product2.Id
          };
        });
        this.dataFilterRows.push(this.genFilterRow());
      }

      this.isMotosProfile = !this.isAutosProfile;
    }
  }

  onChangeProductoCombobox(event) {
    this.productoId = event.detail.value ? event.detail.value : null;
    this.toggleSearchButton();
  }

  onChangeProducto(event) {
    this.productoId = event.detail.length > 0 ? event.detail[0] : null;
    this.toggleSearchButton();
  }

  onChangeConcesionario(event) {
    this.concesionarioId = event.detail.length > 0 ? event.detail[0] : null;
    this.isSearchButtonDisabled = false;
  }

  toggleSearchButton() {
    if (this.isAutosProfile) {
      this.isSearchButtonDisabled = !this.dateString;
    } else {
      this.isSearchButtonDisabled = !this.productoId || !this.dateString;
    }
  }

  onDateChange(event) {
    this.dateString = event.detail;
    this.isSearchButtonDisabled = this.shouldButtonBeDisabled();
  }

  handleClick() {
    this.isLoading = true;

    consultar({
      productoId: this.productoId,
      concesionarioId: this.concesionarioId,
      dateString: this.dateString
    })
      .then((response) => {
        this.handleConsultaResponse(response);
        this.isLoading = false;
      })
      .catch((response) => {
        this.genExceptionObject(response);
        this.isLoading = false;
        this.isSearchButtonDisabled = false;
      });

    this.isTablePopulated = true;
    this.isSearchButtonDisabled = true;
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
        let value = row[key];
        let subfilterValue = subfilter[key];
        let contains = value.indexOf(subfilterValue) > -1;
        self.isFilterApplied = true;
        return contains;
      });
      return match;
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
    let transformedResponse = this.transformResponse(response);
    this.data = transformedResponse;
    this.isTablePopulated = true;

    this.subfilterResults(this.subfilter);
  }

  transformResponse(response) {
    let newResults = response.results;
    if (response.results) {
      if (this.isAutosProfile) {
        newResults = response.results.map((e) => {
          let copy = JSON.parse(JSON.stringify(e));
          copy.vinInterno = e.vinInterno.replace("VH-", "");
          return copy;
        });
      }
    }
    return newResults;
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