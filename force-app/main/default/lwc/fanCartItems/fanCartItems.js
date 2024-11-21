import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import { resolve } from 'c/fanCmsResourceResolver';

import { cartItemsLabels } from 'c/fanLabels';
import { expandCollapseButton } from 'c/fanLabels';

import cartitemsTemplate from './fanCartItems.html';
import groupedCartitemsTemplate from './fanGroupedCartItems.html';

const QUANTITY_CHANGED_EVT = 'quantitychanged';
const BACKORDER_CHANGED_EVT = 'backorderchanged';
const SINGLE_CART_ITEM_DELETE = 'singlecartitemdelete';

/**
 * A non-exposed component to display cart items.
 *
 * @fires Items#quantitychanged
 * @fires Items#singlecartitemdelete
 * @fires Items#backorderchanged
 */
export default class FanCartItems extends NavigationMixin(LightningElement) {
    /**
     * An event fired when the quantity of an item has been changed.
     *
     * @event Items#quantitychanged
     * @type {CustomEvent}
     *
     * @property {string} detail.id
     *   The unique identifier of an item.
     *
     * @property {number} detail.quantity
     *   The new quantity of the item.
     *
     * @export
     */

    /**
     * An event fired when the user triggers the removal of an item from the cart.
     *
     * Properties:
     *   - Bubbles: true
     *   - Cancelable: false
     *   - Composed: true
     *
     * @event Items#singlecartitemdelete
     * @type {CustomEvent}
     *
     * @property {string} detail.cartItemId
     *   The unique identifier of the item to remove from the cart.
     *
     * @export
     */

    /**
     * An event fired when the backorder of an item has been changed.
     *
     * @event Items#quantitychanged
     * @type {CustomEvent}
     *
     * @property {string} detail.itemId
     *   The unique identifier of an item.
     *
     * @property {number} detail.backorder
     *   The new backorder of the item.
     *
     * @export
     */

    /**
     * A cart line item.
     *
     * @typedef {Object} CartItem
     *
     * @property {ProductDetails} productDetails
     *   Representation of the product details.
     *
     * @property {string} originalPrice
     *   The original price of a cart item.
     *
     * @property {number} quantity
     *   The quantity of the cart item.
     *
     * @property {string} totalPrice
     *   The total sales price of a cart item.
     *
     * @property {string} totalListPrice
     *   The total original (list) price of a cart item.
     *
     * @property {string} unitAdjustedPrice
     *   The cart item price per unit based on tiered adjustments.
     * 
     * @property {boolean} color
     *   The cart item color.
     * 
     * @property {boolean} backorder
     *   The cart item backorder.
     * 
     * @property {CartDeliveryGroup} cartDeliveryGroup
     *   The cart item backorder.
     */

    /**
     * Details for a product containing product information
     *
     * @typedef {Object} ProductDetails
     *
     * @property {string} productId
     *   The unique identifier of the item.
     *
     * @property {string} sku
     *  Product SKU number.
     *
     * @property {string} name
     *   The name of the item.
     *
     * @property {ThumbnailImage} thumbnailImage
     *   The image of the cart line item
     *
     */

    /**
     * Image information for a product.
     *
     * @typedef {Object} ThumbnailImage
     *
     * @property {string} alternateText
     *  Alternate text for an image.
     *
     * @property {string} title
     *   The title of the image.
     *
     * @property {string} url
     *   The url of the image.
     */

    /**
     * The ISO 4217 currency code for the cart page
     *
     * @type {string}
     */
    @api
    currencyCode;

    /** Flag that defines when to show the dealer price.  */
    @api
    isDealerPriceVisible;

    /**
     * Control the visibility to display color element
     *
     * @type {boolean}
     */
    @api
    showColor = false;

    /**
     * Control the visibility to display grouped cart items
     *
     * @type {boolean}
     */
    @api
    groupByBranch = false;

    /**
     * The product title option to display in product detail
     *
     * @type {string}
     */
    @api
    productTitleOption;

    /**
     * Decision on which field to take as the item title of the cart
     *
     * @private
     */
    get nameAsTitle() {
        return this.productTitleOption === 'name';
    }

    /**
     * A list of CartItems
     *
     * @type {CartItem[]}
     */
    @api
    get cartItems() {
        return this._providedItems;
    }

    set cartItems(items) {
        this._providedItems = items;
        const generatedUrls = [];
        this._items = (items || []).map((item) => {
            // Create a copy of the item that we can safely mutate.
            const newItem = { ...item };
            // Set default value for productUrl
            newItem.productUrl = '';
            // Get URL of the product image.
            newItem.productImageUrl = resolve(
                item.cartItem.productDetails.thumbnailImage.url
            );
            // Set the alternative text of the image(if provided).
            // If not, set the null all text (alt='') for images.
            newItem.productImageAlternativeText =
                item.cartItem.productDetails.thumbnailImage.alternateText || '';

            // Get URL for the product, which is asynchronous and can only happen after the component is connected to the DOM (NavigationMixin dependency).
            const urlGenerated = this._canResolveUrls
                .then(() =>
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: newItem.cartItem.productId,
                            objectApiName: 'Product2',
                            actionName: 'view'
                        }
                    })
                )
                .then((url) => {
                    newItem.productUrl = url;
                });
            generatedUrls.push(urlGenerated);
            return newItem;
        });

        // When we've generated all our navigation item URLs, update the list once more.
        Promise.all(generatedUrls).then(() => {
            this._items = Array.from(this._items);
            this._items.forEach(item => {
                if (item.cartItem.disableBackorder) this.template.querySelector('[data-item-id="'+item.cartItem.cartItemId+'"]').setAttribute('disabled','');
                else this.template.querySelector('[data-item-id="'+item.cartItem.cartItemId+'"]').removeAttribute('disabled');
            })
        });
    }

    /**
     * A normalized collection of items suitable for display.
     *
     * @private
     */
    _items = [];

    /**
     * A list of provided cart items
     *
     * @private
     */
    _providedItems;

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

    // The active sections
    activeAccordionSections = [];

    /**
     * This lifecycle hook fires when this component is inserted into the DOM.
     */
    connectedCallback() {
        // Once connected, resolve the associated Promise.
        this._connectedResolver();
    }

    /**
     * This lifecycle hook fires when this component is removed from the DOM.
     */
    disconnectedCallback() {
        // We've beeen disconnected, so reset our Promise that reflects this state.
        this._canResolveUrls = new Promise((resolved) => {
            this._connectedResolver = resolved;
        });
    }

    /**
     * Gets the available labels.
     *
     * @type {Object}
     *
     * @readonly
     * @private
     */
    get labels() {
        return cartItemsLabels();
    }

    /**
     * Gets the available labels for the accordion buttons.
     *
     * @type {Object}
     *
     * @readonly
     * @private
     */
    get labelsAccordion() {
        return expandCollapseButton();
    }

    /**
     * Handler for the 'click' event fired from 'contents'
     *
     * @param {Object} evt the event object
     */
    handleProductDetailNavigation(evt) {
        evt.preventDefault();
        const productId = evt.target.dataset.productid;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: productId,
                actionName: 'view'
            }
        });
    }

    /**
     * Fires an event to delete a single cart item
     * @private
     * @param {ClickEvent} clickEvt A click event.
     * @fires Items#singlecartitemdelete
     */
    handleDeleteCartItem(clickEvt) {
        const cartItemId = clickEvt.target.dataset.cartitemid;
        this.dispatchEvent(
            new CustomEvent(SINGLE_CART_ITEM_DELETE, {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    cartItemId
                }
            })
        );
    }

    /**
     * Handler for the 'quantitychanged' event fired from Quantity Handler component and
     * fires an event to update the cart item quantity.
     *
     * @param {Event} event
     *  A 'quanitychanged' event fire from the Quantity Handler component
     * @fires Items#quantitychanged
     * @private
     */
    handleQuantityChange(event) {

        // Get the item ID off this item so that we can add it to a new event.
        const cartItemId = event.detail.itemId;
        // Get the quantity off the control, which exposes it.
        const quantity = event.detail.quantity;

        // Fire a new event with extra data.
        this.dispatchEvent(
            new CustomEvent(QUANTITY_CHANGED_EVT, {
                detail: {
                    cartItemId,
                    quantity
                }
            })
        );
    }

    // To group cart items using display items
    get groupedCartItems() {
        // Group cart items with reduce function
        const groupBy = items => items.reduce((r, a) => {
            const { cartDeliveryGroup } = a.cartItem;
            (r[cartDeliveryGroup.Id] = {
                cartDeliveryGroupName: cartDeliveryGroup.Name,
                elements: (r[cartDeliveryGroup.Id] || {}).elements || []}).elements.push(a);
            return r;
        }, {});

        // Grouped cart items
        const groupedCartItems = groupBy(this._items)

        // Separate grouped cart items object into array
        const groupedCartItemsEntries = Object.entries(groupedCartItems);

        // Set The active section by default in accordion
        this.activeAccordionSections = Object.keys(groupedCartItems || {});

        return groupedCartItemsEntries
        .map(e => ({ // Map the entries into a structure for easier handling
            cartDeliveryGroupId: e[0],
            cartDeliveryGroupName: e[1].cartDeliveryGroupName,
            elements: e[1].elements,
        }));
    }

    handleClick(){
        this.activeAccordionSections = this._items.map(({cartItem}) => cartItem.cartDeliveryGroup.Id);
    }
    
    handleClickClose(){
        this.activeAccordionSections = [];
    }

    handleToggleSection(event) {
        this.activeAccordionSections = event.detail.openSections;
    }


    /**
     * Fires an event to update the cart item backorder
     * @private
     * @param {ChangeEvent} event A click event.
     * @fires Items#backorderchanged
     */
    handleBackorderCheckbox(event) {
        const backorder = event.target.checked;
        const cartItemId = event.target.dataset.itemId;
        // Fire a new event with extra data.
        this.dispatchEvent(
            new CustomEvent(BACKORDER_CHANGED_EVT, {
                detail: {
                    cartItemId,
                    backorder
                }
            })
        );
    }

    render() {
        return this.groupByBranch ? groupedCartitemsTemplate : cartitemsTemplate;
    }
}