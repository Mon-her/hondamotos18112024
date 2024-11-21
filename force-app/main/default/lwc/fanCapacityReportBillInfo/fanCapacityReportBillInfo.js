import { api, LightningElement } from 'lwc';

import { capacityReportBillInfoLabels } from 'c/fanLabels';

const EXPORT_FILE_EVENT = 'exportfile';

export default class FanCapacityReportBillInfo extends LightningElement {

    @api
    accountData;

    @api
    invoicesTotals;

    /**
     * Flag to control whether to disable the button to export file.
     */
    @api
    isExportFileDisabled;

    sortBy

    sortAsc

    filterBy

    filterFor

    hrefLink

    get label(){
        return capacityReportBillInfoLabels();
    }

    get currentSortBy(){
        return {
            sortByBill : this.sortBy !== "document",
            sortByExpirationDate : this.sortBy !== "expirationDate",
            sortByOrderType : this.sortBy !== "code",
            sortByExpiredDays : this.sortBy !== "docuExpired",
            sortByBillValue : this.sortBy !== "total",
            sortByExpiredBillValue : this.sortBy !== "total",
        };
    }

    get arrowDirection(){
        return this.sortAsc ? 'utility:arrowup' : 'utility:arrowdown';
    }

    /**
     * Handles the filter logic and fires a filterupdate event to the parent component
     * @param {*} event 
     */
    onHandleFilter(event){

        this.filterFor = event.target.value;
        this.filterBy = event.target.title;

        const filterupdate = new CustomEvent('filterupdate', {
            detail: {
                'filter_for' : this.filterFor,
                'filter_by' : this.filterBy
            },
        });
        
        this.dispatchEvent(filterupdate);
    }

    /**
     * Handles the sorting logic and fires a sortupdate event to the parent component
     * @param {*} event 
     */
    onHandleSort(event){
        let selectedSortBy = event.target.title;
        let isNewSortBy = selectedSortBy !== this.sortBy;

        this.sortAsc = isNewSortBy ? true : !this.sortAsc;
        this.sortBy = isNewSortBy ? selectedSortBy : this.sortBy;
        console.log('sortAsc >> ',this.sortAsc);
        console.log('sortBy >> ',this.sortBy);

        const sortupdate = new CustomEvent('sortupdate', {
            detail: {
                'sort_asc' : this.sortAsc,
                'sort_by' : this.sortBy
            },
        });
        
        this.dispatchEvent(sortupdate);
    }

    /**
     * Fires an event to export a file.
     * @private
     * @fires fanCapacityReportBillInfo#exportfile
     */
    notifyFileExport() {
        this.dispatchEvent(new CustomEvent(EXPORT_FILE_EVENT));
    }
}