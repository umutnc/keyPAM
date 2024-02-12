import { LightningElement, track, api } from 'lwc';
import getContacts from '@salesforce/apex/PamContactController.getContacts';
//import updateContacts from '@salesforce/apex/PamContactController.updateContacts';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class PamContactList extends LightningElement {
    
    @track contacts;
    @api recordId;
    @track isFlipped = false;
    contact;
    selectedContacts;
    isLoading = false;
    msg;
    accountId;
    
    connectedCallback() {
        this.isLoading = true;
        console.log('in the connected callback');
        this.getContactsFromServer();
        console.log('account id in parent ', this.accountId);
    }

   get hasContacts() {
    return this.contacts && this.contacts.length > 0;
   }

    getContactsFromServer() {
        getContacts({ accountId: this.recordId })
           .then(result => {
                this.isLoading = false;
                console.log(result);
                this.contacts = result;
                this.selectedContacts = [...result].sort(function(a, b){
                    if(a.name < b.name) { return -1; }
                    if(a.name > b.name) { return 1; }
                    return 0;
                });
            })
           .catch(error => {
                console.error(error);
                this.contacts = [];
            });
    }
    // Contact update function removed from this stage as per Key's request...
    // handleToggle(event) {
    //     this.isFlipped = event.detail.isFlipped;
    //     this.contact = event.detail.contact;
    //     console.log('contact', this.contact);
    //     console.log('is flipped', this.isFlipped);
    //     this.invokePAM();
    // }

    // invokePAM() {
    //     this.isLoading = true;
    //     console.log('invoking PAM');
    //     console.log('contactId', this.contact.contactId);
    //     console.log('isFlipped', this.isFlipped);
    //     console.log('record id', this.recordId);
    //     updateContacts({ contactId: this.contact.contactId, accId: this.recordId, flippedOn: this.isFlipped })
    //     .then(result => {
    //         this.isLoading = false;
    //         console.log(result);
    //         this.msg = JSON.stringify(result);
    //         if (this.msg === '\"Record updated\"') {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Success',
    //             message: result,
    //             variant:'success'
    //         }));
    //         }else{
    //             this.dispatchEvent(new ShowToastEvent({
    //             title: 'Error',
    //             message: JSON.stringify(result),
    //             variant: 'error'
    //         }));
    //         }
    //      })
    //      .catch(error => {
    //         this.isLoading = false;
    //         console.error('error', error);
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Error',
    //             message: 'Contact update failed ', error,
    //             variant: 'error'
    //         }));
    //      })
    // }

    filterContacts(event) {
        console.log('event.target.label', event.target.label);
        const selectedFilter = event.target.label;
        if (selectedFilter === 'Disabled') {
            this.selectedContacts = this.contacts.filter((contact) => contact.isEnabled !== true);
            this.selectedContacts = this.selectedContacts.sort(function(a, b){
                if(a.name < b.name) { return -1; }
                if(a.name > b.name) { return 1; }
                return 0;
            });
        } else if (selectedFilter === 'Enabled') {
            this.selectedContacts = this.contacts.filter((contact) => contact.isEnabled === true);
            this.selectedContacts = this.selectedContacts.sort(function(a, b){
                if(a.name < b.name) { return -1; }
                if(a.name > b.name) { return 1; }
                return 0;
            });
        } else if (selectedFilter === 'All') {
            this.selectedContacts = this.contacts.filter((contact) => contact.isEnabled === true || contact.isEnabled !== true);
            this.selectedContacts = this.selectedContacts.sort(function(a, b){
                if(a.name < b.name) { return -1; }
                if(a.name > b.name) { return 1; }
                return 0;
            });
        }
    }
}