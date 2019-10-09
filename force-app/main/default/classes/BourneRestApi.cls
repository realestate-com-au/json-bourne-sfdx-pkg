@RestResource(urlMapping='/bourne/v1/*')
global class BourneRestApi {
  private final static Set<String> PERMITTED_OPERATIONS = new Set<String>{
    'UPSERT',
    'DELETE'
  };

  /* IMPORT METHOD
        The import of reference data requires the JSON Bourne SFDX plugin which can be found here: website.com
        The import is processed in a 4 step process
        1) Deserialize the payload from JSON to a collection of SObject records.
        2) Since we are using external Ids, we need to manually map these to Salesforce IDs.
           The buildOperationMap() method does this, passes the records back in an object that is seperated
           into MAPPED (found a Salesforce ID) and UNMAPPED (no Salesforce ID found in the external ID match).
        3) Instantiate a new responses collection and process the records (dynamic upserts using an external ID
           must be processed asynchronously due to the Apex limitations which doesn't suit this use case, so we
           are processing inserts and updates manually).
        4) Process the SaveResult/DeleteResult records and convert them into Responses to be passed back as the
           response for the overall import operation.
    */
  @HttpPost
  global static String import() {
    Plugins.PreProcessor preProcessor = Plugins.getInstancePreProcessor();
    Plugins.PostProcessor postProcessor = Plugins.getInstancePostProcessor();

    Map<String, Object> requestBody = extractBody(RestContext.request);

    String sObjectType = (String) requestBody.get('sObjectType');
    String operation = (String) requestBody.get('operation');
    String extIdField = (String) requestBody.get('extIdField');
    List<Object> payload = (List<Object>) requestBody.get('payload');
    String payloadString = JSON.serialize(payload);

    if (!PERMITTED_OPERATIONS.contains(operation.toUpperCase()))
      return throwGeneralException('This operation is not permitted');

    if (!objectContainsField(sObjectType, extIdField))
      return throwGeneralException(
        'The ' +
        sObjectType +
        ' object does not contain the field ' +
        extIdField
      );

    // 0.5) Pre Process Plugin
    preProcessor.execute();

    // 1) Deserialize payload
    List<SObject> records;
    try {
      records = (List<SObject>) JSON.deserialize(
        payloadString,
        Type.forName('List<' + sObjectType + '>')
      );
    } catch (Exception e) {
      return throwGeneralException(
        'The payload is not formatted correctly: ' + e.getMessage()
      );
    }

    // 2) Build an operational map
    Map<String, List<SObject>> operationMap = buildOperationMap(
      sObjectType,
      records,
      extIdField
    );

    // 3) & 4) Instantiate a new response collection, process and convert the results to responses
    List<Response> responses = new List<Response>();

    if (operation == 'UPSERT') {
      Database.SaveResult[] insertResults = Database.insert(
        operationMap.get('UNMAPPED'),
        false
      );
      responses.addAll(
        normaliseResponses(
          operationMap.get('UNMAPPED'),
          insertResults,
          extIdField
        )
      );

      Database.SaveResult[] updateResults = Database.update(
        operationMap.get('MAPPED'),
        false
      );
      responses.addAll(
        normaliseResponses(
          operationMap.get('MAPPED'),
          updateResults,
          extIdField
        )
      );
    } else if (operation == 'DELETE') {
      Database.DeleteResult[] deleteResults = Database.delete(
        operationMap.get('MAPPED'),
        false
      );
      responses.addAll(
        normaliseResponses(
          operationMap.get('MAPPED'),
          deleteResults,
          extIdField
        )
      );

      for (SObject record : operationMap.get('UNMAPPED')) {
        responses.add(
          new Response(
            (String) record.get(extIdField),
            'SUCCESS',
            'Record does not exist in target.'
          )
        );
      }
    }

    // 4.5) Post Process Plugin
    postProcessor.execute();

    return JSON.serialize(responses);
  }

  public static String throwGeneralException(String exceptionMessage) {
    Response r = new Response();
    r.result = 'FAILED';
    r.message = exceptionMessage;
    return JSON.serialize(r);
  }

  public static Map<String, Object> extractBody(RestRequest restRequest) {
    Blob bodyBlob = restRequest.requestBody;
    String requestString = bodyBlob.toString();
    return (Map<String, Object>) JSON.deserializeUntyped(requestString);
  }

  public static Map<String, List<SObject>> buildOperationMap(
    String sObjectType,
    List<SObject> records,
    String extIdField
  ) {
    Map<String, List<SObject>> operationMap = new Map<String, List<SObject>>{
      'MAPPED' => new List<SObject>(),
      'UNMAPPED' => new List<SObject>()
    };

    Map<String, SObject> externalIdMap = new Map<String, SObject>();
    for (
      SObject record : Database.query(
        'Select Id, ' +
        extIdField +
        ' From ' +
        sObjectType +
        ' WHERE ' +
        extIdField +
        ' != null'
      )
    )
      externalIdMap.put((String) record.get(extIdField), record);

    for (SObject record : records) {
      if (externalIdMap.containsKey((String) record.get(extIdField))) {
        record.put(
          'Id',
          (Id) externalIdMap.get((String) record.get(extIdField)).get('Id')
        );
        operationMap.get('MAPPED').add(record);
      } else {
        operationMap.get('UNMAPPED').add(record);
      }
    }

    return operationMap;
  }

  public static List<Response> normaliseResponses(
    List<Sobject> records,
    Database.SaveResult[] results,
    String extIdField
  ) {
    List<Response> responses = new List<Response>();
    for (Integer i = 0; i < results.size(); i++) {
      responses.add(new Response((SObject) records[i], results[i], extIdField));
    }
    return responses;
  }

  public static List<Response> normaliseResponses(
    List<Sobject> records,
    Database.DeleteResult[] results,
    String extIdField
  ) {
    List<Response> responses = new List<Response>();
    for (Integer i = 0; i < results.size(); i++) {
      responses.add(new Response((SObject) records[i], results[i], extIdField));
    }
    return responses;
  }

  public static Boolean objectContainsField(
    String objectName,
    String fieldName
  ) {
    SObjectType objToken = Schema.getGlobalDescribe().get(objectName);
    DescribeSObjectResult objDef = objToken.getDescribe();
    Map<String, SObjectField> fields = objDef.fields.getMap();

    Set<String> fieldSet = fields.keySet();
    return fieldSet.contains(fieldName.toLowerCase());
  }
}
