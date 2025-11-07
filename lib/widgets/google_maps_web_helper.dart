// This file contains web-specific Google Maps JavaScript API implementations
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

// Only import dart:js on web
import 'dart:js' as js if (dart.library.io) '';
import 'dart:js_util' as js_util if (dart.library.io) '';

class GoogleMapsWebHelper {
  static bool checkIfGoogleMapsLoaded() {
    if (!kIsWeb) return false;

    try {
      return js.context['google'] != null &&
          js.context['google']['maps'] != null &&
          js.context['google']['maps']['places'] != null;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPlacePredictions(
      String input) async {
    if (!kIsWeb) return [];

    try {
      final completer = Completer<List<Map<String, dynamic>>>();

      final service = js.JsObject(
        js.context['google']['maps']['places']['AutocompleteService'],
      );

      final request = js.JsObject.jsify({
        'input': input,
      });

      service.callMethod('getPlacePredictions', [
        request,
        js.allowInterop((predictions, status) {
          if (status == 'OK' && predictions != null) {
            final List<Map<String, dynamic>> predictionList = [];
            final jsArray = js.JsArray.from(predictions);

            for (var i = 0; i < jsArray.length; i++) {
              final prediction = jsArray[i];
              predictionList.add({
                'description': prediction['description'],
                'place_id': prediction['place_id'],
              });
            }
            completer.complete(predictionList);
          } else {
            completer.complete([]);
          }
        })
      ]);

      return completer.future;
    } catch (e) {
      print('Error getting web place predictions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!kIsWeb) return null;

    try {
      final div =
          js_util.callMethod(js.context['document'], 'createElement', ['div']);
      final service = js.JsObject(
        js.context['google']['maps']['places']['PlacesService'],
        [div],
      );

      final request = js.JsObject.jsify({
        'placeId': placeId,
        'fields': ['geometry', 'formatted_address', 'name'],
      });

      final completer = Completer<Map<String, dynamic>?>();

      service.callMethod('getDetails', [
        request,
        js.allowInterop((place, status) {
          print('Place details callback - Status: $status');
          if (status == 'OK' && place != null) {
            try {
              // Convert place to JsObject for proper property access
              final placeObj = place as js.JsObject;

              // Safely extract geometry and location
              final geometry = placeObj['geometry'];
              if (geometry == null) {
                print('Geometry is null');
                completer.complete(null);
                return;
              }

              final geometryObj = geometry as js.JsObject;
              final location = geometryObj['location'];
              if (location == null) {
                print('Location is null');
                completer.complete(null);
                return;
              }

              final locationObj = location as js.JsObject;

              // Call lat() and lng() methods on the location object
              final lat = locationObj.callMethod('lat', []);
              final lng = locationObj.callMethod('lng', []);

              if (lat == null || lng == null) {
                print('Latitude or Longitude is null');
                completer.complete(null);
                return;
              }

              print('Got coordinates: $lat, $lng');

              // Safely get formatted address and name
              String formattedAddress = '';
              String name = '';

              try {
                final addressProp = placeObj['formatted_address'];
                if (addressProp != null) {
                  formattedAddress = addressProp.toString();
                }
              } catch (e) {
                print('formatted_address is null or missing: $e');
              }

              try {
                final nameProp = placeObj['name'];
                if (nameProp != null) {
                  name = nameProp.toString();
                }
              } catch (e) {
                print('name is null or missing: $e');
              }

              // Convert lat/lng to double
              final double latitude =
                  (lat is num) ? lat.toDouble() : double.parse(lat.toString());
              final double longitude =
                  (lng is num) ? lng.toDouble() : double.parse(lng.toString());

              completer.complete({
                'lat': latitude,
                'lng': longitude,
                'formatted_address': formattedAddress,
                'name': name,
              });
            } catch (e) {
              print('Error parsing place details: $e');
              completer.complete(null);
            }
          } else {
            print('Place details failed - Status: $status');
            completer.complete(null);
          }
        })
      ]);

      return completer.future;
    } catch (e) {
      print('Error getting web place details: $e');
      return null;
    }
  }
}
