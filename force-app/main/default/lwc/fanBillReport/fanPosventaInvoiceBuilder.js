import { posventaInvoiceBuilderLabels } from 'c/fanLabels';

import {
	fontName, NumberFormat, calculateDiscount,
	calculateGrossValue, isFreight, applyTotalsStyles,
	calculateColumnWidth, fillEmptyCells
} from './fanInvoiceUtils'

// Rows between invoice items and totals.
const SEPARATORS = 3;
// For header, invoice items and separators.
const ROW_HEIGHT = undefined;

const GENERIC_HEADER_STYLE = {
	alignment: {
		vertical: "center",
		wrapText: true
	},
	border: {
		bottom: {
			style: "thin"
		}
	},
	font: {
		bold: true,
		name: fontName,
		sz: 9
	},
};
const label = posventaInvoiceBuilderLabels();

const HEADER = [
	{
		v: label.document,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.reference,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.description,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.quantity,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.discount,
		s: { ...GENERIC_HEADER_STYLE,
			alignment: {
				horizontal: "center",
				vertical: "center",
				wrapText: true
			}
		}
	},
	{
		v: label.unitPrice,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.subtotalValue,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.feeRate,
		s: { ...GENERIC_HEADER_STYLE,
			alignment: {
				horizontal: "center",
				vertical: "center",
				wrapText: true
			}
		}
	},
	{
		v: label.feeValue,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.netValue,
		s: GENERIC_HEADER_STYLE
	}
];

const GENERIC_ITEM_STYLE = {
	alignment: {
		vertical: "center",
		wrapText: true
	},
	font: {
		name: fontName,
		sz: 8
	}
};

const TOTALS_LABEL_STYLE = {
	alignment: {
		vertical: "center",
		wrapText: true
	},
	font: {
		bold: true,
		name: fontName,
		sz: 9
	}
};
const TOTALS_VALUE_STYLE = {
	alignment: {
		vertical: "center",
		wrapText: true
	},
	font: {
		name: fontName,
		sz: 10
	},
	numFmt: NumberFormat.CURRENCY
};
const TOTALS_LABELS = [
	label.grossValueRow,
	label.subtotalValueRow,
	label.discountRow,
	label.freightValueRow,
	label.totalVATRow,
	label.totalValueRow
];

function buildInvoiceItem(item) {
	return [
		{
			v: item.document,
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.reference,
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.referenceDescription,
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.quantity,
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.discountRate,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				alignment: {
					horizontal: "center",
					vertical: "center"
				},
				numFmt: NumberFormat.PERCENTAGE
			}
		},
		{
			v: item.unitPrice,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.CURRENCY
			}
		},
		{
			v: item.subtotal,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.CURRENCY
			}
		},
		{
			v: item.feeRate,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				alignment: {
					horizontal: "center",
					vertical: "center"
				},
				numFmt: NumberFormat.PERCENTAGE
			}
		},
		{
			v: item.feeValue,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.CURRENCY
			}
		},
		{
			v: item.netValue,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.CURRENCY
			}
		},
	];
}

function calculateTotals(invoiceItems) {
	return invoiceItems.reduce(([grossValue, subtotal, discounts, freight, IVA, total], item) => {
		return [
			grossValue + calculateGrossValue(item.referenceDescription, item.unitPrice, item.quantity),
			subtotal + (isFreight(item.referenceDescription) ? 0 : item.subtotal),
			discounts + calculateDiscount(item.unitPrice, item.quantity, item.subtotal),
			freight + (isFreight(item.referenceDescription) ? item.subtotal : 0),
			IVA + item.feeValue,
			total + item.netValue
		];
	}, Array(6).fill(0));
}

export function buildPosventaInvoiceData(invoiceItems) {

	const items = invoiceItems.map(buildInvoiceItem);
	const totalsResult = calculateTotals(invoiceItems);
	const totals = TOTALS_LABELS.map(applyTotalsStyles(totalsResult, TOTALS_LABEL_STYLE, TOTALS_VALUE_STYLE))
	.map(fillEmptyCells(HEADER.length - 2)); // Fill the first cells except the last two.

	return {
		header: HEADER,
		items,
		separators: SEPARATORS,
		totals,
		rowHeight: ROW_HEIGHT,
		columnWidth: calculateColumnWidth(HEADER, items, totals)
	};
}