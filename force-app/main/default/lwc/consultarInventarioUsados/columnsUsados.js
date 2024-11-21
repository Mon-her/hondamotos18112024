const columnsUsados = [
  {
    type: 'button-icon',
    typeAttributes:
    {
        iconName: 'action:record',
        name: 'view',
        variant: 'brand'
        //size: 'large'//"small" 
        //iconClass: 'slds-icon-text-error'
    }
},
{
      label: "Autonumérico",
      fieldName: "Name",
      hideDefaultActions: true,
      //type: 'url',
      //typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}
  },
  {
    label: "Estado",
    fieldName: "Estado_Del_Vehiculo__c",
    hideDefaultActions: true
  },
  {
    label: "Origen",
    fieldName: "Origen__c",
    hideDefaultActions: true
  },
  {
    label: "Placa",
    fieldName: "Placas__c",
    hideDefaultActions: true
  },
  /*{
        label: "Nombre de Producto",
        fieldName: "Nombre_De_Producto__c",
        hideDefaultActions: true,
    },*/
    {
      label: "Agencia de recepción",
      fieldName: "Agencia__c",
      hideDefaultActions: true
    },
    
    {
      label: "Marca",
      fieldName: "Marca__c",
      hideDefaultActions: true
    },
    {
      label: "Línea",
      fieldName: "Linea__c",
      hideDefaultActions: true
    },
    {
      label: "Versión",
      fieldName: "Version__c",
      hideDefaultActions: true
    },
    {
      label: "Cilindraje",
      fieldName: "Cilindraje__c",
      hideDefaultActions: true
    },
    {
      label: "Caja",
      fieldName: "Caja__c",
      hideDefaultActions: true
    },
    {
      label: "Tracción",
      fieldName: "Traccion__c",
      hideDefaultActions: true
    },
    {
      label: "Color",
      fieldName: "Color__c",
      hideDefaultActions: true
    },
    {
      label: "Año",
      fieldName: "Ano__c",
      hideDefaultActions: true
    },
    {
      label: "Kilometraje",
      fieldName: "Kilometraje__c",
      hideDefaultActions: true
    },
    {
      label: "Precio Venta",
      fieldName: "Precio_Venta__c",
      hideDefaultActions: true,
      type: "currency"
    },
    {
      label: "Tu carro.com",
      fieldName: "Fotos_TucarroCom__c",
      hideDefaultActions: true,
      type: 'url',
      fixedWidth: 50
      //typeAttributes: {label: { fieldName:  'Fotos_TucarroCom__c' }, target: '_blank'}
  },
  {
    label: "Fotos FINECAR",
    fieldName: "Fotos_FINECAR__c",
    hideDefaultActions: true,
    type: 'url',
    fixedWidth: 50
    //typeAttributes: {label: { fieldName: 'Fotos_TucarroCom__c' }, target: '_blank'}
  }
];
  
  export { columnsUsados };