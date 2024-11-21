import { loadScript } from 'lightning/platformResourceLoader';

// Library to read, edit, and export spreadsheets Works.
import SHEETJS_ZIP from '@salesforce/resourceUrl/fan_sheetjs'

// Labels.
import { fileManager as getLabel } from 'c/fanLabels';

// Constans.
const XLSX_EXTENSION = 'xlsx';

/**
 * Loads the SheetJS library in the window object.
 * @param {Object} component The object reference.
 * @returns A simple promise with no data to provide.
 */
export async function loadSheetJS(component) {
	return loadScript(component, SHEETJS_ZIP + '/xlsx.full.min.js')
    .then(() => {
        if(!window.XLSX) {
            throw new Error(getLabel().errorLoadingSheetJS);
        }
    });
}

/**
 * Generates an XLSX file.
 * @param {Object} sheetJS The sheetJS library loaded into the window object.
 * @param {Array} header (Optional) The array of strings that will serve as header.
 * @param {Array} json The array of object that will serve as data.
 * @param {string} filename The name of the file to be exported.
 * @param {Array} lastRow (Optional) The array of objects that will be added at the end.
 */
export function exportToXLSX(sheetJS, header, json, filename, lastRow) {

    try {
        // Create a worksheet.
        const worksheet = sheetJS.utils.json_to_sheet(json);

        // Add the header.
        sheetJS.utils.sheet_add_aoa(worksheet, [header]);

        // Add a row at the end.
        sheetJS.utils.sheet_add_aoa(worksheet, [lastRow], { origin: -1 });

        // Create a workbook and add the worksheet to it.
        const workbook = sheetJS.utils.book_new();
        sheetJS.utils.book_append_sheet(workbook, worksheet)

        /* Export to file (start a download) */
        sheetJS.writeFileXLSX(workbook, `${filename}.${XLSX_EXTENSION}`);

    } catch (error) {
        throw new Error(getLabel().errorExportingFile);
    }
}