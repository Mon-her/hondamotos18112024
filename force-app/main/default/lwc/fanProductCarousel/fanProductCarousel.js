import { LightningElement, api } from 'lwc';
import communityId from '@salesforce/community/Id';
import getRelatedProductsBySourceId from "@salesforce/apex/fan_ProductCarouselController.getRelatedProductsBySourceId";
import getRelatedProductPickListValue from "@salesforce/apex/fan_ProductCarouselController.getRelatedProductPickListValue";
import getProducts from '@salesforce/apex/fan_B2BProductCtrl.getProducts';
import addToCart from '@salesforce/apex/fan_B2BCartCtrl.addToCart';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { productDetailsLabels } from 'c/fanLabels'
import basePathName from '@salesforce/community/basePath';
import { NavigationMixin } from 'lightning/navigation';
import { resolve } from 'c/fanCmsResourceResolver';

export default class FanProductCarousel extends NavigationMixin(LightningElement) {

    @api componentType = '';
    @api maxProductShow = 4;
    @api skuReferences = '';

    @api recordId = '';
    @api relationType = '';

    @api showPrice = false;
    @api showAddToCart = false;
    @api showViewOptions = false;
    @api showProductName = false;
    @api showSkuProduct = false;
    @api showYearModel = false;

    @api effectiveAccountId;
    @api addToCartLabel = 'ADD TO CART';
    @api viewOptionsLabel = 'SHOW OPTIONS';

    areDetailsVisible = false;
    mapProductBySKU = {};
    accountId = '';
    error = {};

    productList = [];
    picklistValue = [];
    typeSelected = '1';
    isRelatedProducts = false;
    maxProductShowRelated = 0;

    hasProductsToShow = false;
    showCarouselChevron = false;
    layoutSize = 10;

    resultPathName = '';
    recordPageUrl = '';

        /**
     * A Promise-resolver to invoke when the component is a part of the DOM.
     *
     * @type {Function}
     * @private
     */
         _connectedResolver;

         /**
          * A Promise that is resolved when the component is connected to the DOM.
          *
          * @type {Promise}
          * @private
          */
         _canResolveUrls = new Promise((resolved) => {
             this._connectedResolver = resolved;
         });

    connectedCallback() {
        this._connectedResolver();
        this.handleLoad();
    }

    disconnectedCallback() {
        // We've beeen disconnected, so reset our Promise that reflects this state.
        this._canResolveUrls = new Promise((resolved) => {
            this._connectedResolver = resolved;
        });
    }

    handleLoad() {

        var splitPath = basePathName.split('/');
        this.resultPathName = splitPath[1];

        if (this.relationType == 'CrossSell') {
            this.typeSelected = '1';
        } else if (this.relationType == 'UpSell') {
            this.typeSelected = '2';
        } else {
            this.typeSelected = '3';
        }

        this.maxProductShowRelated = 'product-container slds-p-around_x-small slds-col slds-size_1-of-'+this.maxProductShow;

        this.accountId = this.resolvedEffectiveAccountId;
        this.getRelatedPickListValue();
        if (this.recordId) {
            this.getRelatedProductById();
            this.isRelatedProducts = true;
        } else {
            this.getProductsInit();
        }
    }

    getRelatedPickListValue() {
        getRelatedProductPickListValue().then(result => {
            this.picklistValue = result;
        }).catch(error => {
            this.error = error;
        });
    }

    getAccountIdFromUser() {
        getAccountInfoFromUser().then(result => {
            this.accountId = result;
            this.getProductsInit();
        }).catch(error => {
            this.error = error;
        });
    }

    getRelatedProductById() {
        getRelatedProductsBySourceId({
            'productSourceId': this.recordId,
            'relatedProduct': this.typeSelected
        }).then(result => {
            let data = JSON.parse(JSON.stringify(result));
            this.skuReferences = data ? data.join(';') : [];
            if (this.skuReferences.length > 0) { this.getProductsInit() };
        }).catch(error => {
            this.error = error;
        });
    }

    getProductsInit() {
        console.log('Skus -> ',this.skuReferences.split(";"));
        getProducts({
            'communityId': communityId,
            'effectiveAccountId': this.accountId,
            'lstSKU': this.skuReferences ? this.skuReferences.split(";") : [],
            'lstFields': ['Name', 'StockKeepingUnit', 'Id', 'Referencia__c', 'fan_YearModel__c']
        }).then(result => {
            const generatedUrls = [];
            let data = JSON.parse(JSON.stringify(result));
            console.log('Product carousel --> ',data);
            this.areDetailsVisible = false;
            for (var productIndex in data.products) {
                // If product doesnt have Id, the product was not found
                if (data.products[productIndex].id == null) continue;
                let productData = data.products[productIndex];

                let productImg = productData.defaultImage ? resolve(productData.defaultImage.url) : '';
                let productPrice = productData.prices ? productData.prices.unitPrice : '';

                this.productList.push({
                    Id: productData.id,
                    productName: productData.fields.Name,
                    productSKU: productData.fields.Referencia__c,
                    productYear: productData.fields.fan_YearModel__c,
                    productPrice: productPrice,
                    productImg: productImg
                });
            }

            for (let iteratorObj in this.productList) {
                let dataKey = this.productList[iteratorObj];
                this.mapProductBySKU[dataKey.Id] = dataKey;
            }
            this.areDetailsVisible = true;

            this.hasProductsToShow = this.productList.length > 0;
            this.showCarouselChevron = this.productList.length > this.maxProductShow;
            this.layoutSize = this.showCarouselChevron ? 10 : 12;

        }).catch(error => {
            this.error = error;
        });
    }

    leftButton() {
        this.areDetailsVisible = false;
        this.productList.unshift(this.productList.pop());
        this.areDetailsVisible = true;
    }

    rightButton() {
        this.areDetailsVisible = false;
        this.productList.push(this.productList.shift());
        this.areDetailsVisible = true;
    }

    addToCart(event) {

        let btnSplit = event.currentTarget.id.split('-');
        let btnId = btnSplit[0];
        let product = this.mapProductBySKU[btnId];

        const cartItem = {
            Product2Id: product.Id,
            Quantity: 1,
            fan_IsBackorder__c: false
        };
        addToCart({
            communityId: communityId,
            productId: product.Id,
            quantity: "1",
            effectiveAccountId: this.accountId,
            cartItem
        })
            .then(() => {
                this.dispatchEvent(
                    new CustomEvent('cartchanged', {
                        bubbles: true,
                        composed: true
                    })
                );
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: productDetailsLabels().success,
                        message: productDetailsLabels().cartHasBeenUpdated,
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: productDetailsLabels().error,
                        message: productDetailsLabels().addToCartErrorPDP,
                        messageData: [this.displayableProduct.name],
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
    }

    get resolvedEffectiveAccountId() {
        const effectiveAccountId = this.effectiveAccountId || '';
        let resolved = null;

        if (
            effectiveAccountId.length > 0 &&
            effectiveAccountId !== '000000000000000'
        ) {
            resolved = effectiveAccountId;
        }
        return resolved;
    }

    onRedirectProduct(event){
        let btnSplit = event.currentTarget.id.split('-');
        let btnId = btnSplit[0];

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: btnId,
                actionName: 'view'
            }
        });


    }

}