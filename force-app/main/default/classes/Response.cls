public class Response {
  private final static Set<String> PERMITTED_STATUSES = new Set<String>{
    'SUCCESS',
    'FAILED'
  };

  public String recordId;
  public String externalId;
  public String result {
    get;
    set {
      if (PERMITTED_STATUSES.contains(value.toUpperCase())) {
        result = value;
      } else {
        throw new GeneralException('Response result not permitted');
      }
    }
  }
  public String message;

  public Response() {
  }

  public Response(String eId, String res, String msg) {
    externalId = eId;
    result = res;
    message = msg;
  }

  public Response(String rId, String eId, String res, String msg) {
    recordId = rId;
    externalId = eId;
    result = res;
    message = msg;
  }

  public Response(
    SObject record,
    Database.SaveResult saveResult,
    String extIdField
  ) {
    if (saveResult.isSuccess()) {
      result = 'SUCCESS';
    } else {
      result = 'FAILED';
      Database.Error error = saveResult.getErrors().get(0);
      message = error.getMessage();
    }

    if (record.get(extIdField) != null)
      externalId = (String) record.get(extIdField);

    if (record.get('Id') != null)
      recordId = (String) record.get('Id');
  }

  public Response(
    SObject record,
    Database.DeleteResult deleteResult,
    String extIdField
  ) {
    if (deleteResult.isSuccess()) {
      result = 'SUCCESS';
    } else {
      result = 'FAILED';
      Database.Error error = deleteResult.getErrors().get(0);
      message = error.getMessage();
    }

    if (record.get(extIdField) != null)
      externalId = (String) record.get(extIdField);

    if (record.get('Id') != null)
      recordId = (String) record.get('Id');
  }

  private class GeneralException extends Exception {
  }
}
