import { LightningElement, wire, api } from 'lwc';

import communityId from '@salesforce/community/Id';
import getProduct from '@salesforce/apex/fan_B2BProductCtrl.getProduct';
import getCartSummary from '@salesforce/apex/fan_B2BCartCtrl.getCartSummary';
import addToCart from '@salesforce/apex/fan_B2BCartCtrl.addToCart';
import createAndAddToWishlist from '@salesforce/apex/fan_B2BWishlistCtrl.createAndAddToWishlist';
import addToWishlist from '@salesforce/apex/fan_B2BWishlistCtrl.addToWishlist'
import getWishlistSummaries from '@salesforce/apex/fan_B2BWishlistCtrl.getWishlistSummaries'
import getProductPrice from '@salesforce/apex/fan_B2BProductCtrl.getProductPrice';
import getProductAttributes from '@salesforce/apex/fan_B2BProductCtrl.getProductAttributes';
import getPriceAdjustmentTiers from '@salesforce/apex/fan_PromotionCtrl.getPriceAdjustmentTiers'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { resolve } from 'c/fanCmsResourceResolver';
import { productDetailsLabels } from 'c/fanLabels'
import getProductVariations from '@salesforce/apex/fan_B2BProductCtrl.getProductVariations';
import getShippingAddressList from '@salesforce/apex/fan_B2BAccountCtrl.getShippingAddressList';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

/**
 * A detailed display of a product.
 * This outer component layer handles data retrieval and management, as well as projection for internal display components.
 */
export default class fanProductDetails extends NavigationMixin(LightningElement) {
    /** Gets the effective account - if any - of the user viewing the product. */
    @api
    get effectiveAccountId() {
        return this._effectiveAccountId;
    }

    /** Sets the effective account - if any - of the user viewing the product and fetches updated cart information */
    set effectiveAccountId(newId) {
        this._effectiveAccountId = newId;
        this.updateCartInformation();
    }

    /** Gets or sets the unique identifier of a product. */
    @api
    recordId;

    /** Gets or sets the custom fields to display on the product in a comma-separated list of field names */
    @api
    customDisplayFields;

    /** Gets or sets the value to sku label. */
    @api
    skuLabel;

    /** Gets or sets the value to branch picker label. */
    @api
    branchPickerLabel;

    /** Gets or sets the value to show branch picker label and branch picker. */
    @api
    isShowBranchPicker;

    /** Gets or sets the value to color picker label. */
    @api
    colorPickerLabel;
    
    /** Gets or sets the value to show color picker label and color picker. */
    @api
    isShowColorPicker;

    /** Gets or sets the value to public price label. */
    @api
    publicPriceLabel;

    /** Gets or sets the value to show spot price label and spot price. */
    @api
    isShowSpotPrice;

    /** Gets or sets the value to spot price label. */
    @api
    spotPriceLabel;

    /** Gets or sets the value to show credit price label and credit price value. */
    @api
    isShowCreditPrice;

    /** Gets or sets the value to credit price label. */
    @api
    creditPriceLabel;

    /** Gets or sets the value to show dealer price label and dealer price value. */
    @api
    isShowDealerPrice;

    /** Gets or sets the value to dealer price label. */
    @api
    dealerPriceLabel;

    /** Gets or sets the value to inventory label. */
    @api
    inventoryLabel;

    /** Gets or sets the value to quantity inventory label. */
     @api
     quantityAvailableLabel

    /** Gets or sets the value to backorder label. */
    @api
    backorderLabel;

    /** Gets or sets backorder. */
    @api
    backorder = false;

    /** Gets or sets the value to tiered discounts label. */
    @api
    tieredDiscountsLabel;

    /** Gets or sets the value to show tiered discounts label and tiered discounts table. */
    @api
    isShowTieredDiscounts;

    /** Gets or sets the value to quantity label. */
    @api
    quantityLabel;

    /** Gets or sets the value to "add to cart button" label. */
    @api
    addToCartLabel;

    /** Gets or sets the value to "add to list button" label. */
    @api
    addToListLabel;

    selectedAddressCode;

    @api
    selectedColorOption = '';

    /** Gets or sets the wishlists for the context user. */
    wishlists;

    /** The cart summary information from ConnectApi.CartSummary */
    cartSummary;

    /** The color options available for the current product */
    colorOptions = [];

    /** Object where the key is shipping address code and the value is city. */
    branches = {};

    /** The shipping address options available for the current user */
    branchOptions = [];

    /** Used to send the variation product name to the child component in order to refresh website */
    productName;

    /** If the current product is the parent product of a variant group */
    isVariationParent;

    /** If the current product is a simple product (AKA not a variation product) */
    isSimpleProduct;

    /** Save the tier adjustments of the product if exists */
    priceAdjustmentTiers = [];

    /** The current page */
    @wire(CurrentPageReference)
    fetchCurrentPageReference(pageReference) {
        const addressCode = pageReference.state.branch;
        if(addressCode && !this.selectedAddressCode) {
            this.selectedAddressCode = addressCode;
        }
    }

    /** The full product information retrieved from ConnectApi.ProductDetail */
    @wire(getProduct, {
        communityId: communityId,
        productId: '$recordId',
        effectiveAccountId: '$resolvedEffectiveAccountId'
    })
    product;

    /** The price of the product for the user, if any. */
    productPrice;

    /** The connectedCallback() lifecycle hook fires when a component is inserted into the DOM. */
    connectedCallback() {
        if (this.isShowBranchPicker == true) this.backorder = true;
        this.updateCartInformation();
        this.fetchProductPrice();
        this.fetchWishlistSummaries();
        if(this.isShowTieredDiscounts) {
            this.fetchPriceAdjustmentTiers();
        }
    }

    fetchWishlistSummaries() {
        getWishlistSummaries({
            communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            includeDisplayedList: false
        }).then(({ summaries }) => {
            this.wishlists = summaries.map(({ id, name }) => ({
                value: id,
                label: name
            }));
        }).catch(error => {
            console.log('Error in getWishlistSummaries -->' + error);
        })
    }

    /** Gets the normalized effective account of the user. */
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

    /** Gets whether product information has been retrieved for display. */
    get hasProduct() {
        return this.product.data !== undefined;
    }

    /** Obtain images of the product to display in the carousel */
    resolveProductMediaImages(mediaGroups) {
        return mediaGroups.find(mg => mg.usageType === 'Standard')
        .mediaItems
        .filter(mi => mi.mediaType === 'Image')
        .map((mi, index) => {
            const pmi = {...mi};
            pmi.url = resolve(pmi.url);
            pmi.show = index < 4
            return pmi;
        });
    }

    /** Gets the normalized, displayable product information for use by the display components. */
    get displayableProduct() {
        const { currencyIsoCode: currency, unitPrice, listPrice } = this.productPrice ?? {};
        return {
            categoryPath: this.product.data.primaryProductCategoryPath.path.map(
                (category) => ({
                    id: category.id,
                    name: category.name
                })
            ),
            description: this.product.data.fields.Description,
            image: {
                id: this.product.data.defaultImage.id,
                alternativeText: this.product.data.defaultImage.alternativeText,
                url: resolve(this.product.data.defaultImage.url)
            },
            name: this.product.data.fields.Name,
            price: { currency, listPrice, unitPrice },
            reference: this.product.data.fields.Referencia__c,
            sku: this.product.data.fields.StockKeepingUnit,
            yearModel: this.product.data.fields.fan_YearModel__c,
            productMediaImages: this.resolveProductMediaImages(this.product.data.mediaGroups),
            customFields: Object.entries(
                this.product.data.fields || Object.create(null)
            )
                .filter(([key]) =>
                    (this.customDisplayFields || '').includes(key)
                )
                .map(([key, value]) => ({ name: key, value }))
        };
    }

    /** Gets whether the cart is currently locked, Returns true if the cart status is different to either active or checkout  */
    get _isCartLocked() {
        const cartStatus = (this.cartSummary || {}).status;
        return (cartStatus != "Active" && cartStatus != "Checkout");
    }

    /** Handles a user request to add the product to their active cart.
     *  On success, a success toast is shown to let the user know the product was added to their cart
     *  If there is an error, an error toast is shown with a message explaining that the product could not be added to the cart
     *  Toast documentation: https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_toast  */
    addToCart(event) {

        const cartItem = {
            Product2Id: this.recordId,
            Quantity: event.detail.quantity,
            fan_IsBackorder__c: event.detail.backorder,
        };

        this.template.querySelector('c-fan-product-details-display').loading = true;
        addToCart({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            contactPointAddressCode: event.detail.contactPointAddressCode,
            cartItem
        }).then(() => {
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
        }).catch((error) => {
            console.log('Error in addToCart --> ', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: productDetailsLabels().error,
                    message: productDetailsLabels().addToCartErrorPDP,
                    messageData: [this.displayableProduct.name],
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
        }).finally(() => {
            this.template.querySelector('c-fan-product-details-display').loading = false;
        });
    }

    /** Handles a user request to add the product to a newly created or existing wishlist.
     *  On success, a success toast is shown to let the user know the product was added to a new or existing list
     *  If there is an error, an error toast is shown with a message explaining that the product could not be added to a list
     *  Toast documentation: https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_toast */
    addToWishlist(event) {
        const wishlistId = event.detail.wishlistId;
        const wishlistName = event.detail.wishlistName;

        if(event.detail.action === 'create')
            createAndAddToWishlist({
                communityId: communityId,
                productId: this.recordId,
                wishlistName: wishlistName,
                effectiveAccountId: this.resolvedEffectiveAccountId
            }).then(({ summary }) => {
                const { id, name } = summary;
                this.dispatchEvent(new CustomEvent('createandaddtolist'));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: productDetailsLabels().success,
                        message: productDetailsLabels().addToNewWishlistSucess,
                        messageData: [this.displayableProduct.name, name],
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.wishlists = [...this.wishlists, { label: name, value: id }];
            }).catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: productDetailsLabels().error,
                        message: productDetailsLabels().addToNewWishlistError,
                        messageData: [this.displayableProduct.name],
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
        else
            addToWishlist({
                communityId: communityId,
                productId: this.recordId,
                wishlistId: wishlistId
            })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: productDetailsLabels().success,
                        message: productDetailsLabels().addToWishlistSucess,
                        messageData: [wishlistName],
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
            })
            .catch(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: productDetailsLabels().addToWishlistError,
                        messageData: [this.displayableProduct.name, wishlistName],
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
    }

    /** Ensures cart information is up to date */
    updateCartInformation() {
        getCartSummary({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId
        }).then((result) => {
            this.cartSummary = result;
        }).catch((e) => {
            // Handle cart summary error properly
            // For this sample, we can just log the error
            console.log('Error in getCartSummary --> ', e);
        });
    }

    async getProductAttributes(variationParentId) {
        const productAttributes = await getProductAttributes({ variationParentId });

        return productAttributes.reduce((accumulator, { fan_Color__c, Product }) => {
            const { Id, fan_swatch__c } = Product;

            accumulator[Id] = {
                title: fan_Color__c,
                url: resolve(fan_swatch__c)
            };
            return accumulator;
        }, {});
    }

    /** Gets the product color variations of the products */
    @wire(getProductVariations, {
        communityId: communityId,
        productId: '$recordId',
        effectiveAccountId: '$resolvedEffectiveAccountId'
    })
    async getColorOptions({data, error}){
        if(data){
            console.log('Color options -> ',data);
            
            let productType = data.variationInfo == null;

            console.log('Product Type -> ',productType);

            if(!productType){
                this.isSimpleProduct = false;
                this.isVariationParent = data.variationParentId == null;
                const productAttributes = await this.getProductAttributes(data.variationParentId ?? data.id)

                this.colorOptions = data.variationInfo.attributesToProductMappings
                .map(({ productId }) => {
                    const { url, title } = productAttributes[productId];
                    return { id: productId, url, title };
                });

                if (Object.prototype.hasOwnProperty.call(productAttributes, this.recordId)) {
                    this.selectedColorOption = this.recordId;
                }
            }
            else{
                this.isSimpleProduct = true;
                this.isVariationParent = false;
            }
        }
        else if(error){
            console.log(error);
        }
    }

    /** Gets the branch options available for the user */
    @wire(getShippingAddressList, {
        accountId: '$resolvedEffectiveAccountId'
    })
    getBranchOptions({data, error}){
        if(data){
            this.branches = data.reduce((accumulator, { City, fan_Code__c }) => {
                accumulator[fan_Code__c] = City;
                return accumulator;
            }, {});
            // Se itera por los distintos branches disponibles para el usuario y se guardan como opciones
            this.branchOptions = data.map(({ fan_Code__c: value, Name: label }) => ({ label, value }));
            this.resolveAddressCodeFromCache();
        }
        else if(error){
            console.log(error);
        }
    }

    async fetchPriceAdjustmentTiers() {
        this.priceAdjustmentTiers = await getPriceAdjustmentTiers({
            effectiveAccountId: this.resolvedEffectiveAccountId,
            productId: this.recordId
        });
    }

    resolveAddressCodeFromCache() {
        const addressCode = sessionStorage.getItem('addressCode');
        console.log('SessionStorage CPA ', this.addressCode)

        const existsBranchOption = this.branchOptions.some(({ value }) => addressCode === value);
        if (existsBranchOption) {
            this.selectedAddressCode = addressCode;
        } else {
            sessionStorage.removeItem('addressCode');
        }
    }

    /** Handler for child component's custom event "updateproduct"
     *  Refreshes the website with the product selected */
    handleVariantProductUpdate(event){
        //this.getProductName(event.detail);
        getProductVariations({
            'communityId' : communityId,
            'productId' : event.detail,
            'effectiveAccountId' : this.effectiveAccountId
        }).then(data => {
            this.uploadNewVariantProduct(event.detail);
            //this.validateVariationParent(data.fields);
        }).catch(error => {
            console.log('ERROR', error);
        });
    }
    
    /** Refreshes the website to display the newly selected variant product */
    uploadNewVariantProduct(variantProductId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: variantProductId,
                objectApiName: 'Product2',
                actionName: 'view'
            },
            state: {
                branch: this.selectedAddressCode
            }
        });
    }

    fetchProductPrice() {
        getProductPrice({
            communityId: communityId,
            productId: this.recordId,
            effectiveAccountId: this.resolvedEffectiveAccountId
        }).then((productPrice) => {
            this.productPrice = productPrice;
        }).catch(error => {
            console.log('Error with getProductPrice --> ', error);
        });
    }
}