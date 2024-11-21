import LightningDatatable from 'lightning/datatable';
import hasSubstituteCustomButtonTemplate from './hasSubstituteCustomButton.html';

export default class FanInventoryLocationGroupCustomDatatable extends LightningDatatable {
    static customTypes = {
        hasSubstituteCustomButtonType: {
            template: hasSubstituteCustomButtonTemplate,
            standardCellLayout: false,
            typeAttributes: ['recordId', 'buttonname', 'isActive']
        }
    };
}