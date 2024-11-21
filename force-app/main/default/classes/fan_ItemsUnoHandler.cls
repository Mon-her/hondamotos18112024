public with sharing class fan_ItemsUnoHandler {

  final static String EMPTY_VALUE_KEY = 'NO ESPECIFICADO';

  private static fan_ServiceEndpoint__c getSettings(String serviceName) {
    List<fan_ServiceEndpoint__c> settings = [
      SELECT usuario__c, url__c, Nombre__c, contrasena__c
      FROM fan_ServiceEndpoint__c
      WHERE Nombre__c = :serviceName];

    if (settings.size() == 0) {
      throw new HandledException('Settings not found to: ' + serviceName);
    }

    return settings[0];
  }

  public static fan_ItemsUnoE.row_element[] getData() {
    fan_ServiceEndpoint__c settings = getSettings('Fanalca');

    fan_ItemsUnoE.HTTPS_Port port = new fan_ItemsUnoE.HTTPS_Port(
      settings.url__c
    );

    String[] item = new List<String>{ '' };

    port.inputHttpHeaders_x = new Map<String, String>();

    Blob headerValue = Blob.valueOf(
      settings.usuario__c +
      ':' +
      settings.contrasena__c
    );
    String authorizationHeader =
      'Basic ' + EncodingUtil.base64Encode(headerValue);
    port.inputHttpHeaders_x.put('Authorization', authorizationHeader);
    port.inputHttpHeaders_x.put('Content-Type', 'text/xml');
    port.timeout_x = 120000;

    fan_ItemsUnoE.row_element[] rows = port.POST('X');
    System.debug('Response rows' + rows);
    return rows == null ? new List<fan_ItemsUnoE.row_element>() : rows;
  }

  public static Product2 variationParentFormat(fan_ItemsUnoE.row_element row, String recordTypeId) {

    String MODELO_ANIO = validateField(row.MODELO_ANIO);
    String EXT_ITEM_CODIGO = validateField(row.EXT_ITEM_CODIGO);

    String unoeeCode = row.ITEM.replace(EXT_ITEM_CODIGO, '').replace(MODELO_ANIO, '');
    String productCode = unoeeCode + (String.isBlank(MODELO_ANIO) ? '' : ('-' + MODELO_ANIO));

    return new Product2(
      recordTypeId = recordTypeId,
      IdProductoUNOEE__c = productCode,
      Name = row.DESCRIPCION,
      ProductCode = productCode,
      StockKeepingUnit = productCode,

      Referencia__c = row.REFERENCIA,
      fan_Category__c = validateField(row.PLAN_300),
      Type = 'Base'
    );
  }

  public static Product2 variantProductFormat(fan_ItemsUnoE.row_element row, String recordTypeId) {
    Product2 variantProduct = new Product2(
      recordTypeId = recordTypeId,
      IdProductoUNOEE__c = row.ITEM,
      Name = row.DESCRIPCION,
      ProductCode = row.ITEM,
      StockKeepingUnit = row.ITEM,
      Referencia__c = row.REFERENCIA,
      fan_Category__c = validateField(row.PLAN_300),

      IsActive = row.ESTADO == 'Activo',
      fan_BaseColor__c = validateField(row.PLAN_CBR),

      fan_aplicaIVA__c = (Decimal.valueOf( row.CAMPO_IVA ) > 0 ),
      fan_aplicaIVAC__c = (Decimal.valueOf( row.CAMPO_IVAC ) > 0)
    );

    if(row.ITEM.substring(0, 1) == 'M'){
      // Motos Product fields
      variantProduct.fan_CylinderCapacity__c = validateField(row.CILINDRAJE);
      //variantProduct.fan_motoType__c = row.TPMOTOCICLETA;
      //variantProduct.fan_sidecar__c = row.SIDECAR;

      //variantProduct.fan_colorUnoe__c = row.EXT_ITEM_COLOR;
      variantProduct.fan_YearModel__c = validateField(row.MODELO_ANIO);

      //variantProduct.fan_type__c = row.PLAN_100;
      variantProduct.fan_Model__c = validateField(row.PLAN_YFD);
      variantProduct.fan_classification__c = validateField(row.PLAN_YFE);
      //variantProduct.fan_subClass__c = row.PLAN_500;

      //variantProduct.fan_eCommerce__c = row.PLAN_ECO;
      //variantProduct.fan_hondaMotoProductType__c = row.PLAN_YFA;
      //variantProduct.fan_hondaMotoProductClass__c = row.PLAN_YFB;
      //variantProduct.fan_hondaMotoProductSegment__c = row.PLAN_YFC;
      //variantProduct.fan_hondaMotoProductModel__c = row.PLAN_YFD;
      //variantProduct.fan_hondaMotoProductTypeMP__c = row.PLAN_YFE;
      //variantProduct.fan_hondaMotoProductCommercialCylinder__c = row.PLAN_YFF;
    }
    else{
      // Posventa Product fields
      variantProduct.fan_Application__c = validateField(row.PLAN_APL);
      variantProduct.fan_Dimensions__c = validateField(row.PLAN_DIT);
      variantProduct.fan_Position__c = validateField(row.PLAN_POS);
      variantProduct.fan_Rin__c = validateField(row.PLAN_RPM);
      variantProduct.fan_Size__c = validateField(row.PLAN_TMP);
      variantProduct.fan_OrderSegmentationGroup__c = validateField(row.PLAN_PMR);
      variantProduct.fan_Category_Partes__c = validateField(row.PLAN_CAP);

      variantProduct.fan_ProductClass__c = validateField(row.PLAN_GRR);
      variantProduct.fan_ProductBrand__c = validateField(row.PLAN_CN2);

      //variantProduct.fan_style__c = row.PLAN_104;
      //variantProduct.fan_tipoManga__c = row.PLAN_105;
      //variantProduct.fan_origin__c = row.PLAN_108;
      //variantProduct.fan_lineItem__c = row.PLAN_200;
      //variantProduct.fan_caliber__c = row.PLAN_250;
      //variantProduct.fan_B2CCategoryParts__c = row.PLAN_CAP;
      //variantProduct.fan_classificationSparePartsByCylCap__c = row.PLAN_CIL;
      //variantProduct.fan_category1__c = row.PLAN_CN1;
      //variantProduct.fan_category2__c = row.PLAN_CN2;
      //variantProduct.fan_sparePartsGroup__c = row.PLAN_GRR;
      //variantProduct.fan_hondaMotoModel__c = row.PLAN_H20;
      //variantProduct.fan_HondaSparePartsClassification__c = row.PLAN_H70;
      //variantProduct.fan_hondaSupplier__c = row.PLAN_H80;
      // VALUE IS MISSING: variantProduct.fan_supplierModelName__c = row.;
      //variantProduct.fan_hondaSparePartsProductType__c = row.PLAN_ZDA;
      //variantProduct.fan_hondaSparePartsProductClass__c = row.PLAN_ZDB;
    }

    System.debug('PRODUCT TO UPLOAD --> ' + variantProduct);

    return variantProduct;
  }

  // In UPSERT operations, specifying the type field produces an exception.
  public static void purgeTypeField(Map<String, Product2> parentProducts) {

    for (Product2 product : [SELECT IdProductoUNOEE__c FROM Product2 WHERE IdProductoUNOEE__c IN :parentProducts.keySet()]){
      Product2 variationParent = parentProducts.get(product.IdProductoUNOEE__c);
      // Do not change the assignment order.
      variationParent.Type = null;
      variationParent.Id = product.Id;
    }
  }

  public static ProductAttributeSetProduct[] generateProductAttributeSetProducts(Product2[] parentProducts) {

      Set<String> existingProductAttributeSetProducts = new Set<String>();
      ProductAttributeSetProduct[] productAttributeSetProducts = new List<ProductAttributeSetProduct>();
      String productAttributeId = [SELECT Id FROM ProductAttributeSet WHERE DeveloperName = 'Motos_Color'].Id;

      for(ProductAttributeSetProduct productAttributeSetProduct : [SELECT ProductId, ProductAttributeSetId FROM ProductAttributeSetProduct WHERE ProductId IN :parentProducts] ){
        existingProductAttributeSetProducts.add(productAttributeSetProduct.ProductId + '' + productAttributeSetProduct.ProductAttributeSetId);
      }

      for (Product2 product : parentProducts) {
        if(!existingProductAttributeSetProducts.contains(product.Id + '' + productAttributeId)){
          productAttributeSetProducts.add(new ProductAttributeSetProduct(
            ProductId = product.Id,
            ProductAttributeSetId = productAttributeId
            )
          );
        }
      }
      return productAttributeSetProducts;
  }

  static Set<String> getVariationProductIds(Product2[] childProducts) {
    Set<String> variationProductIds = new Set<String>();

    for(ProductAttribute productAttribute : [SELECT ProductId FROM ProductAttribute WHERE ProductId IN: childProducts]){
      variationProductIds.add(productAttribute.ProductId);
    }
    return variationProductIds;
  }

  public static ProductAttribute[] generateProductAttributes(Product2[] childProducts, Map<String, String[]> childMetadata, Map<String, Product2> parentProducts) {

      ProductAttribute[] productAttributes = new List<ProductAttribute>();
      Set<String> variationProductIds = getVariationProductIds(childProducts);

      for (Product2 product : childProducts) {

        String[] metadata = childMetadata.get(product.IdProductoUNOEE__c);
        String parentExternalId = metadata[0];
        String parentId = parentProducts.get(parentExternalId).Id;
        String color = metadata[1];

        if(!variationProductIds.contains(product.Id)) {
          productAttributes.add(new ProductAttribute(
            VariantParentId = parentId,
            ProductId = product.Id,
            fan_Color__c = color
            )
          );
        }
      }
      return productAttributes;
  }

  public static void validateSubstitutes(Map<String, Product2> posventaProducts, Map<String, Set<String>> substitutesByOriginalItem, Set<String> substituteIdentifiers) {

      final String SUBSTITUTE_TYPE = '3';
      Map<String, String> substitutes = new Map<String, String>();
      fan_RelatedProducts__c[] relatedProducts = new List<fan_RelatedProducts__c>();

      for (Product2 product : [SELECT IdProductoUNOEE__c FROM Product2 WHERE IdProductoUNOEE__c IN :substituteIdentifiers]) {
        substitutes.put(product.IdProductoUNOEE__c, product.Id);
      }

      for (String originalIdentifier : substitutesByOriginalItem.keySet()) {
        for (String substituteIdentifier : substitutesByOriginalItem.get(originalIdentifier)) {

          String substituteId = substitutes.get(substituteIdentifier);
          if(substituteId != null) {
            relatedProducts.add(new fan_RelatedProducts__c(
              fan_Source__c = posventaProducts.get(originalIdentifier).Id,
              fan_Target__c = substituteId,
              fan_RelationType__c = SUBSTITUTE_TYPE
            ));
          }
        }
      }
      DELETE [SELECT Id FROM fan_RelatedProducts__c WHERE fan_Source__c IN :posventaProducts.values() AND fan_RelationType__c = :SUBSTITUTE_TYPE];
      INSERT relatedProducts;
  }

  private static String validateField(String field) {
    return String.isBlank(field) || field == EMPTY_VALUE_KEY ? '' : field;
  }
}