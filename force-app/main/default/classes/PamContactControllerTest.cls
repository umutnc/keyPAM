@isTest
private class PamContactControllerTest {

  @isTest
  static void testUpdateContacts() {
    // Arrange
    
    Account acc = new Account();
      acc.name = 'Test Account';
    insert acc;

    Contact con = new Contact();
      con.FirstName = 'Adam';
      con.LastName = ' Smith';
      con.Email = 'sometest@email.com';
      con.isnCinoPortalUser__c = false;
      con.AccountId = acc.Id;
    insert con;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'nCino Community User' LIMIT 1];
    User u = new User();
      u.Username = DateTime.now().getTime() + '@ncino.com';
      u.FirstName = con.FirstName;
      u.LastName = con.LastName;
      u.Email = u.Username;
      u.Alias = 'asmith';
      u.TimeZoneSidKey = 'GMT';
      u.LocaleSidKey = 'en_US';
      u.EmailEncodingKey = 'UTF-8';
      u.ProfileID = p.Id;
      u.LanguageLocaleKey = 'en_US';
      u.ContactId = con.Id;
      
    System.runAs(new User(id = UserInfo.getUserId())) {
        insert u;
    }
    Boolean flippedOn = true;

    Test.startTest();
    String result = PamContactController.updateContacts(con.Id, acc.Id, flippedOn);
	  Test.stopTest();    	
    
    Assert.areEqual(true, con.isnCinoPortalUser__c); 
    // Act
    // 
    //Test.startTest();
    //String result = PamContactController.updateContacts(con.Id, acc.Id, flippedOn);
    //Test.stopTest();
    
    // Assert
    //Assert.areEqual(result, 'Result should not be null'); 
  }

  @isTest
  static void testUpdateContactsNegative() {
    // Arrange
    String contactId = '003xx000003DlK5AAK';
    String accId = '001xx000003GFLGAA4'; 
    Boolean flippedOn = false;
    
    // Act
    Test.startTest();
    String result = PamContactController.updateContacts(contactId, accId, flippedOn);
    Test.stopTest();
    
    // Assert
    System.assert(result != null, 'Result should not be null');
  }

  @isTest
  static void testGetConnections() {
    // Arrange
    String accountId = '001xx000003GFLGAA4';
    
    // Act
    Test.startTest();
    List<LLC_BI__Connection__c> result = PamContactController.getConnections(accountId);
    Test.stopTest();
    
    // Assert
    System.assert(!result.isEmpty(), 'Result should not be empty');
  }

  @isTest
  static void testGetUser() {
    // Arrange
    String contactId = '003xx000003DlK5AAK';
    
    // Act 
    Test.startTest();
    User result = PamContactController.getUser(contactId);
    Test.stopTest();
    
    // Assert
    System.assert(result != null, 'Result should not be null');
  }

  @isTest
  static void testCheckDuplicateUsers() {
    // Arrange
    String email = 'test@example.com'; 
    
    // Act
    Test.startTest();  
    String result = PamContactController.checkDuplicateUsers(email);
    Test.stopTest();
    
    // Assert
    System.assert(result != null, 'Result should not be null');
  }


}