import { api, wire, LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { MessageContext, publish, subscribe, unsubscribe} from 'lightning/messageService';
import { getPathPrefix } from 'lightning/configProvider';

import communityId from '@salesforce/community/Id';

import getCartItems from '@salesforce/apex/fan_B2BCartCtrl.getCartItems';
import deleteCartItem from '@salesforce/apex/fan_B2BCartCtrl.deleteCartItem';
import deleteCart from '@salesforce/apex/fan_B2BCartCtrl.deleteCart';
import createCart from '@salesforce/apex/fan_B2BCartCtrl.createCart';
import updateCartItemsBackorder from '@salesforce/apex/fan_B2BCartCtrl.updateCartItemsBackorder';
import updateCartItemQuantity from '@salesforce/apex/fan_B2BCartCtrl.updateCartItemQuantity';
import updateCartItemPrices from '@salesforce/apex/fan_B2BCartCtrl.updateCartItemPrices';
import deleteCartCheckoutSession from '@salesforce/apex/fan_B2BCartCtrl.deleteCartCheckoutSession';
import addAllToWishlist from  '@salesforce/apex/fan_B2BWishlistCtrl.addAllToWishlist'
import getWishlistSummaries from '@salesforce/apex/fan_B2BWishlistCtrl.getWishlistSummaries'
import createAndAllAddToWishlist from '@salesforce/apex/fan_B2BWishlistCtrl.createAndAllAddToWishlist';

import { cartContentLabels } from 'c/fanLabels';
import { hasAvailability, getAvailability } from 'c/fanInventoryHandler';

import INPUT_CHANNEL from '@salesforce/messageChannel/toFanCartContents__c';
import TO_FAN_ORDER_TYPE from '@salesforce/messageChannel/toFanOrderType__c';
import CART_CHANGED from '@salesforce/messageChannel/lightning__commerce_cartChanged';

/** CHANNELS:
 * @publishes lightning__commerce_cartChanged
 * @publishes toFanOrderType__c
 * @subscribes toFanCartContents__c
 */

const TYPE_GARANTIA = "RMT_Garantia";

export default class FanCartContents extends NavigationMixin(LightningElement) {
    @wire(MessageContext)
    messageContext;

    /** The recordId provided by the cart detail flexipage. */
    @api
    recordId;

    /** The effectiveAccountId provided by the cart detail flexipage. */
    @api
    effectiveAccountId;

    /** Gets or sets the wishlist. */
    wishlists;

    /** Flag that defines whether to show allAllToWishlist modal */
    addAllToWishlistModal = false;

    /** Flag that defines whether allSaveToWishlist button is disabled */
    disableSaveAllToWishlist = false;

    /** Total number of items in the cart */
    _cartItemCount = 0;

    /** A list of cartItems. */
    @track
    cartItems;

    /** A list of sortoptions useful for displaying sort menu */
    sortOptions = [
        { value: 'CreatedDateDesc', label: this.labels.createdDateDesc },
        { value: 'CreatedDateAsc', label: this.labels.createdDateAsc },
        { value: 'NameAsc', label: this.labels.nameAsc },
        { value: 'NameDesc', label: this.labels.nameDesc }
    ];

    /** Specifies the page token to be used to view a page of cart information. If the pageParam is null, the first page is returned. */
    pageParam = null;

    /** Specifies the page size to be used to view a page of cart information. If the pageSize is null, the default size is 25; */
    pageSize = 200;

    /** Sort order for items in a cart. The default sortOrder is 'CreatedDateDesc'
     *    - CreatedDateAsc—Sorts by oldest creation date
     *    - CreatedDateDesc—Sorts by most recent creation date.
     *    - NameAsc—Sorts by name in ascending alphabetical order (A–Z).
     *    - NameDesc—Sorts by name in descending alphabetical order (Z–A). */
    sortParam = 'CreatedDateDesc';

    /** The ISO 4217 currency code for the cart page*/
    currencyCode;

    /** The product title option to display in product detail */
    @api
    productTitleOption;

    /** Flag that defines when to show the dealer price.  */
    @api
    isDealerPriceVisible;

    /** Control the visibility to display color property */
    @api
    showColor = false;
    /** Control the visibility to display sort options element */
    @api
    showSortOption;

    /** Flag that defines whether to group by branch */
    @api
    groupByBranch = false;

    /** Flag that defines when to show 'Loading more cart items' spinner */
    loadingMoreCartItems = false;

    /** Flag that defines if the cart admit backorder */
    _disableBackorder;
    /** Stores cart items stock */
    _itemsStock;
    /** Stores the order type */
    _orderType;
    _paymentCondition;
    /** Wait for products to update its payment condition */
    loading = false;
    /** Gets whether the cart item list is empty. */
    get isCartEmpty() {
        // If the items are an empty array (not undefined or null), we know we're empty.
        return Array.isArray(this.cartItems) && this.cartItems.length === 0;
    }

    /** The labels used in the template.
     * To support localization, these should be stored as custom labels. */
    get labels() {
        return cartContentLabels();
    }

    /** Gets the cart header along with the current number of cart items */
    get cartHeader() {
        return `${this.labels.cartHeader} (${this._cartItemCount})`;
    }

    /** Gets whether the item list state is indeterminate (e.g. in the process of being determined). */
    get isCartItemListIndeterminate() {
        return !Array.isArray(this.cartItems) || this.loading;
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

    /** Flag that defines whether selectAllWithBackorder button is disabled. */
    get disabledSelectAllWithBackorder() {
        return this.isCartEmpty || !(this.cartItems || []).some(ci => !ci.cartItem.backorder) || this._disableBackorder;
    }

    /** Flag that defines whether unselectAllWithBackorder button is disabled. */
    get disabledUnselectAllWithBackorder() {
        return this.isCartEmpty || !(this.cartItems || []).some(ci => ci.cartItem.backorder) || this._disableBackorder;
    }

    /** Flag that defines whether wishlist is empty. */
    get isEmptyWishlists() {
        return !(this.wishlists || []).length;
    }

    get _hasStock(){
        let hasStock = true;
        if((this._paymentCondition === 'contado' || this._paymentCondition == 'anticipo') && this._itemsStock) {
            const storeName = getPathPrefix().replace('/', '');
            hasStock = hasAvailability(storeName, this.cartItems, this._itemsStock);
        }
        return hasStock;
    }

    get isAnticipo(){
        return (this._paymentCondition == 'anticipo' && !this.disabledSelectAllWithBackorder && this._hasStock == false);
    }

    get itHasStock(){
        return this._paymentCondition == 'anticipo' || this._hasStock;
    }

    /** This lifecycle hook fires when this component is inserted into the DOM. */
    connectedCallback() {
        // Initialize 'cartItems' list as soon as the component is inserted in the DOM.
        this.updateCartItems();
        this.subscribeToInputChannel();
        this.updateCheckoutSession();
        this.fetchWishlistSummaries();
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
            //Activate fanOrderType
            publish(this.messageContext, TO_FAN_ORDER_TYPE, {origin: 'fanCartContent', type: 'cartLoadCompleted'});
        }).catch(error => {
            console.log('Error in getWishlistSummaries -->' + error);
        })
    }

    /** Get a list of cart items from the server via imperative apex call */
    updateCartItems() {
        // Call the 'getCartItems' apex method imperatively
        getCartItems({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            activeCartOrId: this.recordId,
            pageParam: this.pageParam,
            pageSize: this.pageSize,
            sortParam: this.sortParam
        }).then((result) => {
            console.log('result pageParam --> ',result.nextPageToken);
            console.log('getCartItems result --> ',result.cartItems);
            this.cartItems = result.cartItems;
            this.currencyCode = result.cartSummary.currencyIsoCode;
            this.pageParam = result.nextPageToken;
            // Load all cart items if there exists more than 200 in cart. If not, get item promotions and check inventory
			if (this.pageParam != null) {
                this.showMoreCartItems();
            } else {
                this._cartItemCount = this.cartItems.reduce((p, a) => p + Number(a.cartItem.quantity), 0);
               // Get promotion prices for cart items
                if (this._cartItemCount > 0) {
                    this.cartItems.map(item => item.cartItem.disableBackorder = this._disableBackorder);
                    this.validateOrderTypeChanges(result.orderTypeValidation);
                    this.getAvailability();
                } else this._loadingCartItems = false;	
           }
        }).catch((error) => {
            this.cartItems = undefined;
            console.log('Error in getCartItems --> ', error);
        });
    }
    /** Handles a "click" event on the sort menu. */
    handleChangeSortSelection(event) {
        this.sortParam = event.target.value;
        // After the sort order has changed, we get a refreshed list
        this.updateCartItems();
    }

    /** Helper method to handle updates to cart contents by publishing.
     * @publishes commerce__lightning_cartChanged */
    notifyCartChanges() {
        // Update Cart Badge and Cart Totals.
        publish(this.messageContext, CART_CHANGED, { origin: 'fanCartContents', hasStock: (this._hasStock || this.disabledSelectAllWithBackorder)});
    }

    /** Handler for the 'quantitychanged' event fired from cartItems component. */
    handleQuantityChanged({ detail }) {
        const { cartItemId, quantity } = detail;
        updateCartItemQuantity({
            cartId: this.recordId,
            cartItemId,
            quantity
        }).then((updatedCartItem) => {
            this.refreshCartItems(updatedCartItem);
            // Update the Cart Header with the new count
            this._cartItemCount = this.cartItems.reduce((totalQuantity, { cartItem }) => totalQuantity + Number(cartItem.quantity), 0);
        }).catch((error) => console.log('Error in handleQuantityChanged --> ', error));
    }

    /** Handler for the 'singlecartitemdelete' event fired from cartItems component. */
    handleCartItemDelete({ detail }) {
        const { cartItemId } = detail;
        deleteCartItem({
            communityId,
            effectiveAccountId: this.effectiveAccountId,
            cartId: this.recordId,
            cartItemId
        }).then((updatedCartItems) => {
            this.removeCartItem(cartItemId, updatedCartItems);
        }).catch((e) => {
            // Handle cart item delete error properly
            // For this sample, we can just log the error
            console.log('Error with deleteCartItem: ', e);
        });
    }

    /** Handler for the 'click' event fired from 'Clear Cart' button
     * We want to delete the current cart, create a new one, and navigate to the newly created cart.  */
    handleClearCartButtonClicked() {
        // Step 1: Delete the current cart
        deleteCart({
            communityId,
            effectiveAccountId: this.effectiveAccountId,
            activeCartOrId: this.recordId
        }).then(() => {
            // Step 2: If the delete operation was successful,
            // set cartItems to undefined and update the cart header
            this.cartItems = undefined;
            this._cartItemCount = 0;
        }).then(() => {
            // Step 3: Create a new cart
            return createCart({
                communityId,
                effectiveAccountId: this.effectiveAccountId
            });
        }).then((result) => {
            // Step 4: If create cart was successful, navigate to the new cart
            this.navigateToCart(result.cartId);
            // Update the Cart Badge, Cart Totals and notify any other components interested in this change.
            this.notifyCartChanges();
        }).catch((e) => {
            // Handle quantity any errors properly
            // For this sample, we can just log the error
            console.log('Error with deleteCart: ', e);
        });
    }

    /** Given a cart id, navigate to the record page */
    navigateToCart(cartId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: cartId,
                objectApiName: 'WebCart',
                actionName: 'view'
            }
        });
    }

    /** Given a cartItem id, remove it from the current list of cart items. */
    removeCartItem(cartItemId, updatedCartItems) {
        const cartItems = this.cartItems.reduce((accumulator, cartItemResult) => {
            accumulator[cartItemResult.cartItem.cartItemId] = cartItemResult;
            return accumulator;
        }, {});
        const { cartItem: removedItem } = cartItems[cartItemId];
        delete cartItems[cartItemId];

        console.log('remove item --> ', removedItem);

        publish(this.messageContext, CART_CHANGED, { origin: 'fanCartContents', cartItemDeleted : Object.keys(cartItems).length});

        // Update Cart Badge and Cart Totals.
        // Update the cartItems with the changes.
        this.refreshCartItems(updatedCartItems, Object.values(cartItems));
        // Update the Cart Header with the new count
        this._cartItemCount -= Number(removedItem.quantity || 0);
    }

    /** Handler for the 'click' event fired from 'Select all with backorder' button
     * We want to select all cart items with backorder */
    handleSelectAllWithBackorder() {
        const cartItems = (this.cartItems || []).filter(e => !e.cartItem.backorder).map(e => {
            const tmpCartItem =  {...e}.cartItem;
            tmpCartItem.backorder = true;
            return (({ cartItemId, backorder }) => ({ Id: cartItemId, fan_IsBackorder__c: backorder }))(tmpCartItem);
        });

        updateCartItemsBackorder({
            cartItemsList: cartItems
        }).then(() => {
            this.cartItems.filter(e => !e.cartItem.backorder)
            .forEach(e => {
                e.cartItem.backorder = true; // Update cart items in the template
            });
            this.notifyCartChanges();
        }).catch((error) => console.log('Error with updateCartItemsBackorder --> ', error));
    }
     
    /** Handler for the 'click' event fired from 'Unselect all with backorder' button
     * We want to unselect all cart items with backorder */
     handleUnselectAllWithBackorder(){
        const cartItems = (this.cartItems || []).filter(e => e.cartItem.backorder).map(e => {
            const cartItemTmp = {...e}.cartItem;
            cartItemTmp.backorder = false;
            return (({cartItemId, backorder}) => ({Id: cartItemId, fan_IsBackorder__c: backorder}))(cartItemTmp);
        });

        updateCartItemsBackorder({
            cartItemsList: cartItems
        }).then(() => {
            this.cartItems.forEach( e => {
                e.cartItem.backorder = false;
                e.cartItem.disableBackorder = this._disableBackorder;
                this.notifyCartChanges();
            });
        }).catch((error) => console.log('Error with updateCartItemsBackorder: ', error));
     }

    /** Handler for the 'click' event fired from 'Select all with backorder' button
     * We want to select backorder */
    handleBackorderChanged(event) {
        const cartItem = (({ cartItemId, backorder }) => ({ Id: cartItemId, fan_IsBackorder__c: backorder }))(event.detail);

        updateCartItemsBackorder( {
            cartItemsList: [cartItem]
        }).then(() => {
            // Update cart item in the template
            this.cartItems.find(e => e.cartItem.cartItemId === cartItem.Id).cartItem.backorder = cartItem.fan_IsBackorder__c;
            this.notifyCartChanges();
        }).catch((error) => console.log('Error with updateCartItemsBackorder: ', error));
    }

    /** Handler for the 'click' event fired from 'Add all to wishlist' button
     * We want to show wishlist modal */
    showWishlistModal() {
        this.addAllToWishlistModal = true;
    }

    /** Handler for the 'click' event fired from 'Cancel' button
     * We want to hide wishlist modal */
    hideWishlistModal() {
        this.disableSaveAllToWishlist = false;
        this.addAllToWishlistModal = false;
    }

    /** Handler for the 'click' event fired from 'Create or add to wishlist' radio button
     * We want to control the options to add cart items to an wishlist */
    validateSelect(event) {
        const selectWishlist = this.template.querySelector('[data-id="select-wishlist"]');
        const createListInput = this.template.querySelector('[data-id="create-list-input"]');

        if(event.target.dataset.id === 'select-list-btn') {
            selectWishlist.disabled = !(createListInput.disabled = true);
            this.disableSaveAllToWishlist = !selectWishlist.value;
        } else {
            createListInput.disabled = !(selectWishlist.disabled = true);
            this.disableSaveAllToWishlist = !createListInput.value;
        }
    }

    /** Handler for the 'change' event fired from 'Select wishlist' combobox
     * we want to verify that a selected wishlist exists */
    handleWishlistOptionChange(event) {
        this.disableSaveAllToWishlist = !event.target.value;
    }

    /** Handler for the 'change' event fired from 'wishlist name' input
     * we want to verify that the name of a wishlist has been entered */
    handleWishlistNameChange(event) {
        this.disableSaveAllToWishlist = !event.target.value;
    }

    /** Handler for the 'click' event fired from 'Save all to wishlist' button
     * we want to save the cart items in a wishlist */
    saveAllToWishlist() {

        const wishlistId = (this.template.querySelector('[data-id="select-wishlist"]') || {}).value;
        const wishlistName = this.template.querySelector('[data-id="create-list-input"]').value;

        if(this.template.querySelector('[data-id="create-list-btn"]').checked)
            createAndAllAddToWishlist({
                communityId: communityId,
                wishlistInput: { name: wishlistName, products: this.cartItems.map(ci => ({ productId: ci.cartItem.productId })) }
            }).then(({ summary }) => {
                const { id, name } = summary;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: cartContentLabels().success,
                        message: cartContentLabels().addAllToWishlistSuccess,
                        messageData: [name],
                        variant: 'success',
                        mode: 'dismissable'
                    })
                );
                this.wishlists = [...this.wishlists, { label: name, value: id }];
            }).catch(error => {
                console.log('Error with createAndAllAddToWishlist: ', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: cartContentLabels().error,
                        message: error,
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });
        else {
            const products =  this.cartItems.reduce((r, a) => {
                r[a.cartItem.productId] = a.cartItem.productDetails.name;
                return r;
            }, {});

            addAllToWishlist({
                communityId: communityId,
                wishlistId,
                products
            })
            .then(() =>
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: cartContentLabels().success,
                        message: cartContentLabels().addAllToWishlistSuccess,
                        messageData: [this.wishlists.find(w => w.value === wishlistId).label],
                        variant: 'success',
                        mode: 'dismissable'
                    })
                )
            )
            .catch(error =>
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: cartContentLabels().error,
                        message: error.toString(),
                        variant: 'error',
                        mode: 'dismissable'
                    })
                )
            )
        }

        this.addAllToWishlistModal = false;
    }

    /** Load new cart items to the existing cart items list */
    showMoreCartItems() {
        // Call the 'getCartItems' apex method imperatively
        getCartItems({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            activeCartOrId: this.recordId,
            pageParam: this.pageParam,
            pageSize: this.pageSize,
            sortParam: this.sortParam
        }).then((result) => {
            this.cartItems = [...this.cartItems, ...result.cartItems];
            this.pageParam = result.nextPageToken;
            if (this.pageParam != null) {
                this.showMoreCartItems();
            } else {
                this.cartItems.map(item => item.cartItem.disableBackorder = this._disableBackorder);
                this._cartItemCount = this.cartItems.reduce((p, a) => p + Number(a.cartItem.quantity), 0);
                this.validateOrderTypeChanges(result.orderTypeValidation);
                this.getAvailability();      
            } 
        }).catch((error) => {
            this.cartItems = undefined;
            console.log('Error in showMoreCartItems --> ', error);
        }).finally(() => {
            this._loadingCartItems = false;
        });
    }

    updateCartItemPrices() {
        if(this.cartItems != undefined && this.cartItems.length > 0) {
            //Activate spinner until product prices are changed in updateCartItemPrices function
            this.loading = true;
            updateCartItemPrices({ cartId: this.recordId })
            .then((updatedCartItems) => {
                this.refreshCartItems(updatedCartItems);
                //Activate the checkout button and disabled the spinner 
                publish(this.messageContext, CART_CHANGED, {origin: 'fanCartContents', type: 'cartItemPricesUpdate', checkoutButtonDisabled: false}); 
                //Activate fanOrderType
                publish(this.messageContext, TO_FAN_ORDER_TYPE, {origin: 'fanCartContent', type: 'cartLoadCompleted'});
                this.loading = false; 
            })
            .catch((error) => console.log('Error in updateCartItemPrices -->', error));
        }
    }

    refreshCartItems(updatedCartItems, cartItems) {
        this.cartItems = (cartItems ?? this.cartItems).map((cartItemResult) => {
            const { cartItemId } = cartItemResult.cartItem;
            const { Id, Quantity, ListPrice, SalesPrice, UnitAdjustedPrice, TotalPrice } = updatedCartItems[cartItemId] ?? {};

            if(Id) {
                cartItemResult.cartItem = {
                    ...cartItemResult.cartItem,
                    quantity: Quantity.toString(),
                    listPrice: ListPrice.toString(),
                    salesPrice: SalesPrice.toString(),
                    unitAdjustedPrice: UnitAdjustedPrice.toString(),
                    totalPrice: TotalPrice.toString(),
                    disableBackorder: this._disableBackorder
                };
            }
            return cartItemResult;
        });
        // Update the Cart Badge, Cart Totals and notify any other components interested in this change.
        this.notifyCartChanges();
    }

    subscribeToInputChannel() {
        if(!this.subscription) {
            this.subscription = subscribe(this.messageContext, INPUT_CHANNEL, data => {
                /** 2 Logics for disable backorder checkbox
                * 1. When the payment method selected is "Contado", but backorder is NOT checked
                * 2. When the order type selected is "Garantia", backorder IS checked */
                this._orderType = data.orderType;
                this._paymentCondition = data.payment;
                this._disableBackorder = data.payment == 'contado' || this._orderType == TYPE_GARANTIA;
                if (data.payment == 'contado') this.handleUnselectAllWithBackorder();
                if (this._orderType == TYPE_GARANTIA) this.handleSelectAllWithBackorder();
                this.updateCartItemPrices();
            });
        }
    }

    unsubscribeToInputChannel() {
        unsubscribe(this.subscription);
         this.subscription = null;
    }

    disconnectedCallback() {
        this.unsubscribeToInputChannel();
    }

    // Delete CartCheckoutSession if session exist for avoid conflicts with shipping taxes in checkout and Start it again
    updateCheckoutSession(){
        deleteCartCheckoutSession({
            cartId: this.recordId
        });
    }

    /** Display an informational message when the selected order type is invalid,
     * and notify fanOrderType to refresh the order type value in the combobox. */
    validateOrderTypeChanges({ applied, isPaymentConditionChangeable, orderType, message, paymentCondition, title, show }) {
        if(!applied) return;
        this._orderType = orderType;

        // Request to refresh the orderType value in the combobox.
        publish(this.messageContext, TO_FAN_ORDER_TYPE, { isPaymentConditionChangeable });

        if(this._orderType == TYPE_GARANTIA) {
           this.handleSelectAllWithBackorder();
        }

        if(show) {
            this.dispatchEvent(new ShowToastEvent({
                title,
                variant: 'error',
                mode: 'dismissible',
                message
            }));
        }
    }

    /** Get inventory data for the current cart items */
    getAvailability() {
        const storeName = getPathPrefix().replace('/', '');
        getAvailability(storeName, communityId, this.cartItems)
        .then(availalibity => {
            this._itemsStock = availalibity;
            this.notifyCartChanges();
        }).catch(error => {
            console.log('Error in getAvailability --> ',error);
        });
    }
}