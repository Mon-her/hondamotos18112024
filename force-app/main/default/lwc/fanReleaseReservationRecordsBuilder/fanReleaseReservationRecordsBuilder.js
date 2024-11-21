import { api, LightningElement } from 'lwc';

const LABELS = {
	action: 'Acción',
	addRow: 'Agregar fila',
	addRowDescription: 'Permite agregar filas en la tabla. El número máximo de filas permitidas es 100.',
	mustSaveAtLestOneRow: 'Debe tener al menos una fila registrada para proceder.',
	location: 'Ubicación',
	locationGroup: 'Grupo de ubicaciones',
	remove: 'Remover',
	stockKeepingUnit: 'StockKeepingUnit',
	quantity: 'Cantidad',
};

export default class FanReleaseReservationRecordsBuilder extends LightningElement {

	@api
	releaseReservationRecords = [];

	columns = [
		{
			label: LABELS.stockKeepingUnit,
			fieldName: 'stockKeepingUnit',
			type: 'text',
			editable: true
		},
		{
			label: LABELS.quantity,
			fieldName: 'quantity',
			type: 'number',
			editable: true
		},
		{
			label: LABELS.location,
			fieldName: 'locationIdentifier',
			type: 'text',
			editable: true
		},
		{
			label: LABELS.locationGroup,
			fieldName: 'locationGroupIdentifier',
			type: 'text',
			editable: true
		},
		{
			label: LABELS.action,
			type: 'button',
			typeAttributes: {
				label: LABELS.remove,
				variant: 'destructive'
			}
		}
	];

	_rows = [];
	get rows() {
		return this._rows.map((row, index) => ({
			rowId: `row-${index}`,
			...row
		}));
	}

	set rows(value) {
		this._rows = value;
	}

	get isAddRowDisabled() {
		return this.rows.length >= 100;
	}

	get labels() {
		return LABELS;
	}

	@api
	validate() {
		const result = { isValid: true };

		if(!this.releaseReservationRecords.length) {
			result.isValid = false;
			result.errorMessage = LABELS.mustSaveAtLestOneRow;
		}
		return result
	}

	connectedCallback() {
		this.rows = this.releaseReservationRecords;
	}

	handleAddRow() {
		const defaultRow = {
			stockKeepingUnit: '',
			quantity: 0,
			locationIdentifier: '',
			locationGroupIdentifier: ''
		};

		this.rows = [
			...this.rows,
			defaultRow
		];
	}

	handelRowAction({ detail }) {
		// Remove element.
		const { rowId: selectedRowId } = detail.row;
		this.rows = this.rows.filter(({ rowId }) => rowId !== selectedRowId);

		this.releaseReservationRecords = this.buildReleaseReservationRecords();
	}

	handleSave({ detail }) {

		const draftValues =  detail.draftValues.reduce((accumulator, row) => {
			const { rowId} = row;
			accumulator[rowId] = row;
			return accumulator;
		}, {});
		console.log(JSON.parse(JSON.stringify(draftValues)));

		this.rows = this.rows.map((row) => {
			const { rowId } = row;
			const draftRow = draftValues[rowId] ?? {};

			return { ...row, ...draftRow };
		});
		this.releaseReservationRecords = this.buildReleaseReservationRecords();
		this.draftValues = [];
	}

	buildReleaseReservationRecords() {
		return this.rows.map(({ stockKeepingUnit, quantity, locationGroupIdentifier, locationIdentifier }) => ({
			stockKeepingUnit,
			quantity: quantity || 0,
			locationGroupIdentifier,
			locationIdentifier
		}));
	}
}