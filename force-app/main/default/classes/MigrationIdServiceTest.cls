@isTest
public class MigrationIdServiceTest {
  @isTest
  static void testMigrationService() {
    // Using an account record to test
    SObject testAccount = new Account();

    Test.startTest();

    MigrationIdService.addMigrationId(new List<SObject>{testAccount}, 'Name');

    system.assert(testAccount.get('Name') != null);
    system.assertEquals('REC', ((String) testAccount.get('Name')).left(3));

    Test.stopTest();
  }
}
