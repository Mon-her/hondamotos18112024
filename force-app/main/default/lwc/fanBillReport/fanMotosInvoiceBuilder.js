import { motosInvoiceBuilderLabels } from 'c/fanLabels';

import {
	fontName, NumberFormat, calculateDiscount,
	calculateGrossValue, isFreight, applyTotalsStyles,
	calculateColumnWidth, fillEmptyCells
} from './fanInvoiceUtils'

// Rows between invoice items and totals.
const SEPARATORS = 1;
// For header, invoice items and separators.
const ROW_HEIGHT = { hpt: 25.5 };

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
const label = motosInvoiceBuilderLabels();

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
		v: label.issueDate,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.chassis,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.engine,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.discount,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.color,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.model,
		s: GENERIC_HEADER_STYLE
	},
	{
		v: label.quantity,
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
		v: label.feeRate,
		s: GENERIC_HEADER_STYLE
	},
];

const GENERIC_ITEM_STYLE = {
	alignment: {
		vertical: "center"
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
	label.discountRow,
	label.freightValueRow,
	label.totalVATRow,
	label.totalValueRow,
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
			v: item.issueDate,
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.chassis ?? '',
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.engine ?? '',
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.discountRate,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.PERCENTAGE
			}
		},
		{
			v: item.color ?? '',
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.model ?? '',
			t: "s",
			s: GENERIC_ITEM_STYLE
		},
		{
			v: item.quantity,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				alignment: {
					horizontal: "center",
					vertical: "center"
				},
				numFmt: NumberFormat.DECIMAL
			}
		},
		{
			v: item.unitPrice,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.CUSTOM_CURRENCY
			}
		},
		{
			v: item.feeRate,
			t: "n",
			s: {
				...GENERIC_ITEM_STYLE,
				numFmt: NumberFormat.PERCENTAGE
			}
		},
	];
}

function calculateTotals(invoiceItems) {
	return invoiceItems.reduce(([grossValue, discounts, freight, IVA, totalValue], item) => {
		return [
			grossValue + calculateGrossValue(item.referenceDescription, item.unitPrice, item.quantity),
			discounts + calculateDiscount(item.unitPrice, item.quantity, item.subtotal),
			freight + (isFreight(item.referenceDescription) ? item.subtotal : 0),
			IVA + item.feeValue,
			totalValue + item.netValue
		];
	}, Array(5).fill(0));
}

export function buildMotosInvoiceData(invoiceItems) {

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