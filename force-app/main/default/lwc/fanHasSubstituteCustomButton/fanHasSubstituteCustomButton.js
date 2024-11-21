import { LightningElement, api } from 'lwc';

export default class FanHasSubstituteCustomButton extends LightningElement {
    @api recordId;
    @api buttonName;
    @api isActive;
    get isDisabled(){
        return !this.isActive;
    }
 
    handleClick(){
        let paramData = {recordId : this.recordId};
        const ev = new CustomEvent('hassubstitutecustombuttonevent', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: paramData
        });
        this.dispatchEvent(ev);
    }
}