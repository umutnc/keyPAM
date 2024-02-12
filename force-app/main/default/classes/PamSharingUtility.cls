/**
* Retrieves all manual sharing records for the given user across Accounts, Loans and Deposits.
* 
* @param userId The Id of the user to retrieve sharing for.
* @return A map of the user's Id to the set of shared record Ids.
*/
public with sharing class PamSharingUtility {
    
    public static Map<String,Set<String>> getAllShareMap(String userId) {

        Map<String,Set<String>> allSharesMap = new Map<String,Set<String>>();
        Set<String> userIds = new Set<String>();
        userIds.add(userId);

        Map<String,Set<String>> accShareMap = getAccShareMap( userIds);
        Map<String,Set<String>> loanShareMap = getLoanShareMap(userIds);
        Map<String,Set<String>> depositShareMap = getDepositShareMap(userIds);
        
        Set<String> allShares = new Set<String>();

        if(accShareMap.size() > 0) {
        allShares.addAll(accShareMap.get(userId));
        } 
        if(loanShareMap.size() > 0) {
        allShares.addAll(loanShareMap.get(userId));
        }
        if(depositShareMap.size() > 0) {
        allShares.addAll(depositShareMap.get(userId));
        }
        allSharesMap.put(userId, allShares);
        return allSharesMap;
    }
    
    public static Map<String,Set<String>> getAccShareMap(Set<String> userIds) {

        Map<String,Set<String>> accShareMap = new Map<String,Set<String>>();
        List<AccountShare> accShareList = [SELECT Id, AccountId, UserOrGroupId, RowCause FROM AccountShare Where UserOrGroupId In: userIds AND RowCause ='Manual'];

        for(AccountShare accShare : accShareList) {
            if(userIds.contains(accShare.UserOrGroupId)) {
                if(!accShareMap.containsKey(accShare.UserOrGroupId)) {   
                accShareMap.put(accShare.UserOrGroupId, new Set<String>());
                accShareMap.get(accShare.UserOrGroupId).add(accShare.AccountId);
                }else{
                accShareMap.get(accShare.UserOrGroupId).add(accShare.AccountId);
                }
            }  
        }
        return accShareMap;
    }

    public static Map<String,Set<String>> getLoanShareMap(Set<String> userIds) {

        Map<String,Set<String>> loanShareMap = new Map<String,Set<String>>();
        List<LLC_BI__Loan__Share> loanShares = [SELECT Id, ParentId, UserOrGroupId, RowCause FROM LLC_BI__Loan__Share WHERE UserOrGroupId IN: userIds AND RowCause ='Manual'];
        
        for(LLC_BI__Loan__Share loanShare : loanShares) {
           if(userIds.contains(loanShare.UserOrGroupId)) {
                if(!loanShareMap.containsKey(loanShare.UserOrGroupId)) {
                    loanShareMap.put(loanShare.UserOrGroupId, new Set<String>());
                    loanShareMap.get(loanShare.UserOrGroupId).add(loanShare.ParentId);
                }else{
                    loanShareMap.get(loanShare.UserOrGroupId).add(loanShare.ParentId);
                }
            }   
        }
        return loanShareMap;
    }

    public static Map<String,Set<String>> getDepositShareMap(Set<String> userIds) {

        Map<String,Set<String>> depositShareMap = new Map<String,Set<String>>();
        List<LLC_BI__Deposit__Share> depositShares = [SELECT Id, ParentId, UserOrGroupId, RowCause FROM LLC_BI__Deposit__Share WHERE UserOrGroupId IN: userIds AND RowCause ='Manual'];
    
        for(LLC_BI__Deposit__Share depositShare : depositShares) {
            if(userIds.contains(depositShare.UserOrGroupId)) {
                if(!depositShareMap.containsKey(depositShare.UserOrGroupId)) {
                depositShareMap.put(depositShare.UserOrGroupId, new Set<String>());
                depositShareMap.get(depositShare.UserOrGroupId).add(depositShare.ParentId);
            }else{
                depositShareMap.get(depositShare.UserOrGroupId).add(depositShare.ParentId);
            }
        }
    }
    return depositShareMap;
    }

    public static User getUser(String contactId){
        
        User us;
        List<User> users = [SELECT Id, Name, LastLoginDate, ContactId, IsActive FROM User 
                            WHERE ContactId =: contactId];
        for(User usr: users){
            us = usr;
        }
        return us;
    }

    public static String checkDuplicateUsers(String email) {
        List<User> users = [SELECT Id, Name, Email, LastLoginDate, ContactId, IsActive FROM User
                            WHERE Email =: email];
    
        String dupeUser = null;
        if(users!= null && users.size() > 0) {
            dupeUser = users[0].Name;
        }
        return dupeUser;
    }

    // public static String checkDuplicateUsersByEmail(String email) {
    //     List<User> users = [SELECT Id, Name, Email, LastLoginDate, ContactId, IsActive FROM User
    //                         WHERE Email =: email];
    
    //     String dupeUser = null;
    //     if(users!= null && users.size() > 0) {
    //         dupeUser = users[0].Name;
    //     }
    //     return dupeUser;
    // }

    // This method may be voided by the nCino nPORTAL updates.
    @future
    public static void updateContactFlag(String contactId, Boolean flippedOn) {
        Contact con = new Contact(
            Id = contactId,
            isnCinoPortalUser__c = flippedOn
        );
        if(con!= null) {
            update con;
        }
    }
    //@future
    public static void deactivateUser(String userId) {
        PamUserUtilQueueable queueable = new PamUserUtilQueueable(userId);
        System.enqueueJob(queueable);
    }
}