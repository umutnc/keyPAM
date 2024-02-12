/**
 * Apex controller class for PamRelationshipList Lightning component.
 * Contains logic for querying and returning connected relationship data for a Contact.
 */
public with sharing class PamRelationshipListController {
    
@AuraEnabled
public static List<RelationshipWrapper> getConnectedRelationships(string contactId){
    
    Set<String> relationshipIds = new Set<String>();
    List<Contact> contacts = [SELECT Id, name, AccountId FROM Contact WHERE Id =: contactId];
    List<Account> accList = [SELECT id, name FROM Account WHERE Id =: contacts[0].AccountId];
    String accId= accList[0].id;

    List<LLC_BI__Connection__c> connections = PamContactController.getConnections(accId);
    Map<String,String> roleMap = new Map<String,String>();

    for(LLC_BI__Connection__c connection : connections) {
        if(connection.LLC_BI__Connected_From__c == accId) {
            relationshipIds.add(connection.LLC_BI__Connected_To__c);
            roleMap.put(connection.LLC_BI__Connected_To__c, connection.LLC_BI__Role__c);   
        } else if (connection.LLC_BI__Connected_To__c == accId) {
            relationshipIds.add(connection.LLC_BI__Connected_To__c);
            roleMap.put(connection.LLC_BI__Connected_From__c, connection.LLC_BI__Role__c);
        }   
    }
    relationshipIds.add(accId);
    List<Account> allAccounts =  [SELECT id, name FROM Account WHERE Id in : relationshipIds];
    
    User usr = PamSharingUtility.getUser(contactId);
    Set<String> userIds = new Set<String>();
    Map<String,Set<String>> accShareMap = new Map<String,Set<String>>();

    if(usr != null){
        system.debug('user is not null');
        userIds.add(usr.Id);
        accShareMap = PamSharingUtility.getAccShareMap(userIds);
    }
    try {
        List<RelationshipWrapper> relWrap = new List<RelationshipWrapper>();

       for (Account acc : allAccounts) {
            RelationshipWrapper rel = new RelationshipWrapper();
            rel.accountId = acc.Id;
            rel.name = acc.name;
            if(acc.id == accId){
                rel.role = 'Relationship';
            } else{
                rel.role = roleMap.get(acc.id);
            }
            if (accShareMap.size()> 0 && accShareMap.get(usr.Id).contains(acc.id)) {
                rel.isEnabled = true;
            }else{ 
                rel.isEnabled = false;
            }
            relWrap.add(rel);
       }

       return relWrap;
        
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

@AuraEnabled
public static List<RelationshipWrapper> getAccountInfo(String contactId){
    
    List<RelationshipWrapper> relWrap = new List<RelationshipWrapper>();
    RelationshipWrapper rel = new RelationshipWrapper();

    List<Contact> conList = [SELECT id, AccountId FROM Contact WHERE Id =: contactId];
    List<Account> accList = [SELECT id, name FROM Account WHERE Id =: conList[0].AccountId];

    rel.name = accList[0].name;
    rel.accountId = accList[0].id;
    relWrap.add(rel);

    return relWrap;
}

@AuraEnabled
public static String updateAccountShares(String contactId, String accId, Boolean flippedOn) {
    
    String message;
    
    try {
        message = PamContactController.updateContacts(contactId, accId, flippedOn);
    } catch (Exception ex) {
        message = ex.getMessage();
    }   
    return message;   
}

public class RelationshipWrapper {   

    @AuraEnabled 
    public String accountId;

    @AuraEnabled 
    public String name;

    @AuraEnabled 
    public String role;

    @AuraEnabled
    public Boolean isEnabled;

    }    
}