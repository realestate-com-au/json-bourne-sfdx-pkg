global class Plugins {
  // Pre Processor
  public static Plugins.PreProcessor getInstancePreProcessor() {
    Object result = getInstance('API_Pre_Processor__c');
    return (Plugins.PreProcessor) (result == null
      ? new DefaultPreProcessor()
      : result);
  }

  global interface PreProcessor {
    void execute();
  }

  global class DefaultPreProcessor implements defaultInterface, PreProcessor {
    global void execute() {
    }
  }

  // Post Processor
  public static Plugins.PostProcessor getInstancePostProcessor() {
    Object result = getInstance('API_Post_Processor__c');
    return (Plugins.PostProcessor) (result == null
      ? new DefaultPostProcessor()
      : result);
  }

  global interface PostProcessor {
    void execute();
  }

  global class DefaultPostProcessor implements defaultInterface, PostProcessor {
    global void execute() {
    }
  }

  // Marker Interface
  public interface defaultInterface {
  }

  // Exception class
  class PluginException extends Exception {
  }

  // Method to instantiate class from custom setting field
  static Object getInstance(String pluginField) {
    BournePlugins__c pluginSettings = BournePlugins__c.getInstance();
    if (pluginSettings == null || pluginSettings.get(pluginField) == null)
      return null;

    Type t = Type.forName(null, (String) pluginSettings.get(pluginField));
    if (t == null)
      throw new PluginException(
        'No class called ' +
        pluginSettings.get(pluginField) +
        'found.'
      );
    return t.newInstance();
  }
}
