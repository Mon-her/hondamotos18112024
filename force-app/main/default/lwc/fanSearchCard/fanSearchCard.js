import { LightningElement, api } from 'lwc';

import { resolve } from 'c/fanCmsResourceResolver';
import { searchCardLabels } from 'c/fanLabels'

/**
 * An organized display of a single product card.
 *
 * @fires SearchCard#calltoaction
 * @fires SearchCard#showdetail
 */
export default class FanSearchCard extends LightningElement {
    /**
     * An event fired when the user clicked on the action button. Here in this
     *  this is an add to cart button.
     *
     * Properties:
     *   - Bubbles: true
     *   - Composed: true
     *   - Cancelable: false
     *
     * @event SearchLayout#calltoaction
     * @type {CustomEvent}
     *
     * @property {String} detail.productId
     *   The unique identifier of the product.
     *
     * @export
     */

    /**
     * An event fired when the user indicates a desire to view the details of a product.
     *
     * Properties:
     *   - Bubbles: true
     *   - Composed: true
     *   - Cancelable: false
     *
     * @event SearchLayout#showdetail
     * @type {CustomEvent}
     *
     * @property {String} detail.productId
     *   The unique identifier of the product.
     *
     * @export
     */

    /**
     * A result set to be displayed in a layout.
     * @typedef {object} Product
     *
     * @property {string} id
     *  The id of the product
     *
     * @property {string} name
     *  Product name
     *
     * @property {Image} image
     *  Product Image Representation
     *
     * @property {Array} fields
     *  Map containing field name as the key and it's field value inside an object.
     *
     * @property {Prices} prices
     *  Negotiated and listed price info
     */

    /**
     * A product image.
     * @typedef {object} Image
     *
     * @property {string} url
     *  The URL of an image.
     *
     * @property {string} alternativeText
     *  The alternative display text of the image.
     */

    /**
     * Prices associated to a product.
     *
     * @typedef {Object} Pricing
     *
     * @property {string} listPrice
     *  Original price for a product.
     *
     *
     * @property {string} currencyIsoCode
     *  The ISO 4217 currency code for the product card prices listed
     */

    /**
     * Card layout configuration.
     * @typedef {object} CardConfig
     *
     * @property {Boolean} showImage
     *  Whether or not to show the product image.
     *
     * @property {string} resultsLayout
     *  Products layout. This is the same property available in it's parent
     *  {@see LayoutConfig}
     *
     * @property {Boolean} actionDisabled
     *  Whether or not to disable the action button.
     */

    /**
     * Gets or sets the display data for card.
     *
     * @type {Product[]}
     */
    @api
    variants;

    get selectedProduct() {
        return this._selectedProduct ?? this.variants?.[0];
    }

    set selectedProduct(value) {
        this._selectedProduct = value;
    }

    _selectedProduct;

    /**
     * Gets or sets the card layout configurations.
     *
     * @type {CardConfig}
     */
    @api
    config;

    @api
    branch;

    @api
    isAddToCartDisabled;

    /**
     * Gets the product image.
     *
     * @type {Image}
     * @readonly
     * @private
     */
    get image() {
        return this.selectedProduct.image ?? {};
    }

    /**
     * Gets the product fields.
     *
     * @type {Array}
     * @readonly
     * @private
     */
    get fields() {
        return this.selectedProduct.fields.map((value, id) => ({
            id: id + 1,
            tabIndex: id === 0 ? 0 : -1,
            // making the first field bit larger
            class: id
                ? 'slds-truncate slds-text-heading_small'
                : 'slds-truncate slds-text-heading_medium',
            // making Name and Description shows up without label
            // Note that these fields are showing with apiName. When builder
            // can save custom JSON, there we can save the display name.
            value
        }));
    }

    /**
     * Whether or not the product image to be shown on card.
     *
     * @type {Boolean}
     * @readonly
     * @private
     */
    get showImage() {
        return !!(this.config || {}).showImage;
    }

    /**
     * Whether or not disable the action button.
     *
     * @type {Boolean}
     * @readonly
     * @private
     */
    get actionDisabled() {
        return this.isAddToCartDisabled || this.hasnotPrice || !this.branch;
    }

    /**
     * Gets the product price.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get price() {
        const { prices } = this.selectedProduct;
        return prices?.listPrice;
    }

    /**
     * Whether or not the product has price.
     *
     * @type {Boolean}
     * @readonly
     * @private
     */
    get hasPrice() {
        return !!Number(this.price);
    }

    get hasnotPrice() {
        return !this.hasPrice;
    }

    /**
     * Gets the currency for the price to be displayed.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get currency() {
        return this.selectedProduct.prices.currencyIsoCode;
    }

    /**
     * Gets the container class which decide the innter element styles.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get cardContainerClass() {
        return this.config.resultsLayout === 'grid'
            ? 'card-layout-grid'
            : 'card-layout-list';
    }

    get swatches() {
        return this.variants.map(({ id, swatch }) => {
            const { title, url } = swatch;
            return { id, title, url: resolve(url) };
        });
    }

    get label() {
        return searchCardLabels();
    }

    get addToCartTitle() {
        let title = '';
        if(this.hasnotPrice) {
            title = this.label.productHasnotPrice;
        } else if(!this.branch) {
            title = this.label.selectBranch;
        }
        return title;
    }

    quantity = 1;

    /**
     * Emits a notification that the user wants to add the item to their cart.
     *
     * @fires SearchCard#calltoaction
     * @private
     */
    notifyAction() {

        const { id, name } = this.selectedProduct;

        this.dispatchEvent(
            new CustomEvent('calltoaction', {
                bubbles: true,
                composed: true,
                detail: {
                    productId: id,
                    productName: name,
                    quantity: this.quantity
                }
            })
        );
    }

    /**
     * Emits a notification that the user indicates a desire to view the details of a product.
     *
     * @fires SearchCard#showdetail
     * @private
     */
    notifyShowDetail(evt) {
        evt.preventDefault();

        this.dispatchEvent(
            new CustomEvent('showdetail', {
                bubbles: true,
                composed: true,
                detail: { productId: this.selectedProduct.id }
            })
        );
    }

    handleSwatchChange({ detail }) {
        this.selectedProduct = this.variants.find(({ id }) => id === detail);
    }

    handleQuantityChange({ detail }) {
        this.quantity = detail.quantity;
    }
}