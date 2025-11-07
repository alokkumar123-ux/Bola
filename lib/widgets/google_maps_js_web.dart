// Web implementation that uses dart:js
import 'dart:js' as js;
import 'dart:js_util' as js_util;

// Re-export for use in main file
export 'dart:js' show JsObject, JsArray, context, allowInterop;

// Wrapper class for js_util
class JsUtil {
  static dynamic callMethod(dynamic o, String method, List<dynamic> args) {
    return js_util.callMethod(o, method, args);
  }

  static dynamic getProperty(dynamic o, String name) {
    return js_util.getProperty(o, name);
  }
}
