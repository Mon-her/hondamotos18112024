import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { MessageContext, publish } from 'lightning/messageService';

import communityId from '@salesforce/community/Id';
import getProductCategoryPath from '@salesforce/apex/fan_B2BSearchCtrl.getProductCategoryPath';
import getSortRules from '@salesforce/apex/fan_B2BSearchCtrl.getSortRules';
import productSearch from '@salesforce/apex/fan_B2BSearchCtrl.productSearch';
import getProductPrices from '@salesforce/apex/fan_B2BStorePricingCtrl.getProductPrices';
import addToCart from '@salesforce/apex/fan_B2BCartCtrl.addToCart';
import getShippingAddressList from '@salesforce/apex/fan_B2BAccountCtrl.getShippingAddressList';
import { normalizedCardContentMapping, setPrices, transformData } from './dataNormalizer';

import CART_CHANGED from '@salesforce/messageChannel/lightning__commerce_cartChanged';

import { searchResultsLabels } from 'c/fanLabels'

const HOME_PATH = { id: 'home', name: 'Inicio', isNavigable: true};

/**
 * A search resutls component that shows results of a product search or
 * category browsing.This component handles data retrieval and management, as
 * well as projection for internal display components.
 * When deployed, it is available in the Builder under Custom Components as
 * 'B2B Custom Search Results'
 */
export default class fanSearchResults extends NavigationMixin(LightningElement) {
    /**
     * Gets the effective account - if any - of the user viewing the product.
     *
     * @type {string}
     */
    @api
    effectiveAccountId;

    /**
     *  Gets or sets the unique identifier of a category.
     *
     * @type {string}
     */
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this._landingRecordId = value;
    }

    /**
     *  Gets or sets the search term.
     *
     * @type {string}
     */
    @api
    get term() {
        return this._term;
    }
    set term(value) {
        this._term = value;
        if (value) {
            this.triggerProductSearch();
        }
    }

    /**
     *  Gets or sets fields to show on a card.
     *
     * @type {string}
     */
    @api
    cardContentMapping;

    /**
     *  Gets or sets the layout of this component. Possible values are: grid, list.
     *
     * @type {string}
     */
    @api
    resultsLayout;

    /**
     *  Gets or sets whether the product image to be shown on the cards.
     *
     * @type {string}
     */
    @api
    showProductImage;

    /**
     * Gets the normalized component configuration that can be passed down to
     *  the inner components.
     *
     * @type {object}
     * @readonly
     * @private
     */
    get config() {
        return {
            layoutConfig: {
                resultsLayout: this.resultsLayout,
                cardConfig: {
                    showImage: this.showProductImage,
                    resultsLayout: this.resultsLayout
                }
            }
        };
    }

    /**
     * Gets or sets the normalized, displayable results for use by the display components.
     *
     * @private
     */
    get displayData() {
        return this._displayData ?? {};
    }
    set displayData(data) {
        this._displayData = transformData(data);
    }

    /**
     * Gets whether product search is executing and waiting for result.
     *
     * @type {Boolean}
     * @readonly
     * @private
     */
    get isLoading() {
        return this._isLoading;
    }

    /**
     * Gets whether results has more than 1 page.
     *
     * @type {Boolean}
     * @readonly
     * @private
     */
    get hasMorePages() {
        return this.displayData.total > this.displayData.pageSize;
    }

    /**
     * Gets the current page number.
     *
     * @type {Number}
     * @readonly
     * @private
     */
    get pageNumber() {
        return this._pageNumber;
    }

    /**
     * Gets the header text which shows the search results details.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get headerText() {
        let text = '';
        const totalItemCount = this.displayData.total;
        const pageSize = this.displayData.pageSize;

        if (totalItemCount > 1) {
            const startIndex = (this._pageNumber - 1) * pageSize + 1;

            const endIndex = Math.min(
                startIndex + pageSize - 1,
                totalItemCount
            );
            text = `${startIndex} - ${endIndex} de ${totalItemCount} productos`;
        } else if (totalItemCount === 1) {
            text = `1 resultado`;
        }
        return text;
    }

    /**
     * Gets the normalized effective account of the user.
     *
     * @type {string}
     * @readonly
     * @private
     */
    get resolvedEffectiveAccountId() {
        const effectiveAcocuntId = this.effectiveAccountId || '';
        let resolved = null;

        if (
            effectiveAcocuntId.length &&
            effectiveAcocuntId !== '000000000000000'
        ) {
            resolved = effectiveAcocuntId;
        }
        return resolved;
    }

    get productSearchInputJson() {
        const productSearchInput = {
            searchTerm: this.term,
            categoryId: this.recordId,
            refinements: this._refinements,
            fields: normalizedCardContentMapping(this.cardContentMapping),
            page: this._pageNumber - 1,
            sortRuleId: this.selectedSortRuleId
        };
        return JSON.stringify(productSearchInput);
    }

    get label() {
        return searchResultsLabels();
    }

    @wire(MessageContext)
    messageContext;

    @wire(getSortRules, { communityId })
    getSortRules({data, error}) {
        if(data) {
            this.sortRules = data.map(({ sortRuleId, label }) => ({ label, value: sortRuleId }));
            this.selectedSortRuleId = data[0].sortRuleId;
        } else if(error) {
            console.log('Error in getSortRules -> ', error);
        }
    }

    /**
     * Gets the branch options available for the user.
     */
    @wire(getShippingAddressList, { accountId: '$resolvedEffectiveAccountId' })
    getBranchOptions({data, error}){
        if(data) {
            this.branches = data.map(({ Name: label, fan_Code__c: value }) => ({ label, value }));

            const addressCode = sessionStorage.getItem('addressCode');
            if(addressCode && !this.branches.some(({ value }) => value === addressCode)) {
                sessionStorage.removeItem('addressCode');
            } else {
                this.selectedBranch = addressCode;
            }
        } else if(error){
            console.log('Error in getShippingAddressList --> ', error);
        }
    }

    @wire(getProductCategoryPath, { communityId, productCategoryId: "$_landingRecordId" })
    getProductCategoryPath({ data, error }) {
        if(data) {
            this.categoryPath = [HOME_PATH, ...data].map((productCategoryData, index) => ({
                ...productCategoryData,
                isNavigable: index !== data.length
            }));
        } else if(error) {
            console.log('Error in getProductCategoryPath -> ', error);
        }
    }

    /**
     * The connectedCallback() lifecycle hook fires when a component is inserted into the DOM.
     */
    connectedCallback() {
        this.triggerProductSearch();
    }

    triggerProductSearch() {
        this._isLoading = true;
        productSearch({
            communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            productSearchInputJson: this.productSearchInputJson
        }).then((result) => {
            this.displayData = result;

            const productIds = Object.values(result.productsPage.products)
            .flat()
            .map(({ id }) => id);
            this.getProductPrices(productIds);
        }).catch((error) => {
            console.log('Error in productSearch --> ', error);
        }).finally(() => {
            this._isLoading = false;
        });
    }

    async getProductPrices(productIds) {
        try {
            const pricingResult = await getProductPrices({
                communityId,
                effectiveAccountId: this.resolvedEffectiveAccountId,
                productIds
            });
            const { currencyIsoCode = '', pricingLineItemResults = [] } = pricingResult ?? {};

            const productPrices = pricingLineItemResults.reduce((accumulator, { productId, listPrice }) => {
                accumulator[productId] = listPrice;
                return accumulator;
            }, {});
            this._displayData = { ...this.displayData,
                layoutData: this.displayData.layoutData.map(setPrices(productPrices, currencyIsoCode))
            };
        } catch (error) {
            console.log('Error in getProductPrices --> ', error);
        }
    }


    /**
     * Handles a user request to add the product to their active cart.
     *
     * @private
     */
    handleAction(event) {
        event.stopPropagation();
        this.isAddToCartDisabled = true;

        const { productId,  productName, quantity } = event.detail;

        const cartItem = {
            Product2Id: productId,
            Quantity: quantity
        };

        addToCart({
            communityId: communityId,
            effectiveAccountId: this.resolvedEffectiveAccountId,
            contactPointAddressCode: this.selectedBranch,
            cartItem
        }).then(() => {
            publish(this.messageContext, CART_CHANGED);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.cartHasBeenUpdated,
                    variant: 'success',
                    mode: 'dismissable'
                })
            );
        }).catch((error) => {
            console.log('Error in addToCart --> ', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.error,
                    message: this.label.addToCartErrorPDP,
                    messageData: [productName],
                    variant: 'error',
                    mode: 'dismissable'
                })
            );
        }).finally(() => {
            this.isAddToCartDisabled = false;
        });
    }

    /**
     * Handles a user request to clear all the filters.
     *
     * @private
     */
    handleClearAll() {
        this._refinements = [];
        this._recordId = this._landingRecordId;
        this._pageNumber = 1;
        this.template.querySelector('c-fan-search-filter').clearAll();
        this.triggerProductSearch();
    }

    /**
     * Handles a user request to navigate to the product detail page.
     *
     * @private
     */
    handleShowDetail(event) {
        event.stopPropagation();

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.productId,
                actionName: 'view'
            },
            state: {
                branch: this.selectedBranch ?? this.branches?.[0]?.value
            }
        });
    }

    /**
     * Handles a user request to navigate to previous page results page.
     *
     * @private
     */
    handlePreviousPage(event) {
        event.stopPropagation();

        this._pageNumber = this._pageNumber - 1;
        this.triggerProductSearch();
    }

    /**
     * Handles a user request to navigate to previous or next page results page.
     *
     * @private
     */
    handleNextPage(event) {
        event.stopPropagation();

        this._pageNumber = this._pageNumber + 1;
        this.triggerProductSearch();
    }

    /**
     * Handles a user request to filter the results from facet section.
     *
     * @private
     */
    handleFacetValueUpdate(evt) {
        evt.stopPropagation();

        this._refinements = evt.detail.refinements;
        this._pageNumber = 1;
        this.triggerProductSearch();
    }

    /**
     * Handles a user request to show a selected category from facet section.
     *
     * @private
     */
    handleCategoryUpdate(event) {
        event.stopPropagation();

        this._recordId = event.detail.categoryId;
        this._pageNumber = 1;
        this.triggerProductSearch();
    }

    handleBranchChange({ detail }) {
        const { value } = detail;
        this.selectedBranch = value;
        sessionStorage.setItem('addressCode', value);
    }

    handleBreadcrumbClick({ currentTarget }) {

        const { id } = currentTarget.dataset;

        if(id === HOME_PATH.id) {
            this[NavigationMixin.Navigate]({ 
                name: 'Home',
                type: 'standard__namedPage',
                attributes: { pageName: 'home' }
            });
        } else {
            this[NavigationMixin.Navigate]({ 
                type: 'standard__recordPage',
                attributes: { recordId: id, actionName: 'view' }
            });
        }
    }

    handleSortRuleChange({ detail }) {
        this.selectedSortRuleId = detail.value;
        this.triggerProductSearch();
    }

    selectedBranch;
    selectedSortRuleId;
    sortRules;
    categoryPath = [HOME_PATH];
    isAddToCartDisabled;
    _displayData;
    _isLoading = false;
    _pageNumber = 1;
    _refinements = [];
    _term;
    _recordId;
    _landingRecordId; 
}