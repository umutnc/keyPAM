/**
* @description Fetches documents for the given account Id and returns them as a list of Document objects.
* Queries for AccountDocument records where the account Id matches the input and the Portal_Enabled flag is true.
* Converts each AccountDocument into a Document object containing relevant fields.
*/
public with sharing class PamToDoListController {

    @AuraEnabled
    public static List<Document> getDocuments(string accountId){
        try {
            List<LLC_BI__AccountDocument__c> documents = [SELECT Id, Name, LLC_BI__reviewStatus__c, LLC_BI__Portal_Doc_Name__c, 
                                                            LLC_BI__Account__r.Name, LLC_BI__Portal_Enabled__c, LLC_BI__Account__c
                                                            FROM LLC_BI__AccountDocument__c 
                                                            WHERE LLC_BI__Account__c = :accountId
                                                            AND LLC_BI__Portal_Enabled__c = : true
                                                            ];

            List<Document> documentsList = new List<Document>();
            if(documents!= null) {
                for(LLC_BI__AccountDocument__c document : documents) {
                    Document doc = new Document();
                    doc.id = document.Id;
                    doc.status = document.LLC_BI__reviewStatus__c;
                    if(document.LLC_BI__Portal_Doc_Name__c!= null) {
                        doc.placeholder = document.LLC_BI__Portal_Doc_Name__c;
                    }else{
                        doc.placeholder = document.Name;
                    }
                    doc.documentManager = document.LLC_BI__Account__r.Name;
                    doc.style = 'slds-badge '+ document.LLC_BI__reviewStatus__c;
                    documentsList.add(doc);
                }   
            }
            return documentsList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class Document {
        @auraEnabled public String id {get; set;}
        @auraEnabled public String status {get; set;}
        @auraEnabled public String placeholder {get; set;}
        @auraEnabled public String documentManager {get; set;}
        @auraEnabled public String style {get; set;}

        public Document(String id, String status, String placeholder, String documentManager, String style) {
            this.id = id;
            this.status = status;
            this.placeholder = placeholder;
            this.documentManager = documentManager;
            this.style = style;
        }

        public Document() {}
    }
}