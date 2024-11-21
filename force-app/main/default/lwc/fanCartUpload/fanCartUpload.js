/*
 * Copyright (c) 2021, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import processData from '@salesforce/apex/fan_CartUploadController.processData';
import getInfo from '@salesforce/apex/fan_CartUploadController.getInfo';

import getManagedContentByContentKeys from '@salesforce/apex/fan_B2BManagedContentCtrl.getManagedContentByContentKeys';

import LOCALE from '@salesforce/i18n/locale';
import USERID from '@salesforce/user/Id';
import COMMUNITYID from '@salesforce/community/Id';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import cssResources from '@salesforce/resourceUrl/b2bCartUpload';

import { readFile } from './readFile';
import SHEETJS_ZIP from '@salesforce/resourceUrl/fan_sheetjs'

// Labels
import { cartUploadLabels } from 'c/fanLabels';

export default class FanCartUpload extends LightningElement {

    @api componentTitle;

    @api effectiveAccountId;

    inputSelection = 'file';

    textAreaValue;

    isShowHelp = false;

    /**
     * Container of the supplied value in the Experience Builder.
     * @type {boolean}
     */
    _isOrderTemplateDownloadButtonVisible;

    /**
     * The order template managed content data.
     * @type {Object}
     */
    orderTemplateManagedContent;

    // For the help dialog
    @api contentId;
    @api contentType;

    @api isAsynchronous = false;

    // Indicates if the backorder is the field to save or the CartDeliveryGroup
    @api defaultBackorder;

    /**
     * Label for the order template download button.
     */
    @api
    orderTemplateDownloadButtonLabel;

    /**
     * Flag to control when to display the order template download button. 
     * @type {boolean}
     */
    @api
    set isOrderTemplateDownloadButtonVisible(value) {
       this._isOrderTemplateDownloadButtonVisible = value;
    }

    get isOrderTemplateDownloadButtonVisible() {
        return this._isOrderTemplateDownloadButtonVisible && this.orderTemplateManagedContent;
    }

    /**
     * The key of the managed content to look for.
     * @type {string}
     */
    @api orderTemplateKey;

    showProcessLog = false;
    processLog;

    get label (){
        return cartUploadLabels();
    };

    communityId = COMMUNITYID;

    locale = LOCALE;
    userId = USERID;

    cartId;
    webstoreId;
    maxUploadRows;

    @wire(getManagedContentByContentKeys, { 
        communityId: COMMUNITYID,
        contentKeys: '$orderTemplateKey',
        pageParam: 0, // Page number.
        pageSize: 1, // Page size.
        showAbsoluteUrl: true })
    fetchManagedContents(result) {

        const { data, error } = result;

        if(data) {
            this.orderTemplateManagedContent = (data.items ?? [])?.[0].contentNodes;
        } else if(error) {
            console.log('Error in --> fetchManagedContents', error);
        }
    }

    connectedCallback() {
        console.log('communityId: ' + this.communityId);

        this.loadInfo();
    }

    get options() {
        return [
            { label: this.label.fileOption, value: 'file' },
            { label: this.label.textArea, value: 'text' },
        ];
    }

    handleShowHelpDialog(event) {
        this.isShowHelp = true;
    }

    handleCloseHelpDialog(event) {
        this.isShowHelp = false;
    }

    handleInputSelectionChange(event) {
        const selectedOption = event.detail.value;

        this.inputSelection = selectedOption;
    }

    handleTextAreaChange(event) {
        this.textAreaValue = event.detail.value;
    }

    handleTextReset(event) {
        this.textAreaValue = undefined;
    }

    get isFileOptionSelected() {
        return this.inputSelection === 'file';
    }

    constructor() {
        super();

        loadStyle(this, cssResources);

        loadScript(this, SHEETJS_ZIP + '/xlsx.full.min.js')
        .then(() => {
            if(!window.XLSX) {
                throw new Error(this.label.errorLoadingSheetJS);                
            }
        })
        .catch(error => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.libraryLoad,
                    message: error.message,
                    variant: 'error'
                })
            );
        });
    }

    loadInfo() {

        console.log('inside loadInfo()');

        getInfo({ userId: this.userId, effectiveAccountId: this.resolvedEffectiveAccountId, communityId: this.communityId, webstoreId: null })
            .then((result) => {
                if (result) {
                    console.log("getInfo():result");
                    console.log(JSON.stringify(result));

                    this.cartId = result.cartId;
                    this.webstoreId = result.webstoreId;
                    this.maxUploadRows = result.maxUploadRows;

                }
            })
            .catch((error) => {
                console.log("error from getInfo()");
                console.log(error);
                this.showLoadingSpinner = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.searchError,
                        message: error.message,
                        variant: "error"
                    })
                );
            });

    }

    showLoadingSpinner = false;
    isFileSelected = false;
    rows;

    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    content;
    MAX_FILE_SIZE = 1500000;

    get acceptedFormats() {
        return ['.csv', '.xlsx'];
    }

    get noFileSelected() {
        if (this.filesUploaded.length == 0) {
            return true;
        }
        else {
            return false;
        }
    }

    get hasContent() {
        // console.log('contentId: ' + this.contentId);
        // console.log('contentType: ' + this.contentType);

        if (this.contentId && this.contentType) {

            // console.log('hasContent = true');
            return true;
        }
        else {
            // console.log('hasContent = false');
            return false;
        }
    }

    handleReset() {
        this.filesUploaded = [];
        this.file = undefined;
        this.fileContents = undefined;
        this.content = undefined;
        this.rows = undefined;
        this.isFileSelected = false;
    }

    // getting file 
    handleFilesChange(event) {

        try {
            if (event.target.files.length > 0) {

                this.filesUploaded = event.target.files;
                this.isFileSelected = true;

                // let contentType = event.target.files[0].type;
                // console.log('contentType: ' + contentType);
                // let size = event.target.files[0].size;
                // console.log('size: ' + size);
            }
        }
        catch (error) {
            console.log(error.message);
        }
    }

    handleSave() {
        console.log('inside handleSave()');
        if (this.filesUploaded.length > 0) {
            this.uploadHelper();
        }
        else {

        }
    }

    handleTextSave() {

        console.log('inside handleTextSave');

        if ((this.textAreaValue || '').trim().length) {
            this.rows = this.textAreaValue.split(/\r?\n/g);
            this.processUserInput();
        } else
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.processingError,
                    message: this.label.noTextFound,
                    variant: 'error',
                }),
            );
    }

    uploadHelper() {
        console.log('inside uploadHelper()');
        this.file = this.filesUploaded[0];
        if (this.file.size > this.MAX_FILE_SIZE) {
            window.console.log(this.label.fileTooLong);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.processingError,
                    message: this.label.fileTooLong,
                    variant: "error"
                })
            );
            return;
        }

        this.showLoadingSpinner = true;

        Promise.resolve(readFile(this.file))
        .then(result => {

            // Fill fileContents and handle showLoadingSpinner property
            this.parseContentFile(result);

            // removes whitespace
            this.fileContents = this.fileContents.trim();

            if (this.showLoadingSpinner && this.fileContents.length) {
                this.rows = this.fileContents.split(/\r?\n/g);
                this.processUserInput();
            } else if(!this.fileContents.length) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.processingError,
                        message: this.label.fileIsEmpty,
                        variant: 'error',
                    }),
                );
                this.showLoadingSpinner = false;
            }
        });
    }

    // Calling apex class to insert the file
    processUserInput() {
        console.log('inside processUserInput()');

        const hasHeaderRow = false;
        const ignoreInvalidSkus = true;
        const emailResults = true;

        this.processLog = undefined;
        this.showProcessLog = false;

        this.showLoadingSpinner = true;

        console.log('hasHeaderRow: ' + hasHeaderRow);
        console.log('ignoreInvalidSkus: ' + ignoreInvalidSkus);
        console.log('emailResults: ' + emailResults);

        processData({
            userId: this.userId
            , rows: this.rows
            , webstoreId: this.webstoreId
            , effectiveAccountId: this.resolvedEffectiveAccountId
            , cartId: this.cartId
            , hasHeaderRow: hasHeaderRow
            , ignoreInvalidSkus: ignoreInvalidSkus
            , emailResults: emailResults
            , defaultBackorder: this.defaultBackorder
        })
            .then(result => {
                console.log('return from processData()');

                this.showLoadingSpinner = false;
                this.isFileSelected = true;

                console.log('result: ' + JSON.stringify(result));

                if (result.messagesJson) {
                    let messages = JSON.parse(result.messagesJson);

                    this.showProcessLog = false;
                    let processLog = '';

                    processLog += '<ul>';

                    // Process messages returned
                    // Display toasts when applicable
                    // Create content for the details section
                    for (var i = 0; i < messages.length; i++) {

                        var message = messages[i];

                        if (message.toast === true) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: message.title,
                                    message: message.message,
                                    variant: message.severity,
                                }),
                            );

                        }

                        let formattedMessage = '';

                        // These classes are defined in cartUploadProcessLog.css
                        let msgClass = '';
                        // if(message.severity === 'info') {
                        //     msgClass = 'msgInfo';
                        // }
                        // if(message.severity === 'success') {
                        //     msgClass = 'msgSuccess';
                        // }
                        // if(message.severity === 'warn') {
                        //     msgClass = 'msgWarn';
                        // }
                        // if(message.severity === 'error') {
                        //     msgClass = 'msgErr';
                        // }

                        if (message.severity === 'info') {
                            msgClass = 'slds-text-color_error';
                        }
                        if (message.severity === 'success') {
                            msgClass = 'slds-text-color_success';
                        }
                        if (message.severity === 'warn') {
                            msgClass = 'slds-text-color_default';
                        }
                        if (message.severity === 'error') {
                            msgClass = 'slds-text-color_error';
                        }

                        formattedMessage = '<li class=\'' + msgClass + '\'>' + message.message + '</li>';

                        processLog += formattedMessage;

                    }

                    processLog += '</ul>';

                    console.log('processLog: ' + processLog);

                    this.processLog = processLog;
                    this.showProcessLog = true;

                    // Refresh the cart icon
                    try {
                        this.dispatchEvent(new CustomEvent("cartchanged", {
                            bubbles: true,
                            composed: true
                        }));
                    }
                    catch (err) {
                        console.log('error: ' + err);
                    }

                }

            })
            .catch(error => {

                console.log('error from processData()');

                window.console.log(error);

                this.showLoadingSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.processingError,
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });

    }

    get resolvedEffectiveAccountId() {

        const effectiveAcocuntId = this.effectiveAccountId || "";
        let resolved = null;

        if (effectiveAcocuntId.length > 0 && effectiveAcocuntId !== "000000000000000") {
            resolved = effectiveAcocuntId;
        }
        return resolved;
    }

    // Result: content and extension from file
    parseContentFile(result) {
        if(result.extension === 'csv')
            this.fileContents = result.content;
        else if(result.extension === 'xlsx') {

		    const workbook = window.XLSX.read(result.content, { type: 'binary' });

            if(!workbook || !workbook.Workbook) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: this.label.processingError,
                        message: this.label.incorrectFileFormat,
                        variant: 'error',
                    }),
                );
                this.showLoadingSpinner = false;
                throw new Error(this.label.incorrectFileFormat);
            }

            const sheetName = workbook.SheetNames[0];
            const ws = workbook.Sheets[sheetName];
            this.fileContents = window.XLSX.utils.sheet_to_csv(ws);
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: this.label.processingError,
                    message: this.label.fileTypeNotSupported,
                    variant: 'error',
                }),
            );
            this.showLoadingSpinner = false;
        }
    }

}