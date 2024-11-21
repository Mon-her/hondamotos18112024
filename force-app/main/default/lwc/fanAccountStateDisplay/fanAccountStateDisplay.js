import { LightningElement, api } from 'lwc';

import { accountStateDisplayLabels } from 'c/fanLabels'

const EXPORT_FILE_EVENT = 'exportfile';
const APPLY_FILTER_EVENT = 'applyfilter';

export default class FanEstadoCuentaDisplay extends LightningElement {

    @api
    accountStateData

    @api
    netTotal

    @api
    sortBy

    @api
    sortAsc

    /**
     * Flag to control whether to disable the button to export file.
     */
    @api
    isExportFileDisabled;

    onHandleSort(event){
        let selectedSortBy = event.target.title;
        let isNewSortBy = selectedSortBy != this.sortBy;

        this.sortAsc = isNewSortBy ? true : !this.sortAsc;
        this.sortBy = isNewSortBy ? selectedSortBy : this.sortBy;

        const sortupdate = new CustomEvent('sortupdate', {
            detail: {
                'sort_by' : this.sortBy,
                'sort_asc' : this.sortAsc
            },
        });
        
        this.dispatchEvent(sortupdate);
    }

    /**
     * Gets the labels to display.
     */
    get label(){
        return accountStateDisplayLabels();
    }

    /**
     * Gets the current date and time
     */

    get currentDateTime(){
        const dateTimeNow = new Date(Date.now());

        const day = dateTimeNow.getDate();
        const month = dateTimeNow.getMonth() + 1;
        const fullYear = dateTimeNow.getFullYear();

        return {
            date: day + '/' + month + '/' + fullYear,
            time: dateTimeNow.toLocaleTimeString()
        };
    }

    get currentSortBy(){
        return {
            sortByDocument : this.sortBy != "document",
            sortByAux : this.sortBy != "aux",
            sortByQuantity : this.sortBy != "quantity",
            sortByCurrentAmount : this.sortBy != "current",
            sortByExpiryAmountShort : this.sortBy != "expiryAmountShort",
            sortByExpiryAmountMedium : this.sortBy != "expiryAmountMedium",
            sortByExpiryAmountLong : this.sortBy != "expiryAmountLong",
            sortByExpiryAmountMax : this.sortBy != "expiryAmountMax",
            sortByTotal : this.sortBy != "total"
        };
    }

    get arrowDirection(){
        return this.sortAsc ? 'utility:arrowup' : 'utility:arrowdown';
    }

    /**
     * Fires an event to export a file.
     * @private
     * @fires fanAccountStateDisplay#exportfile
     */
    notifyFileExport() {
        this.dispatchEvent(new CustomEvent(EXPORT_FILE_EVENT));
    }

    /**
     * Fires an event to filter data.
     * @private
     * @fires fanAccountStateDisplay#applyfilter
     */
    notifyApplyFilter(event) {
        this.dispatchEvent(new CustomEvent(APPLY_FILTER_EVENT, {
            detail: {
                filterBy: event.target.dataset.property,
                filterFor: event.detail.value,
            }
        }));
    }
}