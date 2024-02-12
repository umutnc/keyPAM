import { LightningElement, api, track} from 'lwc';
import getDocuments from '@salesforce/apex/PamToDoListController.getDocuments';

export default class PamToDoList extends LightningElement {
    @api recordId;
    @api contact;
    error;
    @api accountId;
    @api docs;
    headingText;

    connectedCallback() {
        getDocuments({accountId: this.accountId})
           .then(result => {
                console.log('result', result);
                this.docs = result;
                if(this.docs.length !== 0){
                    this.headingText = 'To-Do list depicts all Portal requested documents for this relationship.';
                }else{
                    this.headingText = 'No documents found';
                }
            })
           .catch(error => {
                console.log('error', error);
                this.error = error;
                this.docs = [];
            });
        }
    }