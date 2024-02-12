import { LightningElement, api, track } from 'lwc';


export default class ContactTile extends LightningElement {
 @api contact;
 @track isFlipped = false;
 @api recordId;
 @api accountId;
 @api contactId;
 @track childVisible = false;
 chevronIconName = 'utility:chevronright';
 contactLink;

 handleFlip(event) {
    console.log('flipping');
    this.isFlipped = event.target.checked;
    this.dispatchEvent(new CustomEvent('flip', { detail: { contact: this.contact, isFlipped: this.isFlipped } }));
    console.log('passing event to parent', event);
    }

    toggleChildVisibility(){
        this.childVisible =!this.childVisible;
        this.chevronIconName = this.childVisible? 'utility:chevrondown' : 'utility:chevronright';
    }

    conLink(event){
        this.contactLink = event.currentTarget.dataset.link;
        this.navigateToLink();
    }

    navigateToLink() {
        window.location.href = window.location.origin +'/'+ this.contactLink;
    }

}