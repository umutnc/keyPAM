/**
 * Retrieves a list of LoanWrapper records for the given contactId. 
 * 
 * The LoanWrapper contain information about each loan related to the account, 
 * including name, stage, status, and portal visibility status if applicable.
 * 
 * Update loan shares based on the toggle swith activity on the PAM page.
 */
public with sharing class PamLoanListController {
    
    @AuraEnabled
    public static List<LoanWrapper> getLoans(String contactId){

        List<Contact> contacts = [SELECT Id, name, AccountId FROM Contact WHERE Id =: contactId];
        List<Account> accList = [SELECT id, name FROM Account WHERE Id =: contacts[0].AccountId];

        List <LLC_BI__Legal_Entities__c > loans = [SELECT id, LLC_BI__Loan__r.Name, LLC_BI__Loan__c, LLC_BI__Loan__r.LLC_BI__Stage__c, 
                                                    LLC_BI__Loan__r.LLC_BI__Status__c, LLC_BI__Borrower_Type__c, LLC_BI__Account__c from LLC_BI__Legal_Entities__c 
                                                    WHERE LLC_BI__Account__c =: accList[0].Id
                                                    AND LLC_BI__Loan__c != null]; 

        User usr = PamSharingUtility.getUser(contactId);
        Set<String> userIds = new Set<String>();
        List<String> loanShares = new List<String>();

        if(usr != null){
            userIds.add(usr.Id);
            Map<String,Set<String>> loanShareMap = PamSharingUtility.getLoanShareMap(userIds);
            loanShares = new List<String>(loanShareMap.get(usr.Id));
        }   
        try {
            List<LoanWrapper> loanList = new List<LoanWrapper>();
            if(loans.size() > 0){
                for(LLC_BI__Legal_Entities__c loan : loans){
                    LoanWrapper loanWrapper = new LoanWrapper();
                    String loId = loan.LLC_BI__Loan__r.Id;
                    loanWrapper.loanId = loId;
                    loanWrapper.name = loan.LLC_BI__Loan__r.Name;
                    loanWrapper.borrowerType = loan.LLC_BI__Borrower_Type__c;
                    loanWrapper.stage = loan.LLC_BI__Loan__r.LLC_BI__Stage__c;
                    loanWrapper.status = loan.LLC_BI__Loan__r.LLC_BI__Status__c;
                    if(loanShares.contains(loId)){
                        loanWrapper.isEnabled = true;
                    }else{
                        loanWrapper.isEnabled = false;
                    }
                    loanList.add(loanWrapper);
                }
            }
            return loanList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String updateLoanShares(String contactId, String loanId, Boolean flippedOn) {
        
        String message;
        List<Contact> con = [SELECT Id, Name, FirstName, Email, AccountId FROM Contact WHERE Id =: contactId];

        Map<String,Set<String>> loanShareMap = new Map<String,Set<String>>();
        User usr = PamSharingUtility.getUser(contactId);
        String dupeUser = PamSharingUtility.checkDuplicateUsers(con[0].Email);

        if(usr != null){
        loanShareMap = PamSharingUtility.getAllShareMap(usr.Id);
        }
        
        try {
            if(flippedOn){
                if(usr == null){
                    if(con[0].Email == null || con[0].Email == '') {
                        message = 'Please provide an email address for the user.';
                        return message;
                    }else{
                        if(dupeUser != null) {
                            message = 'There is already a user '+ dupeUser +' with the username '+ con[0].email + 
                            ' in the system. Please contact your nCino administrator.';
                            return message;
                        } else {
                            String result = PamInvokenPortal.grantAccess(loanId, contactId);
                            PamSharingUtility.updateContactFlag(contactId, true);
                            if(result != null) {
                                message = result;
                            }else{
                                message = 'Record updated';
                            } 
                        }
                    }
                }else{
                    String result = PamInvokenPortal.grantAccess(loanId, contactId);
                    PamSharingUtility.updateContactFlag(contactId, flippedOn);
                    if(result != null) {
                        message = result;
                    }else{
                        message = 'Record updated';
                    } 
                }                           
            } else if (!flippedOn){
                if(usr != null){
                    loanShareMap = PamSharingUtility.getAllShareMap(usr.Id);
                    Set<String> shareSet = loanShareMap.get(usr.Id);
                    shareSet.remove(loanId);
                    //If they have shares we don't clear the flag just delete the current share..
                    if(shareSet.size() > 0){
                        deleteLoanShares(usr.Id, loanId); 
                        message = 'Record updated';
                    } else {
                        PamInvokenPortal.revokeAccess(loanId, contactId);
                        PamSharingUtility.updateContactFlag(contactId, flippedOn);
                        PamSharingUtility.deactivateUser(usr.Id);
                        //Return the success message.
                        message = 'Record updated';
                    }                        
                }
            }      
            }catch(Exception e) {
                message = e.getMessage();
                throw new AuraHandledException(e.getMessage());
            }
            return message;
}
    public static void deleteLoanShares (Id userId, Id loanId) {
        List<LLC_BI__Loan__Share> shares = [SELECT Id FROM LLC_BI__Loan__Share WHERE ParentId =: loanId AND UserOrGroupId =: userId];

        if(shares!= null && shares.size() > 0) {
            delete shares;
        }
    }

    public class LoanWrapper {   

        @AuraEnabled 
        public String loanId;
    
        @AuraEnabled 
        public String name;
    
        @AuraEnabled 
        public String borrowerType;

        @AuraEnabled 
        public String stage;

        @AuraEnabled 
        public String status;
    
        @AuraEnabled
        public Boolean isEnabled;
    
        }    
}