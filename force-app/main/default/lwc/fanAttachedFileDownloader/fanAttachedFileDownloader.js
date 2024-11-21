import { LightningElement, api, wire } from 'lwc';
import communityPath from '@salesforce/community/basePath'

import { attachedFileDownloaderLabels } from 'c/fanLabels'

import getRelatedFiles from '@salesforce/apex/fan_AttachedFileCtrl.getRelatedFiles';

export default class FandAttachedFileDownloader extends LightningElement {

    @api 
    recordId;

    url;

    @wire(getRelatedFiles, { recordId: "$recordId" })
    getRelatedFiles({ data, error }) {
        if (data && data.length > 0) {
            const storeName = communityPath.replace('/s', '');

            let url = `${storeName}/sfc/servlet.shepherd/version/download`;

            data.forEach((item) => {
                url += "/" + item;
            });
            this.url = url;
        } else if (error) {
            console.log('Error in getRelatedFiles --> ', error);
        }
    }

    get label() {
        return attachedFileDownloaderLabels();
    }
}