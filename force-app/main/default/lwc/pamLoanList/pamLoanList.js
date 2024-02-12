import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateLoanShares from '@salesforce/apex/PamLoanListController.updateLoanShares';
import getLoans from '@salesforce/apex/PamLoanListController.getLoans';

export default class PamLoanList extends LightningElement {
    @track toggleSwitch = false;
    loanId;
    isLoading = false;
    @api contactId;
    @api accountId;
    relatedLoans;
    sortedLoans;
    headingText;
    msg;
    error;
    lnLink;

    connectedCallback() {
        console.log('in the connected callback of loan relationshipList');
        console.log('contact id', this.contactId );
        console.log('accountId in loanlist:', this.accountId);
        this.isLoading = true;
        this.headingText = 'No loans found';
        this.getRelatedLoans();
    }

    getRelatedLoans(){
        getLoans({contactId: this.contactId })
           .then(result => {
                console.log(result);
                this.relatedLoans = result;
                this.sortedLoans = this.relatedLoans.sort((a, b) => a.name.localeCompare(b.name));
                this.isLoading = false;
                if(this.sortedLoans.length !== 0){
                this.headingText = 'These are all the loans this relationship is involved in. Enabled loans are visible to this relationship in Customer Portal.'
                }
            })
           .catch(error => {
                console.error(error);
                this.isLoading = false;
                this.error = error;
                this.relatedLoans = [];
            });
    }

    handleFlip(event){
        this.loanId = event.currentTarget.dataset.id;
        console.log('flipping');
        console.log('loanId', this.loanId);
        this.toggleSwitch = event.currentTarget.checked;
        console.log('checked? ', event.currentTarget.checked); 
        this.updateShares();                   
    }  

    updateShares(){
        this.isLoading = true;
        updateLoanShares({contactId: this.contactId, loanId: this.loanId, flippedOn: this.toggleSwitch})
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
        const element = this.template.querySelector('lightning-input');
        element.checked =!this.toggleSwitch;
    }
    
    loanLink(event){
        console.log('link clicked');
        console.log('event', event);
        this.lnLink = event.currentTarget.dataset.link;
        console.log('link', this.link);
        this.navigateToLink();
    }

    navigateToLink() {
        window.location.href = window.location.origin +'/'+ this.lnLink;
    }
}