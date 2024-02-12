import { LightningElement, api, track } from 'lwc';
import  getConnectedRelationships  from '@salesforce/apex/PamRelationshipListController.getConnectedRelationships';
import  getAccountInfo  from '@salesforce/apex/PamRelationshipListController.getAccountInfo';
import updateAccountShares from '@salesforce/apex/PamRelationshipListController.updateAccountShares';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class PamRelationshipList extends LightningElement {
    
    @track toggleSwitch = false;
    isLoading = false;
    accId;
    isLoading = false;
    @api contactId;
    @api contactName;
    @api accountId;
    @track account;
    connectedAccounts;
    sortedAccounts;
    headingText= 'Connected Accounts';
    msg;
    error;
    accountLink;
    
    connectedCallback() {
        this.isLoading = true;
        console.log('in the connected callback of relationshipList');
        console.log('contact id', this.contactId );
        console.log('recordid in rel:', this.recordId);
        console.log('accountId in rel:', this.accountId);
        this.getAccounts();
        this.getContactAccount();
         
    }
 
    getAccounts(){
        getConnectedRelationships({ contactId: this.contactId })
           .then(result => {
                console.log(result);
                this.isLoading = false;
                //this.connectedAccounts = result.filter(item =>item.accountId !== this.accountId);
                this.sortedAccounts = result.sort((a, b) => a.name.localeCompare(b.name));
                if(this.sortedAccounts.length !== 0){
                    this.headingText = 'These are all connected relationships to '+  this.account[0].name + '. Enabled relationships are visible in Customer Portal for '+ this.contactName ;
                }else{
                    this.headingText = 'No relationships found';
                }
                this.getContactAccount();

            })
           .catch(error => {
                console.error(error);
                this.connectedAccounts = [];
            });
    }

    getContactAccount(){
        getAccountInfo ({contactId: this.contactId})
        .then(result => {
            console.log('account retrieved in relationshiplist ' ,result);
            this.account = result;            
        })
        .catch(error => {
            console.error(error);
            this.account = undefined;
        });
    };

    handleFlip(event){
        this.accId = event.currentTarget.dataset.id;
        console.log('flipping');
        console.log('accId', this.accId);
        this.toggleSwitch = event.currentTarget.checked;
        console.log('checked? ', event.currentTarget.checked); 
        this.updateShares();                   
    }  

    updateShares(){
        this.isLoading = true;
        updateAccountShares({contactId: this.contactId, accId: this.accId, flippedOn: this.toggleSwitch})
        .then(result=>{
            this.isLoading = false;
            console.log(result);
            this.msg = JSON.stringify(result);
            if (this.msg === '\"Record updated\"') {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: result,
                    variant:'success'
                }));
                }else{
                    this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: JSON.stringify(result),
                    variant: 'error'
                }));
                this.revertToggle();
                }
            })
        .catch(error =>{
            this.isLoading = false;
            this.error = error;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: error,
                variant: 'error'
            }));
            this.revertToggle(); 
        })
    }

   revertToggle(){
    console.log('revert toggle');
    const element = this.template.querySelector('lightning-input');
    element.checked =!this.toggleSwitch;
   }

    accLink(event){
        console.log('link clicked');
        console.log('event', event);
        this.accountLink = event.currentTarget.dataset.link;
        console.log('link', this.link);
        this.navigateToLink();
    }

    navigateToLink() {
        window.location.href = window.location.origin +'/'+ this.accountLink;
    }
}