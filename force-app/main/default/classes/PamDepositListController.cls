/**
 * Retrieves a list of DepoWrapper records for the given contactId. 
 * 
 * The DepoWrapper contain information about each loan related to the account, 
 * including name, stage, type, and portal visibility status if applicable.
 * 
 * Update deposit shares based on the toggle swith activity on the PAM page.
 */
public with sharing class PamDepositListController {

    @AuraEnabled
    public static List<depoWrapper> getDeposits(String contactId){

        List<Contact> contacts = [SELECT Id, name, AccountId FROM Contact WHERE Id =: contactId];
        List<Account> accList = [SELECT id, name FROM Account WHERE Id =: contacts[0].AccountId];
        system.debug('acclist:'+accList);

        List <LLC_BI__Legal_Entities__c > deposits = [SELECT id, LLC_BI__Deposit__c, LLC_BI__Deposit__r.LLC_BI__Stage__c, LLC_BI__Deposit__r.Name,
                                                        LLC_BI__Relationship_Type__c, LLC_BI__Account__c from LLC_BI__Legal_Entities__c 
                                                        WHERE LLC_BI__Account__c =: accList[0].Id
                                                        AND LLC_BI__Deposit__c!= null];
        
        User usr = PamSharingUtility.getUser(contactId);
        Set<String> userIds = new Set<String>();
        List<String> depoShares = new List<String>();

        if(usr != null){
            userIds.add(usr.Id);
            System.debug('usr:'+usr);
            Map<String,Set<String>> depositShareMap = PamSharingUtility.getDepositShareMap(userIds);
            depoShares = new List<String>(depositShareMap.get(usr.Id));
        }    
        try {
            List<DepoWrapper> depoList = new List<DepoWrapper>();
            if(deposits.size() > 0){
                for(LLC_BI__Legal_Entities__c depo : deposits){
                    DepoWrapper depoWrapper = new DepoWrapper();
                    depoWrapper.depositId = depo.LLC_BI__Deposit__c;
                    depoWrapper.name = depo.LLC_BI__Deposit__r.Name;
                    depoWrapper.relationshipType = depo.LLC_BI__Relationship_Type__c;
                    depoWrapper.stage = depo.LLC_BI__Deposit__r.LLC_BI__Stage__c;
                    if(depoShares.contains(depo.LLC_BI__Deposit__c)){
                        depoWrapper.isEnabled = true;
                    }else{
                        depoWrapper.isEnabled = false;
                    }
                    depoList.add(depoWrapper);
                }
            }
            return depoList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String updateDepositShares(String contactId, String depositId, Boolean flippedOn) {
        
        String message;
        List<Contact> con = [SELECT Id, Name, FirstName, Email, AccountId FROM Contact WHERE Id =: contactId];
        
        Map<String,Set<String>> depoShareMap = new Map<String,Set<String>>();
        User usr = PamSharingUtility.getUser(contactId);
        String dupeUser = PamSharingUtility.checkDuplicateUsers(con[0].Email);

        if(usr != null){
            depoShareMap = PamSharingUtility.getAllShareMap(usr.Id);
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
                            String result = PamInvokenPortal.grantAccess(depositId, contactId);
                            PamSharingUtility.updateContactFlag(contactId, true); // This is going to be done by nPORTAL code.
                            if(result != null) {
                                message = result;
                            }else{
                                message = 'Record updated';
                            } 
                        }
                    }
                }else{
                    String result = PamInvokenPortal.grantAccess(depositId, contactId);
                    PamSharingUtility.updateContactFlag(contactId, flippedOn); // This is going to be done by nPORTAL code.
                    if(result != null) {
                        message = result;
                    }else{
                        message = 'Record updated';
                    } 
                }   
            } else if (!flippedOn){
                if(usr != null){
                    depoShareMap = PamSharingUtility.getAllShareMap(usr.Id);
                    Set<String> shareSet = depoShareMap.get(usr.Id);
                    shareSet.remove(depositId);
                    //If they have shares we don't clear the flag just delete the current share..
                    if(shareSet.size() > 0){
                        deleteDepoShares(usr.Id, depositId); 
                        message = 'Record updated';
                    } else {
                        //If they don't have shares we clear the flag and deactivate the user.
                        PamInvokenPortal.revokeAccess(depositId, contactId);
                        PamSharingUtility.updateContactFlag(contactId, flippedOn); // This is going to be done by nPORTAL code.
                        PamSharingUtility.deactivateUser(usr.Id);
                        //Return the success message.
                        message = 'Record updated';
                    }                        
                }else{
                    message = 'User not found';
                }
            }      
            }catch(Exception e) {
                message = e.getMessage();
                throw new AuraHandledException(e.getMessage());
            }
            return message;
    }
    
    public static void deleteDepoShares (Id userId, Id depositId) {
        List<LLC_BI__Deposit__Share> shares = [SELECT Id FROM LLC_BI__Deposit__Share WHERE ParentId =: depositId AND UserOrGroupId =: userId];

        if(shares!= null && shares.size() > 0) {
            delete shares;
        }
    }

    public class DepoWrapper {   

        @AuraEnabled 
        public String depositId;
    
        @AuraEnabled 
        public String name;
    
        @AuraEnabled 
        public String relationshipType;

        @AuraEnabled 
        public String stage;
   
        @AuraEnabled
        public Boolean isEnabled;
    
        }    
}