/**
 * Retrieves a list of ContactWrapper records for the given accountId. 
 * 
 * The ContactWrappers contain information about each contact related to the account, 
 * including name, email, portal access status, and last login date if applicable.
 * 
 * Connections are queried to determine which accounts are related to the input accountId.
 * The contacts for those related accounts are then queried and wrapped with additional info.
 */
public with sharing class PamContactController {
    
    @AuraEnabled(cacheable=true)
    public static List<ContactWrapper> getContacts(string accountId) {

        List<ContactWrapper> contactWrappers = new List<ContactWrapper>();
        List<LLC_BI__Connection__c> connections = getConnections(accountId);
          
        Set<String> connectedAccountIds = new Set<String>();
        Map<String,String> roleMap = new Map<String,String>();
        // Connections are required to determine the roles of the connected accounts.
        if(connections!= null){
            for(LLC_BI__Connection__c con : connections) {
                if(con.LLC_BI__Connected_From__c == accountId) {
                    connectedAccountIds.add(con.LLC_BI__Connected_To__c);
                    roleMap.put(con.LLC_BI__Connected_To__c, con.LLC_BI__Role__c);
                } else if (con.LLC_BI__Connected_To__c == accountId) {
                    connectedAccountIds.add(con.LLC_BI__Connected_From__c);
                    roleMap.put(con.LLC_BI__Connected_From__c, con.LLC_BI__Role__c);
                }
            }
        }
        connectedAccountIds.add(accountId);

        List<Contact> cons = [SELECT Id , Name, Email, isnCinoPortalUser__c, AccountId FROM Contact 
                                WHERE AccountId IN : connectedAccountIds];
        Map<String, User> userContactMap = new Map<String, User>();
        
        List<User> users = [SELECT Id, Name, Username , LastLoginDate, ContactId, IsActive FROM User 
                            WHERE ContactId IN: cons];
        Map<String,Set<String>> accShareMap = new Map<String,Set<String>>();
        Set<String> userIds = new Set<String>();
       if(users != null && users.size()>0){
            for(User usr: users){
                userContactMap.put(usr.ContactId, usr);
                userIds.add(usr.Id);
            }
            accShareMap = PamSharingUtility.getAccShareMap(userIds);
       }
        if(cons != null) {
            for(Contact c : cons) {
                User us = userContactMap.get(c.Id);
                ContactWrapper wrapper = new ContactWrapper();
                wrapper.contactId = c.Id;
                wrapper.name = c.Name;
                wrapper.email = c.Email;
                if (us != null) {
                    if (us.LastLoginDate!= null) {
                        wrapper.lastLoginDate = String.valueOf(us.LastLoginDate.format('MMM dd, yyyy hh:mm', 'America/New_York'));
                    }else{
                        wrapper.lastLoginDate = '--'; // Set to null if us is not populated
                    }
                    wrapper.userName = us.Username;
                } else {
                    wrapper.lastLoginDate = '--'; // Set to null if us is not populated
                }
                if(c.AccountId == accountId) {
                    wrapper.role = 'Relationship';
                } else {
                    wrapper.role = roleMap.get(c.AccountId);
                }
                if(us != null){
                    if(accShareMap.containsKey(us.Id)) {
                        Set<String> shares = accShareMap.get(us.Id);
                        System.debug('shares' +shares );
                        if(shares!= null) {
                            if(shares.contains(accountId)) {
                                wrapper.isEnabled = true;
                            } else {
                                wrapper.isEnabled = false;
                            }
                        }else{
                            wrapper.isEnabled = false;
                        }
                    }else{
                        wrapper.isEnabled =false;
                    }
                }else{
                    wrapper.isEnabled = false;
                }
                ContactWrappers.add(wrapper); 
                }  
            }
        return ContactWrappers;
}
    //This is to update the given contact based on the toggle switch activity.
    @AuraEnabled
    public static String updateContacts (string contactId, string accId, boolean flippedOn) {
        
        String message;
        List<Contact> con = [SELECT Id, FirstName, Name, AccountId, Email, isnCinoPortalUser__c FROM Contact WHERE Id =: contactId LIMIT 1];
        User us = PamSharingUtility.getUser(contactId);
        String dupeUser = PamSharingUtility.checkDuplicateUsers(con[0].Email);

        try {
            if(flippedOn) {
                if(us == null){
                    if(con[0].Email == null || con[0].Email == '') {
                        message = 'Please provide an email address for the user.';
                        return message;
                    }else{
                        if(dupeUser != null) {
                            message = 'There is already a user '+ dupeUser +' with the username '+ con[0].email + 
                            ' in the system. Please contact your nCino administrator.';
                            return message;
                        } else {
                            String result = PamInvokenPortal.grantAccess(accId, contactId);
                            PamSharingUtility.updateContactFlag(contactId, true); // This is going to be done by nPORTAL code.
                            if(result != null) {
                                message = result;
                            }else{
                                message = 'Record updated';
                            } 
                        }
                    }
                }else{
                    String result = PamInvokenPortal.grantAccess(accId, contactId);
                    PamSharingUtility.updateContactFlag(contactId, true); // This is going to be done by nPORTAL code.
                    if(result != null) {
                        message = result;
                    }else{
                        message = 'Record updated';
                    } 
                }               
            }else if (!flippedOn) {
                Map<String,Set<String>> accShareMap = new Map<String,Set<String>>();
                if(us != null){
                    accShareMap = PamSharingUtility.getAllShareMap(us.Id);
                    Set<String> shareSet = accShareMap.get(us.Id);
                    shareSet.remove(accId);
                    //If they have shares we don't clear the flag just delete the current share..
                    if(shareSet.size() > 0){
                        deleteAccShares(us.Id, accId); 
                        message = 'Record updated';
                    } else {
                        //If they don't have shares we can clear the flag and deactivate the user.
                        String result = PamInvokenPortal.revokeAccess(accId, contactId);
                        PamSharingUtility.updateContactFlag(contactId, false); // This is going to be done by nPORTAL code.
                        PamSharingUtility.deactivateUser(us.Id);
                        //Return the success message.
                        if(result != null) {
                            message = result;
                        }
                        message = 'Record updated';
                    }                        
                }else{
                    message = 'No user found for this contact. Please contact your nCino administrator.';
                }
            }      
        } catch (Exception e) {
            message = e.getMessage(); 
        }
        return message;
    }

    public static List<LLC_BI__Connection__c> getConnections(string accountId) {
        
        List<LLC_BI__Connection__c> connections = new List<LLC_BI__Connection__c>(
                                                [SELECT Id, LLC_BI__Role__c, LLC_BI__Connected_From__c, LLC_BI__Connected_To__c 
                                                FROM LLC_BI__Connection__c Where LLC_BI__Connected_From__c =: accountId 
                                                OR LLC_BI__Connected_To__c =: accountId]
        );
        return connections;
    }
    
    //delete account shares should be used when we can't call nCino PAM.
    public static void deleteAccShares(Id userId, Id accId) {
        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE UserOrGroupId =: userId AND AccountId =: accId AND RowCause =: 'Manual'];
        if(shares!= null && shares.size() > 0) {
            delete shares;
        }
    }
 
    public class ContactWrapper {   

        @AuraEnabled 
        public String contactId;

        @AuraEnabled 
        public String name;

        @AuraEnabled 
        public String email;

        @AuraEnabled
        public String role;

        @AuraEnabled
        public String userName;

        @AuraEnabled
        public String lastLoginDate;

        @AuraEnabled
        public Boolean isEnabled;
    }
}