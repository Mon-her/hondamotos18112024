global class fan_ProductTitlePicklist extends VisualEditor.DynamicPickList {

    global override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('Nombre', 'name');
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows dynamicPickListRows = new VisualEditor.DynamicPickListRows();
        dynamicPickListRows.addAllRows(new List<VisualEditor.DataRow>{
            new VisualEditor.DataRow('Nombre', 'name'),
            new VisualEditor.DataRow('Referencia', 'sku')
        });
        return dynamicPickListRows;
    }
}