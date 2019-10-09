global class MigrationIdService {
  global class MigrationIdServiceException extends Exception {
  }

  global static void addMigrationId(sObject[] records, String migrationField) {
    if (records == null || records.size() == 0)
      throw new MigrationIdServiceException('No records specified.');
    if (migrationField == '' || migrationField == null)
      throw new MigrationIdServiceException(
        'Migration Field parameter is required.'
      );

    Integer sequence = 0;
    for (sObject rec : records) {
      if (
        rec.get(migrationField) == null ||
        rec.get(migrationField) == '' ||
        rec.isClone()
      ) {
        rec.put(migrationField, externalIdFactory(sequence));
      }
      sequence++;
    }
  }

  private static String externalIdFactory(Integer sequence) {
    return 'REC' +
      generateRandomString(7) +
      String.valueOf(Math.roundToLong(Math.random() * 1000000)) +
      String.valueOf(sequence);
  }

  private static String generateRandomString(Integer len) {
    final String AVAILABLE_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
      Integer idx = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        AVAILABLE_CHARACTERS.length()
      );
      randStr += AVAILABLE_CHARACTERS.substring(idx, idx + 1);
    }
    return randStr;
  }
}
