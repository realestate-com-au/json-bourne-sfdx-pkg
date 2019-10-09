@isTest
public with sharing class BourneRestApiTest {
  public static final String MIGRATION_FIELD_NAME = 'ProductCode';
  public static final String TEST_PRE_PLUGIN = 'Plugins.DefaultPreProcessor';
  public static final String TEST_POST_PLUGIN = 'Plugins.DefaultPostProcessor';

  @testsetup
  static void setup() {
    insert new BournePlugins__c(
      API_Pre_Processor__c = TEST_PRE_PLUGIN,
      API_Post_Processor__c = TEST_POST_PLUGIN
    );
    insert getTestProducts()[0];
  }

  @isTest
  public static void testImport() {
    Test.startTest();

    Map<String, Object> requestBody = new Map<String, Object>{
      'sObjectType' => 'Product2',
      'operation' => 'UPSERT',
      'payload' => getTestProducts(),
      'extIdField' => MIGRATION_FIELD_NAME
    };

    //normal import
    performOperation(requestBody);
    assertNumberOfProducts(2);

    requestBody.put('operation', 'DELETE');

    //normal delete
    performOperation(requestBody);
    assertNumberOfProducts(0);

    //delete something not present
    performOperation(requestBody);

    requestBody.put('operation', 'INVALID');

    //invalid operation
    performOperation(requestBody);

    Test.stopTest();
  }

  static void performOperation(Map<String, Object> body) {
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();

    req.requestURI = '/services/apexrest/bourne/v1';
    req.requestBody = Blob.valueOf(JSON.serialize(body));

    req.httpMethod = 'POST';
    RestContext.request = req;
    RestContext.response = res;

    BourneRestApi.import();
  }

  public static List<SObject> getTestProducts() {
    return (List<SObject>) (new List<Product2>{
      new Product2(
        Description =
          'First Example Product used for the JSON Bourne Testing methods',
        Family = 'Example',
        IsActive = false,
        Name = 'JSON Bourne Test Product 1',
        ProductCode = 'JSON_BOURNE_TEST_1',
        StockKeepingUnit = null
      ),
      new Product2(
        Description =
          'Second Example Product used for the JSON Bourne Testing methods',
        Family = 'Example',
        IsActive = false,
        Name = 'JSON Bourne Test Product 2',
        ProductCode = 'JSON_BOURNE_TEST_2',
        StockKeepingUnit = null
      )
    });
  }

  public static void assertNumberOfProducts(Integer expectedNumber) {
    List<Product2> products = new List<Product2>([SELECT Id FROM Product2]);
    system.assertEquals(products.size(), expectedNumber);
  }
}
