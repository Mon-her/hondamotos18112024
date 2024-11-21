import { api, LightningElement, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import SHEETJS_STYLE_ZIP from '@salesforce/resourceUrl/fan_sheetjs_style';
import { financialStatementLabels as label } from 'c/fanLabels';
import { exportToXLSX } from './fanBuilder';

import getMovements from '@salesforce/apex/fan_ConsultaExtractosController.getMovements';
import getAccountInformation from '@salesforce/apex/fan_ConsultaExtractosController.getAccountInformation';

const Exception = {
	READ_TIMED_OUT: "IO Exception: Read timed out"
};

export default class FanMovementExtract extends LightningElement {

	@api
	effectiveAccountId;

	// Request input for the date range.
	@api
	startDate;

	// Request input for the date range.
	@api
	endDate;

	get isDownloadButtonDisabled() {
		return !this.startDate || !this.endDate;
	}

	get label() {
		return label();
	}

	// Local fields.
	isDownloading;

	@wire(getAccountInformation, { id: "$effectiveAccountId" })
	getAccountInformation({ data, error }) {
		if(data) {
			this.accountInformation = data;
		} else if(error) {
			console.log('Error in getAccountInformation --> ', error);
		}
	}

	connectedCallback() {
		loadScript(this, SHEETJS_STYLE_ZIP + '/xlsx.bundle.js');
	}

	handleDateChange({ detail, currentTarget }) {
		this[currentTarget.dataset.name] = detail.value;
	}

	handleDownload() {
		this.isDownloading = true;

		getMovements({
			nitCliente: this.accountInformation.nit,
			startDate: this.startDate,
			endDate: this.endDate
		}).then((movements) => {
			if(movements.length) {
				exportToXLSX(this.accountInformation, [this.startDate, this.endDate], movements);
			} else {
				this.dispatchEvent(new ShowToastEvent({
					title: label().noFinancialStatementFound,
					variant: "warning"
				}));
			}
		}).catch((error) => {
			this.handleExceptionMessages(error);
		}).finally(() => {
			this.isDownloading = false;
		});
	}

	handleExceptionMessages(error) {
		if(error?.body?.message === Exception.READ_TIMED_OUT) {
			this.dispatchEvent(new ShowToastEvent({
				title: label().readTimedOut,
				variant: 'error'
			}));
		} else {
			console.log('Error in getMovements --> ', error);
		}
	}
}