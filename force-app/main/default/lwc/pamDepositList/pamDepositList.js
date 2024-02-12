import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateDepositShares from '@salesforce/apex/PamDepositListController.updateDepositShares';
import getDeposits from '@salesforce/apex/PamDepositListController.getDeposits';

export default class PamDepositList extends LightningElement {
    @track toggleSwitch = false;
    depositId;
    isLoading = false;
    @api contactId;
    @api accountId;
    relatedDeposits;
    sortedDeposits;
    headingText;
    msg;
    error;
    depositLink;

    connectedCallback() {
        console.log('in the connected callback of loan depo list');
        console.log('contact id', this.contactId );
        console.log('accountId in loanlist:', this.accountId);
        this.isLoading = true;
        this.headingText = 'No deposits found';
        this.getrelatedDeposits();
    }

    getrelatedDeposits(){
        getDeposits({contactId: this.contactId })
           .then(result => {
                console.log(result);
                this.relatedDeposits = result;
                this.sortedDeposits = this.relatedDeposits.sort((a, b) => a.name.localeCompare(b.name));
                this.isLoading = false;
                if(this.sortedDeposits.length !== 0){
                this.headingText = 'These are all the deposits this relationship is involved in. Enabled deposits are visible to this relationship in Customer Portal.'
                }
            })
           .catch(error => {
                console.error(error);
                this.isLoading = false;
                this.error = error;
                this.relatedDeposits = [];
            });
    }

    handleFlip(event){
        this.depositId = event.currentTarget.dataset.id;
        console.log('flipping');
        console.log('depositId', this.depositId);
        this.toggleSwitch = event.currentTarget.checked;
        console.log('checked? ', event.currentTarget.checked); 
        this.updateShares();                   
    }  

    updateShares(){
        this.isLoading = true;
        updateDepositShares({contactId: this.contactId, depositId: this.depositId, flippedOn: this.toggleSwitch})
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
    
    depoLink(event){
        console.log('link clicked');
        console.log('event', event);
        this.depositLink = event.currentTarget.dataset.link;
        console.log('link', this.link);
        this.navigateToLink();
    }

    navigateToLink() {
        window.location.href = window.location.origin +'/'+ this.depositLink;
    }
}