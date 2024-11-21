const columnsMotos = [
  {
    label: "Agencia",
    fieldName: "agenciaNombre",
    hideDefaultActions: true
  },
  {
    label: "Referencia",
    fieldName: "referencia",
    hideDefaultActions: true
  },
  {
    label: "Año Modelo",
    fieldName: "anioModelo",
    hideDefaultActions: true
  },
  {
    label: "Color",
    fieldName: "color",
    hideDefaultActions: true
  },
  {
    label: "Linea",
    fieldName: "linea",
    hideDefaultActions: true
  },
  {
    label: "Unidades disponibles",
    fieldName: "unidades",
    hideDefaultActions: true,
    type: "number",
    typeAttributes: {
      maximumFractionDigits: 0,
      minimumFractionDigits: 0
    }
  }
];

export { columnsMotos };