// Stub for non-web platforms
class JsObject {
  JsObject(dynamic constructor, [List? arguments]);
  dynamic operator [](String property) => null;
  dynamic callMethod(String method, [List? arguments]) => null;
  static dynamic jsify(Map object) => null;
}

class JsArray {
  static List from(dynamic list) => [];
}

dynamic get context => null;
Function allowInterop(Function f) => f;

class JsUtil {
  static dynamic callMethod(dynamic o, String method, List args) => null;
  static dynamic getProperty(dynamic o, String name) => null;
}
