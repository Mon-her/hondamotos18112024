import { financialStatementXlsxBuilderLabels } from 'c/fanLabels';

const SESSION_NAME_ORDER = [
	'CLIENTES NACIONALES',
	'CARTERA PUENTE',
	'DEUDORES VARIOS',
	'OTRAS CUENTAS POR PAGAR CLIENTES',
	'ANTIC. DE CLIENTES'
];

const LABEL = financialStatementXlsxBuilderLabels();

const MINIMUM_COLUMN_WIDTH = 10;

const FONT = {
	name: 'Courier New',
	sz: 10
};

const DataFormat = {
	DATE: "dd/mm/yyyy",
	CURRENCY: "[$$-es-CO] #,##0",
};

const alignmentForNumericColumn = {
	horizontal: "right",
	vertical: "center"
};

function formatDate(date) {
	return date.split('-').reverse().join('/');
}

function buildHeaderInformationRows(account, [ startDate, endDate ]) {
	const STYLE = { font: { bold: true, ...FONT }};
	return [
		[
			{ v: account.corporation.name, s: STYLE }
		],
		[],
		[
			{ v: account.corporation.address, s: STYLE }
		],
		[],
		[
			{ v: LABEL.phone.replace('{0}', account.corporation.phone), s: STYLE }
		],
		...Array(4),
		[
			...Array(3),
			{ v: LABEL.sir, s: STYLE }
		],
		[],
		[
			...Array(3),
			{ v: account.name, s: STYLE }
		],
		[],
		[
			...Array(3),
			{ v: LABEL.code, s: STYLE },
			{ v: account.nit, s: STYLE }
		],
		[],
		[
			...Array(3),
			{ v: account.billingStreet, s: STYLE }
		],
		[],
		[
			...Array(3),
			{ v: `${account.billingCity} - ${account.billingState}`, s: STYLE }
		],
		[
			...Array(3),
			{ v: account.billingCountry, s: STYLE }
		],
		...Array(2),
		[
			{ v: LABEL.dearSir, s: STYLE }
		],
		[],
		[
			{ v: LABEL.dateRange, s: STYLE },
			...Array(4),
			{
				v: `${formatDate(startDate)} y ${formatDate(endDate)}`,
				s: STYLE
			}
		]
	];
}

const HEADER_COLUMN_STYLE = {
	font: {
		bold: true,
		...FONT
	}
};
const HEADER_COLUMNS = [
	{
		v: LABEL.date,
		s: {
			alignment: {
				horizontal: "center"
			},
			font: HEADER_COLUMN_STYLE.font
		}
	},
	{ v: LABEL.document, s: HEADER_COLUMN_STYLE },
	{ v: "" },
	{ v: LABEL.crossingDocument, s: HEADER_COLUMN_STYLE },
	{ v: LABEL.expirationDate, s: HEADER_COLUMN_STYLE },
	{ v: "" },
	{ v: LABEL.documentValue, s: HEADER_COLUMN_STYLE },
	{ v: "" },
	{ v: LABEL.initialBalance, s: HEADER_COLUMN_STYLE },
	{ v: LABEL.appliedValue, s: HEADER_COLUMN_STYLE },
	{ v: LABEL.endingBalance, s: HEADER_COLUMN_STYLE }
];

function buildSession(sessionName, currency) {
	const STYLE = { font:  { bold: true, ...FONT } };
	return [
		{
			v: sessionName,
			s: {
				alignment: {
					horizontal: "center"
				},
				...STYLE
			}
		},
		...Array(4),
		{
			v: LABEL.currency,
			s: STYLE
		},
		{
			v: currency,
			s: {
				alignment: {
					horizontal: "right"
				},
				...STYLE
			}
		}
	];
}

function buildMovementRow(item) {
	const SEPARATOR = { v: "" };
	const STYLE = { font: FONT };
	return [
		{
			v: item.documentDate,
			t: "d",
			s: {
				alignment: {
					horizontal: "center"
				},
				...STYLE
			},
			z: DataFormat.DATE
		},
		{
			v: item.document,
			s: STYLE,
		},
		SEPARATOR,
		{
			v: item.crossingDocument,
			s: STYLE,
		},
		{
			v: item.expirationDate,
			t: "d",
			s: STYLE,
			z: DataFormat.DATE
		},
		SEPARATOR,
		{
			v: item.documentValue,
			t: "n",
			s: {
				...STYLE,
				alignment: alignmentForNumericColumn
			},
			z: DataFormat.CURRENCY
		},
		SEPARATOR,
		{
			v: item.initialBalance,
			t: "n",
			s: {
				...STYLE,
				alignment: alignmentForNumericColumn
			},
			z: DataFormat.CURRENCY
		},
		{
			v: -1 * item.appliedValue,
			t: "n",
			s: {
				...STYLE,
				alignment: alignmentForNumericColumn
			},
			z: DataFormat.CURRENCY
		},
		{
			v: item.endingBalance,
			t: "n",
			s: {
				...STYLE,
				alignment: alignmentForNumericColumn
			},
			z: DataFormat.CURRENCY
		},
	];
}

function sortByDocumentDate({ documentDate: a }, { documentDate: b }) {
	return a.localeCompare(b);
}

function sortBySessionName([a], [b]) {
	return SESSION_NAME_ORDER.indexOf(a) - SESSION_NAME_ORDER.indexOf(b);
}

function groupBySubsidiary(movements) {
	const grouped = movements.reduce((accumulator, current) => {
		const subsidiaryKey = current.subsidiary;
		const subsidiaryValue = accumulator.get(subsidiaryKey);

		if (accumulator.has(subsidiaryKey)) {
			subsidiaryValue.push(current);
		} else {
			accumulator.set(subsidiaryKey, [current]);
		}
		return accumulator;
	}, new Map());
	return [...grouped];
}

function countCommas(number) {
	number = String(number);
	let commas = 0;

	// 3 represents thousands separator.
	for (let i = 3; i < number.length; i += 3) {
		++commas;
	}
	return commas;
}

function getMaxColumnWidth(widths, row) {
	return widths.map((width, index) => {
		const cellValue = String(row[index]?.v ?? '');
		let length = cellValue.length;

		if(row[index]?.z === DataFormat.CURRENCY) {
			const natural = cellValue | 0;
			const extraWidth = 1 + 1 + countCommas(natural);
			length = String(natural).length + extraWidth;
		}
		return Math.max(width, length);
	});
}

function calculateColumnWidth(rows) {
	return rows.reduce(getMaxColumnWidth, Array(HEADER_COLUMNS.length).fill(MINIMUM_COLUMN_WIDTH));
}

function buildMovementData(movements, currency) {
	const groupedMovements = groupBySubsidiary(movements)
	.sort(sortBySessionName)
	.map(([ sessionName, items ]) => [sessionName, items.map(buildMovementRow)]);
	return {
		header: HEADER_COLUMNS,
		items: groupedMovements.reduce((accumulator, [ sessionName, items ]) => [
			...accumulator,
			buildSession(sessionName, currency),
			[], // Separator.
			...items,
			...Array(4) // Separators.
		], []),
		columnWidth: calculateColumnWidth([
			HEADER_COLUMNS,
			...groupedMovements.map(([ sessionName ]) => [{ v: sessionName }]),
			...groupedMovements.map(([, items ]) => items).flat()
		])
	};
}

function buildWorkbook(sheetJS, headerInformationRows, movementsData) {
	const workbook = sheetJS.utils.book_new();
	const worksheet = sheetJS.utils.aoa_to_sheet([
		...headerInformationRows,
		[],
		movementsData.header,
		[],
		...movementsData.items,
	]);
	worksheet["!cols"] = movementsData.columnWidth.map((width) => ({ wch: width }));

	sheetJS.utils.book_append_sheet(workbook, worksheet);
	return workbook;
}

function buildFileName([startDate, endDate]) {
	const format = (date) => date.split('/').reverse().join('-');

	return LABEL.fileName
	.replace('{0}', format(startDate))
	.replace('{1}', format(endDate));
}

export function exportToXLSX(accountInformation, dateRange, movements) {
	const sheetJS = window.XLSX;
	try {
		const headerInformationRows = buildHeaderInformationRows(accountInformation, dateRange);
		const sortedMovements = [...movements].sort(sortByDocumentDate);

		const movementsData = buildMovementData(sortedMovements, accountInformation.corporation.currency);
		const workbook = buildWorkbook(sheetJS, headerInformationRows, movementsData);

		sheetJS.writeFile(workbook, buildFileName(dateRange));
	} catch (error) {
		console.log("Error in --> exportToXLSX ", error);
	}
}