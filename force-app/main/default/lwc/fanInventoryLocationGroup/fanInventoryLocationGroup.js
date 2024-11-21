import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { inventoryLabels } from 'c/fanLabels';

import getAvailabilityOfRelatedProducts from '@salesforce/apex/fan_OCIGetAvailability.getAvailabilityOfRelatedProducts';
import getRelatedProductsWithAvailability from '@salesforce/apex/fan_OCIGetAvailability.getRelatedProductsWithAvailability';
import getAvailabilityForRedInventory from '@salesforce/apex/fan_OCIGetAvailability.getAvailabilityForRedInventory';
import getLocationByCity from '@salesforce/apex/fan_OCIGetAvailability.getLocationByCity';
import getShippingAddressList from '@salesforce/apex/fan_B2BAccountCtrl.getShippingAddressList';

const MOTOS_STORE_NAME = 'Motos';

const MOTOS_COLUMNS = [
    { label: inventoryLabels().modelLine, fieldName: 'modelLine', type: 'text', sortable: true },
    { label: inventoryLabels().color, fieldName: 'color', type: 'text', sortable: true },
    { label: inventoryLabels().model, fieldName: 'model', type: 'text', sortable: true },
];

const LocationType = {
    LOCATION: 'Location',
    LOCATION_GROUP: 'Location Group'
};

export default class FanInventoryLocationGroup extends LightningElement {

    get labels(){
        return inventoryLabels();
    }

    get columnsData(){
        return [
            { label: this.labels.reference, fieldName: 'reference', type: 'text', sortable: true },
            { label: this.labels.description, fieldName: 'description', type: 'text', sortable: true },
            { label: this.labels.concessionaire, fieldName: 'concessionaire', type: 'text', sortable: true },
            { label: this.labels.agency, fieldName: 'agencia', type: 'text', sortable: true },
            { label: this.labels.available, fieldName: 'availableToFulfill', type: 'number', sortable: true }
        ];
    }

    _columnsLocationGroup = [
        { label: this.labels.reference, fieldName: 'reference', type: 'text', sortable: true },
        { label: this.labels.description, fieldName: 'description', type: 'text', sortable: true },
        { label: this.labels.available, fieldName: 'availableToFulfill', type: 'number', sortable: true },
        { label: this.labels.hasSubstitute, fieldName: 'hasRelatedProduct', type: 'hasSubstituteCustomButtonType', 
            typeAttributes: {
                buttonname: { fieldName: 'hasRelatedProductLabel'}, 
                recordId:{ fieldName: 'stockKeepingUnit'},
                isActive:{ fieldName: 'hasRelatedProduct'}
            },
            cellAttributes: {
                class: '',
            }
        }    
    ];

    get columnsLocationGroup() {
        return this._columnsLocationGroup;
    }

    set columnsLocationGroup(value){
        this._columnsLocationGroup = value;
    }

    get columnsLocationGroupRelatedProduct(){
        return this.columnsLocationGroup.filter(item => item.fieldName !== "hasRelatedProduct");
    }
    
    columns = this.columnsData;

    get getAvailabilityParams(){
        const city = this.branches?.[this.selectedBranch];
        return {
            locationGroup: this.locationGroupSelected,
            locations: this.locationsByCity[city] ?? [],
            searchTerm: this.searchTerm
        };
    }

    @api
    accountId;

    @api
    storeName;

    sortBy = 'availableToFulfill';
    sortDirection = 'desc';

    @api
    locationGroupSelected  = '';

    @api
    locationType = '';

    dataLocation = [];
    dataLocationFilter = [];
    searchTerm = '';
    dataProductsRelated = [];
    dataProductsRelatedFilter = [];

    showNoSKUMessage = false;
    hasResult = false;
    isGettingStock = false;

    showModalRelatedProduct = false;

    branchOptions = [];
    selectedBranch;

    get isDataProductsRelated(){
        return this.dataProductsRelated.length == 0 ? false : true;
    }

    get isStoreMotos(){
        return (this.storeName === MOTOS_STORE_NAME);
    }

    connectedCallback() {
        this.handleLoad();
        this.fetchLocationByCity();
    }

    handleLoad() {
        const additionalColumns = this.getAdditionalColumns();
        const rawColumns = this.locationType === LocationType.LOCATION ? this.columnsData : this.columnsLocationGroup;
        this.columns = [...rawColumns, ...additionalColumns];
    }

    async getAvailability() {
        this.isGettingStock = true;
        try {
            if(this.locationType === LocationType.LOCATION) {
                this.dataLocation = await getAvailabilityForRedInventory({ locationGroup: this.locationGroupSelected, searchTerm: this.searchTerm });
                this.dataLocationFilter = this.dataLocation;
            } else {
                const { lstLocationGroup, lstLocation } = await getAvailabilityOfRelatedProducts(this.getAvailabilityParams);
                this.dataLocation = (this.isStoreMotos
                ? this.getInventoryRowsMergedBySKU(lstLocation)
                : lstLocationGroup)
                .sort(this.sortImplementation(this.sortBy, this.sortDirection));
                console.log('Result to Table', this.dataLocation);
                this.dataLocationFilter = this.dataLocation;
                this.dataLocationFilter.forEach(row => {
                    row.hasRelatedProductLabel = row.hasRelatedProduct ? this.labels.yes : this.labels.no;
                });
            }
            this.hasResult = !!this.dataLocation.length;
            this.showNoSKUMessage = !this.hasResult;
        } catch (error) {
            console.log('Error getting availability --> ', error);
        } finally {
            this.isGettingStock = false;
        }
    }

    getRelatedProducts(PickedSku){
        getRelatedProductsWithAvailability({
            locationGroup: this.locationGroupSelected,
            sku: PickedSku
        }).then(({ lstLocationGroup }) => {
            this.dataProductsRelated = lstLocationGroup.sort(this.sortImplementation(this.sortBy, this.sortDirection));
            this.dataProductsRelatedFilter = this.dataProductsRelated;
        }).catch(error => {
            console.log('Error in getRelatedProductsWithAvailability -->', error);
        });
    }

    /**
     * Gets the branch options available for the user.
     */
    @wire(getShippingAddressList, { accountId: '$accountId' })
    getBranchOptions({data, error}){
        if(data) {
            this.branches = data.reduce((accumulator, { City, fan_Code__c }) => {
                accumulator[fan_Code__c] = City;
                return accumulator;
            }, {});
            this.branchOptions = data.map(({ fan_Code__c: value, Name: label }) => ({ label, value }));

            if(data.length === 1) {
                this.selectedBranch = data[0].fan_Code__c;
            }
        } else if(error){
            console.log('Error in getShippingAddressList --> ', error);
        }
    }

    fetchLocationByCity() {
        getLocationByCity({
            accountId: this.accountId
        }).then(data => {
            this.locationsByCity = data;
            console.log('Result getLocationByCity', data);
        }).catch(error => {
            console.log('Error getting locations by city', error);
        });
    }

    onChangeSKU(event) {
        this.searchTerm = event.target.value;
    }

    onHandleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        this.dataLocationFilter = [...this.dataLocation]
        .sort(this.sortImplementation(this.sortBy, this.sortDirection));
    }

    onHandleSortModalRelatedProduct(event){
        this.dataProductsRelatedFilter = [...this.dataProductsRelated]
        .sort(this.sortImplementation(event.detail.fieldName, event.detail.sortDirection));
    }

    sortImplementation(fieldName, sortDirection) {
        const isReverse = sortDirection === 'asc' ? 1 : -1;
        return (a, b) => {
            a = a[fieldName] ?? '';
            b = b[fieldName] ?? '';
            return isReverse * ((a > b) - (b > a));
        };
    }

    updateSearch(event) {
        const inputValue = event.target.value;

        if (inputValue) {
            const regex = new RegExp(inputValue, 'gi');

            const filterImplementation = this.locationType === LocationType.LOCATION
            ? this.filterForLocations(regex)
            : this.filterForLocationGroups(regex);

            this.dataLocationFilter = this.dataLocation.filter(filterImplementation);
        } else {
            this.dataLocationFilter = this.dataLocation;
        }
    }

    updateSearchModalRelatedProduct(event) {
        const inputValue = event.target.value;

        if (inputValue) {
            const regex = new RegExp(inputValue, 'gi');

            const filterImplementation = this.locationType === LocationType.LOCATION
            ? this.filterForLocations(regex)
            : this.filterForLocationGroups(regex);

            this.dataProductsRelatedFilter = this.dataProductsRelated.filter(filterImplementation);
        } else {
            this.dataProductsRelatedFilter = this.dataProductsRelated;
        }
    }

    filterForLocations(regex) {
        return (row) =>
            regex.test(row.agencia) ||
            regex.test(row.stockKeepingUnit) ||
            regex.test(row.reference) ||
            regex.test(row.description) ||
            regex.test(row.concessionaire);
    }

    filterForLocationGroups(regex) {
        return (row) =>
            regex.test(row.description) ||
            regex.test(row.stockKeepingUnit) ||
            regex.test(row.reference) ||
            regex.test(row.ubicacion);
    }

    handleAlert(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    handleHasSubstituteCustomButtonEvent(event){
        this.showModalRelatedProduct = true;
        this.getRelatedProducts(event.detail.recordId);
    }
    
    handleCloseModalRelatedProduct(event){
        if(this.showModalRelatedProduct){
            this.showModalRelatedProduct = false;
            this.dataProductsRelated = [];
            this.dataProductsRelatedFilter = [];
        }
    }

    handleBranchChange({ detail }) {
        const { value } = detail;
        this.selectedBranch = value;
        console.log('handlebranchchange', this.selectedBranch);

        this.getAvailability();
    }

    /**
     * Gets the columns according to the selected store.
     */
    getAdditionalColumns() {
        if(this.isStoreMotos){
            //Deleting column 'hasRelatedProduct' from the array columnsLocationGroup if store name == Motos
            this.columnsLocationGroup = this.columnsLocationGroup.filter(x => x.fieldName !== 'hasRelatedProduct');
            return MOTOS_COLUMNS;
        }
        else {
            return [];
        }
    }

    /**
     * Gets rows of products unified by his sku given a list rows with separated by locations
     */
    getInventoryRowsMergedBySKU(rowsInventory){
        const groups = rowsInventory.reduce((accumulator, item) => {
            const stockKeepingUnit = item.stockKeepingUnit;
            const group = accumulator[stockKeepingUnit] ?? [];
            accumulator[stockKeepingUnit] = [...group, item];
            return accumulator;
          }, {});

          return Object.values(groups).map((inventoryRecords) => {
            const { stockKeepingUnit, reference, description, modelLine, color, model } = inventoryRecords[0];
            return { 
                stockKeepingUnit,
                reference,
                description,
                availableToFulfill: inventoryRecords.reduce((total, { availableToFulfill }) => total + availableToFulfill, 0),
                modelLine,
                color,
                model
            };
          });
    }
}