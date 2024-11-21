import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { resolve } from 'c/fanCmsResourceResolver';

import communityId from '@salesforce/community/Id';
import getImagesFromTopic from "@salesforce/apex/fan_HomeCarouselCtrl.getImagesFromTopic";

import { refreshApex } from "@salesforce/apex";

export default class FanHomeCarousel extends NavigationMixin(LightningElement) {

    @api topicName;
    @api autoScroll = false;
    @api
    get autoScrollTime() {
        return this._autoScrollTime;
    }

    set autoScrollTime(value) {
        const miliSeconds = 1000;
        this._autoScrollTime = Number(value) * miliSeconds;
    }

    // Local Fields.
    _autoScrollTime;
    images;
    currentImage;
    firstLoad = true;

    get isImageChangeable() {
        return this.images?.length > 1;
    }

    get pointerType() {
        return this.currentImage.recordId ? '' : 'default-cursor';
    }

    @wire(getImagesFromTopic, {
        communityId: communityId,
        topicName : "$topicName"
    })
    getImagesFromTopicWire(result){
        const { data, error } = result;
        if(data) {
            this.images = data.map((content) => ({
                ...content,
                url: resolve(content.url)
            })).reverse();

            this.currentImage = this.images[0];
            this.createInterval();
            this.refreshCache(result);
        } else if(error) {
            console.log('Error in getImagesFromTopic --> ', error);
        }
    }

    async refreshCache(imagesFromTopicResult) {
        if(this.firstLoad) {
            await refreshApex(imagesFromTopicResult);
            this.firstLoad = false;
        }
    }

    goToPrevious() {
        this.resetInterval();
        const index = this.images.indexOf(this.currentImage);
        this.currentImage = this.images.at(index - 1);
    }

    goToNext() {
        this.resetInterval();
        const index = this.images.indexOf(this.currentImage);
        this.currentImage = this.images[(index + 1) % this.images.length];
    }

    handleNavigation() {
        if(this.currentImage.recordId) {
            clearInterval(this.intervalId);

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.currentImage.recordId
                }
            });
        }
    }

    createInterval() {
        if(this.autoScroll && this.isImageChangeable) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.intervalId = setInterval(() => {
                this.goToNext();
            }, this.autoScrollTime);
        }
    }

    resetInterval() {
        clearInterval(this.intervalId);
        this.createInterval();
    }
}