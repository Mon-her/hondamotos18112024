const ReferenceDescription = {
	FREIGHT: 'FLETES'
};

export const fontName = 'Times New Roman';

export const NumberFormat = {
	CURRENCY: '$ #,##0',
	DECIMAL: '#.00',
	PERCENTAGE: '0.00%',
	CUSTOM_CURRENCY: '_($* #,##0_);_($* (#,##0);_($* "-"??_);_(@_)'
};

export function calculateDiscount(unitPrice, quantity, subtotal) {
	return unitPrice * quantity - subtotal;
}

export function calculateGrossValue(referenceDescription, unitValue, quantity) {
	return isFreight(referenceDescription) ? 0 : unitValue * quantity;
}

export function isFreight(referenceDescription) {
	return referenceDescription === ReferenceDescription.FREIGHT;
}

export function applyTotalsStyles(totalsValues, labelStyle, valueStyle) {
	return (label, index) => [
		{
			v: label,
			t: "s",
			s: labelStyle
		},
		{
			v: totalsValues[index],
			t: "n",
			s: valueStyle
		}
	];
}

export function fillEmptyCells(length) {
	return (totalsRow) => [
		...Array(length).fill({ v: "" }),
		...totalsRow
	];
}

function getMaximumCellLength(accumulator, current) {
	return current.map((cell, index) => Math.max((cell.v + '').length, accumulator[index]));
}

// Currency symbol, space and commas.
function getExtraLengthOfCurrencyValue(totalValue) {

	const lengthToSeparateThousands = 3;

	return 1 + // A Currency symbol.
	1 + // A space.
	(totalValue + '').length / lengthToSeparateThousands | 0; // Number of commmas.
}

export function calculateColumnWidth(header, items, totals) {

	const columnWidth = [header, ...items, ...totals].reduce(getMaximumCellLength, Array(header.length).fill(0));

	const totalValue = totals.at(-1) // Last row.
	.at(-1).v; // Last cell value.
	const totalValueLength = columnWidth.at(-1);

	columnWidth[columnWidth.length - 1] = totalValueLength + getExtraLengthOfCurrencyValue(totalValue);
	return columnWidth;
}