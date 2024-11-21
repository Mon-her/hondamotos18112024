import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { productDetailsLabels } from 'c/fanLabels';
import getMotosAvailability from '@salesforce/apex/fan_OCIGetAvailability.getMotosAvailability';
import getPosventaAvailability from '@salesforce/apex/fan_OCIGetAvailability.getPosventaAvailability';

import { extractAvailability } from 'c/fanInventoryHandler';

import getWebStoreInformation from '@salesforce/apex/fan_B2BProductCtrl.getWebStoreInformation';
import getAvailabilityMapped from '@salesforce/apex/fan_B2BProductCtrl.getAvailabilityMapped';
import communityId from '@salesforce/community/Id';

// A fixed entry for the home page.
const homePage = {
    name: 'Home',
    type: 'standard__namedPage',
    attributes: {
        pageName: 'home'
    }
};

const InventoryStatus = {
    AVAILABLE: 'Disponible',
    LIMITED: 'Limitado',
    UNAVAILABLE: 'No Disponible'
};

const TIER_TYPE = { ADJUSTMENT_PERCENTAGE: 'AdjustmentPercentage' };
const MOTOS_STORE_NAME = 'Motos';

export default class fanProductDetailsDisplay extends NavigationMixin(
    LightningElement
) {
    /** Objects used in this component:
     * Product image
     * @typedef {object} Image
     * @property {string} url
     * @property {string} alternativeText

     * A product category.
     * @typedef {object} Category
     * @property {string} id
     * @property {string} name

     * Product prices and currency.
     * @typedef {object} Price
     * @property {string} listPrice
     * @property {string} unitPrice
     * @property {string} currency

     * A product field.
     * @typedef {object} CustomField
     * @property {string} name
     * @property {string} value

     * An iterable Field for display.
     * @typedef {CustomField} IterableField
     * @property {number} id
    */

    @api
    effectiveAccountId;

    /** Gets or sets the color options for the current product */
    @api
    colorOptions;

    /** Stores CPA, the key is shipping address code and the value is city */
    @api
    branches = {};
    @api
    get branchOptions() {
        return this._branchOptions;
    }

    set branchOptions(value) {
        this._branchOptions = value;
        this.getAvailability();
    }

    /** Id of current product */
    @api
    recordId;

    /** Gets or sets which custom fields should be displayed (if supplied) */
    @api
    customFields;

    /** Gets or sets the value to sku label. */
    @api
    skuLabel;

    /** Gets or sets the images of the product to display in the carousel */
    @api
    productMediaImages;

    /** Gets or sets the product name of the current variation product */
    @api
    productName;

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

    /** Gets or sets the value to inventory label status. */
     @api
     quantityAvailableLabel;

    /** Gets or sets the value to backorder label. */
    @api
    backorderLabel;

    /** Gets or sets backorder. */
    @api
    backorder;

    /** Gets or sets the value to tiered discounts label. */
    @api
    tieredDiscountsLabel;

    /** Gets or sets the value to show tiered discounts label and tiered discounts table. */
    @api
    isShowTieredDiscounts;

    /** Gets or sets the value to priceAdjustmentTiers to display its information */
    @api
    priceAdjustmentTiers;

    /** Gets or sets the value to quantity label. */
    @api
    quantityLabel;

    /** Gets or sets the value to "add to cart button" label. */
    @api
    addToCartLabel;

    /** Gets or sets the value to "add to list button" label. */
    @api
    addToListLabel;

    /** Gets or sets whether the cart is locked. */
    @api
    cartLocked;

    /** Gets or sets the name of the product. */
    @api
    description;

    /** Gets or sets the product image. */
    @api
    image;

    /** Gets or sets the name of the product. */
    @api
    name;

    /** Gets or sets the price - if known - of the product. */
    @api
    get price() {
        return this._price;
    }

    set price(value) {
        this._price = value;
    }

    /** Gets or sets the stock keeping unit (or SKU) of the product. */
    @api
    sku;

    @api
    reference;

    @api
    yearModel;

    /** Used to identify if the product is a variation parent to validate button access. */
    @api
    isVariationParent

    /** Used to identify if the product is a simple product to validate button access. */
    @api
    isSimpleProduct

    /** Gets or sets the wishlist. */
    @api
    wishlists;

    /** Gets or sets if the data is loading */
    @api
    loading = false;

    /** Gets or sets the selected address code from cache */
    @api
    selectedAddressCode;

    /** Gets or sets the selected color from cache */
    @api
    selectedColorOption;

    get inventoryStatus() {
        let status = InventoryStatus.UNAVAILABLE;
        const skuAvailability = JSON.parse(JSON.stringify(this._skuAvailability ?? {}));
        const available = extractAvailability(skuAvailability, this.sku, Infinity);
        const { CantidadLimitada__c: limitedQuantity = 0 } = this.mapCategoryQuantity ?? {};

        if(this._hasLimitedQuantityProduct && available > 0 && available <= limitedQuantity){
            status = InventoryStatus.LIMITED;
        } else if(available) {
            status = InventoryStatus.AVAILABLE;
        }
        return status;
    }

    get disableAddToCartBtn() {
        return this.isShowBranchPicker && (!this.selectedAddressCode || !this.selectedColorOption)
        || !this.price.listPrice || this.price.listPrice == 0;
    }

    get isStoreMotos(){
        return this.locationGroup?.includes(MOTOS_STORE_NAME);
    }

    // Local variables
    _quantityFieldValue = 1;
    _categoryPath;
    _resolvedCategoryPath = [];
    _hasLimitedQuantityProduct;
    _skuAvailability;
    _branchOptions;

    mapCategoryQuantity = {};

    // A bit of coordination logic so that we can resolve product URLs after the component is connected to the DOM,
    // which the NavigationMixin implicitly requires to function properly.
    _resolveConnected;
    _connected = new Promise((resolve) => {
        this._resolveConnected = resolve;
    });

    @wire(getWebStoreInformation, { communityId })
    getWebStoreInformation({ data, error }) {
        if(data) {
            console.log('Web Store Information -> ', data);
            const { fan_HasLimitedQuantityProduct__c, fan_LocationGroup__r } = data;
            this._hasLimitedQuantityProduct = fan_HasLimitedQuantityProduct__c
            this.locationGroup = fan_LocationGroup__r.ExternalReference;
            this.getAvailability();
        } else if(error) {
            console.log('Error in getWebStoreInformation -> ', error);
        }
    }

    connectedCallback() {
        this.loading = true;
        this._resolveConnected();
    }

    disconnectedCallback() {
        this._connected = new Promise((resolve) => {
            this._resolveConnected = resolve;
        });
    }

    /** Gets or sets the ordered hierarchy of categories to which the product belongs, ordered from least to most specific. */
    @api
    get categoryPath() {
        return this._categoryPath;
    }

    set categoryPath(newPath) {
        this._categoryPath = newPath;
        this.resolveCategoryPath(newPath || []);
    }

    /** Emits a notification that the user wants to add the item to their cart.
     *  @fires ProductDetailsDisplay#addtocart */
    notifyAddToCart() {
        this.dispatchEvent(
            new CustomEvent('addtocart', {
                detail: {
                    quantity: this._quantityFieldValue,
                    backorder: this.backorder,
                    contactPointAddressCode: this.selectedAddressCode
                }
            })
        );
    }

    // start wishlist
    get lastCategoryPath() {
        return ((this.categoryPath || []).at(-1) || {});
    }

    get isEmptyWishlists() {
        return !(this.wishlists || []).length;
    }

    get wishlistImage() {
        return this.carouselImages.length ? this.carouselImages[0] : undefined;
    }

    get label() {
        return productDetailsLabels();
    }

    get formattedPriceAdjustmentTiers() {
        return this.priceAdjustmentTiers
        .map(({ Id, LowerBound, UpperBound, TierType, TierValue }) => {

            const symbol = TierType === TIER_TYPE.ADJUSTMENT_PERCENTAGE ? '%' : '$';
            const formattedUpperBound = UpperBound ? `- ${UpperBound}` : '+' 

            return {
                id: Id,
                range: `${LowerBound} ${formattedUpperBound}`,
                adjustmentValue: `${TierValue} ${symbol}`
            };
        });
    }

    modalAddToWishlist = false;
    cannotSaveToWishlist = false;

    // Show modal when a close button is clicked
    openModalWishlist() {
        this.modalAddToWishlist = true;
    }

    // Hide modal when a close button is clicked
    closeModalWishlist() {
        this.cannotSaveToWishlist = false;
        this.modalAddToWishlist = false;
    }

    validateSelect(event) {
        const selectWishlist = this.template.querySelector('[data-id="select-wishlist"]');
        const createListInput = this.template.querySelector('[data-id="create-list-input"]');

        if (event.target.dataset.id === 'select-list-btn') {
            selectWishlist.disabled = !(createListInput.disabled = true);
            this.cannotSaveToWishlist = !selectWishlist.value;
        } else {
            createListInput.disabled = !(selectWishlist.disabled = true);
            this.cannotSaveToWishlist = !createListInput.value;
        }
    }

    handleWishlistChange(event) {
        this.cannotSaveToWishlist = !event.target.value;
    }

    handleWishlistNameChange(event) {
        this.cannotSaveToWishlist = !event.target.value;
    }

    /** Emits a notification that the user wants to add the item to a new wishlist.
     *  @fires ProductDetailsDisplay#addtowishlist */
    notifySaveToWishlist() {
        const action = this.template.querySelector('[data-id="create-list-btn"]').checked ? 'create' : 'add';
        const wishlistId = (this.template.querySelector('[data-id="select-wishlist"]') || {}).value;
        const wishlistName = this.template.querySelector('[data-id="create-list-input"]').value;

        this.dispatchEvent(new CustomEvent('addtowishlist', {
            detail: {
                action: action,
                wishlistId: wishlistId,
                wishlistName: action === 'create' ? wishlistName : this.wishlists.find(w => w.value === wishlistId).label
            }
        }));

        this.modalAddToWishlist = false;
    }
    // end wishlist

    /** Updates the breadcrumb path for the product, resolving the categories to URLs for use as breadcrumbs. */
    resolveCategoryPath(newPath) {
        const path = [homePage].concat(
            newPath.map((level) => ({
                name: level.name,
                type: 'standard__recordPage',
                attributes: {
                    actionName: 'view',
                    recordId: level.id
                }
            }))
        );

        this._connected
            .then(() => {
                const levelsResolved = path.map((level) =>
                    this[NavigationMixin.GenerateUrl]({
                        type: level.type,
                        attributes: level.attributes
                    }).then((url) => ({
                        name: level.name,
                        url: url
                    }))
                );

                return Promise.all(levelsResolved);
            })
            .then((levels) => {
                this._resolvedCategoryPath = levels;
                this.getAvailabilityMapped();
            });
    }

    /** Gets the iterable fields. */
    get _displayableFields() {
        // Enhance the fields with a synthetic ID for iteration.
        return (this.customFields || []).map((field, index) => ({
            ...field,
            id: index
        }));
    }

    // Change the main image product when someone clicks an image in the carousel
    changeProductImage(event) {

        const carouselImage = this.carouselImages.find(pmi => pmi.id === event.target.dataset.id);

        this.image = {
            id: carouselImage.id,
            url: carouselImage.url,
            alternativeText: carouselImage.alternateText
        };

        this.carouselImages.find(ci => ci.active).active = false;
        this.carouselImages.find(ci => ci.id === carouselImage.id).active = true;
    }

    // Determines if it is possible to zoom
    get isZoomable() {
        return !this.image.id;
    }

    // Determinates if it is possible to change the carousel image.
    get canChangeImageCarousel() {
        return this.carouselImages.length > 1;
    }

    // Simulates zoom for an image when main product image is clicked
    zoomImage() {
        this.modalGalleryCarousel = true;
    }

    // Hide modal gallery carousel when a close button is clicked
    hideModalBox() {
        this.modalGalleryCarousel = false;
    }

    // Flag to display modal gallery carousel
    modalGalleryCarousel = false;

    // Reactive property to handle when to show images in the carousel
    @track
    carouselImages = [];

    // Show carousel when exist images to display
    get isShowCarousel() {
        if (this.carouselImages.length != (this.productMediaImages || {}).length) {
            this.carouselImages = this.productMediaImages.map(pmi => Object.assign({}, pmi));
            this.carouselImages[0].active = true;
        }

        return this.carouselImages[0].id != undefined;
    }

    disablePreviousPageBtn = true;
    disableNextPageBtn = this.carouselImages.length < 5;

    // Change carousel page via show property
    changeCarouselPage(event) {
        if (event.target.dataset.name === 'previousPage') {
            this.disablePreviousPageBtn = !(this.disableNextPageBtn = false);
            this.carouselImages.forEach(i => i.show = !i.show)
        }
        else {
            this.disableNextPageBtn = !(this.disablePreviousPageBtn = false);
            this.carouselImages.forEach(i => i.show = !i.show)
        }
    }

    // Change carousel image via active property
    changeCarouselImage(event) {
        let i = this.carouselImages.findIndex(i => i.active);
        this.carouselImages[i].active = false;

        // Handle index to manipulate
        event.target.dataset.name === 'previousImage' ? i-- : i++;

        const s = this.carouselImages.length;
        const elementToActive = this.carouselImages[(i % s + s) % s];
        elementToActive.active = true;
        this.image = {
            id: elementToActive.id,
            url: elementToActive.url,
            alternativeText: elementToActive.alternateText
        };
    }

    handleQuantityChange({ detail }) {
        this._quantityFieldValue = detail.quantity;
    }

    handleBackorderChange(event) {
        this.backorder = event.target.checked;
    }

    /** Event used to update the variation product to the one selected from the swatches.
     *  Fires the custom event "updateproduct", listened by the parent component. */
    handleProductColorChange({ detail }) {
        this.loading = true;
        this.selectedColorOption = detail;

        const updateProduct = new CustomEvent("updateproduct", {
            detail: this.selectedColorOption
        });
        this.dispatchEvent(updateProduct);
    }

    handleAddressChange({ detail }) {
        this.selectedAddressCode = detail.value;
        // Save in session the selected address for next products selections
        sessionStorage.setItem('addressCode', this.selectedAddressCode);
        this.getAvailability();
    }

    getAvailabilityMapped() {
        getAvailabilityMapped()
            .then((result) => {
                let resultMap = {};

                if(this._resolvedCategoryPath.length > 0){
                    let resultCategory = this._resolvedCategoryPath[this._resolvedCategoryPath.length - 1];
                    resultMap = result[resultCategory.name.toUpperCase()];
                }
                this.mapCategoryQuantity = resultMap;
                console.log('getAvailabilityMapped mapCategoryQuantity -> ',this.mapCategoryQuantity);
            })
            .catch((e) => {
                // For this sample, we can just log the error
                console.log('Error getting metadata -> ', e);
            });
    }

    async getAvailability() {
        this.loading = true;
        try {
            if(this.branchOptions && this.locationGroup) {
                if(this.isStoreMotos) {
                    const city = this.branches[this.selectedAddressCode];
                    const skusByCity = { [city]: [this.sku] };

                    const jsonAvailability = await getMotosAvailability({ skusByCity });
                    this._skuAvailability = JSON.parse(jsonAvailability)[city];
                } else {
                    this._skuAvailability = await getPosventaAvailability({ communityId, skus: [this.sku] });
                }
                console.log('Sku availability.. ',this._skuAvailability);
            }
        } catch (error) {
            console.log('Error in getAvailability -> ',error);
        } finally {
            this.loading = false;
        }
    }
}