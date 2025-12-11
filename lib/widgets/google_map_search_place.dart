import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:poolmate/constant/constant.dart';
import 'package:poolmate/constant/show_toast_dialog.dart';
import 'package:poolmate/model/map/place_picker_model.dart';
import 'package:poolmate/model/map/geometry.dart';
import 'package:poolmate/themes/app_them_data.dart';
import 'package:poolmate/themes/text_field_widget.dart';
import 'package:poolmate/utils/dark_theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

// Conditional imports - only load dart:js on web platform
import 'google_maps_js_web.dart'
    if (dart.library.io) 'google_maps_js_stub.dart';

class GoogleMapSearchPlacesApi extends StatefulWidget {
  const GoogleMapSearchPlacesApi({super.key});

  @override
  GoogleMapSearchPlacesApiState createState() =>
      GoogleMapSearchPlacesApiState();
}

class GoogleMapSearchPlacesApiState extends State<GoogleMapSearchPlacesApi> {
  final _controller = TextEditingController();
  var uuid = const Uuid();
  String? _sessionToken = '1234567890';
  List<dynamic> _placeList = [];
  bool _isGoogleMapsLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _onChanged();
    });

    // Check if Google Maps API is loaded (for web)
    if (kIsWeb) {
      _checkGoogleMapsLoaded();
    }
  }

  void _checkGoogleMapsLoaded() {
    // Check periodically if Google Maps is loaded
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (context['google'] != null &&
          context['google']['maps'] != null &&
          context['google']['maps']['places'] != null) {
        setState(() {
          _isGoogleMapsLoaded = true;
        });
        print('Google Maps API is ready!');
        return false; // Stop checking
      }
      return !_isGoogleMapsLoaded; // Continue checking
    });
  }

  _onChanged() {
    if (_sessionToken == null) {
      setState(() {
        _sessionToken = uuid.v4();
      });
    }
    getSuggestion(_controller.text);
  }

  void getSuggestion(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placeList = [];
      });
      return;
    }

    // On web, use Google Maps JavaScript API
    if (kIsWeb) {
      try {
        // Check if Google Maps API is loaded
        if (!_isGoogleMapsLoaded) {
          print('Google Maps API not loaded yet. Waiting...');
          setState(() {
            _placeList = [];
          });
          return;
        }

        // Call the JavaScript autocomplete service
        final service = JsObject(
          context['google']['maps']['places']['AutocompleteService'],
        );

        final request = JsObject.jsify({
          'input': input,
        });

        service.callMethod('getPlacePredictions', [
          request,
          allowInterop((predictions, status) {
            if (status == 'OK' && predictions != null) {
              final List<dynamic> predictionList = [];
              final jsArray = JsArray.from(predictions);

              for (var i = 0; i < jsArray.length; i++) {
                final prediction = jsArray[i];
                predictionList.add({
                  'description': prediction['description'],
                  'place_id': prediction['place_id'],
                });
              }

              setState(() {
                _placeList = predictionList;
              });
            } else {
              setState(() {
                _placeList = [];
              });
            }
          })
        ]);
      } catch (e) {
        print('Error getting web suggestions: $e');
        setState(() {
          _placeList = [];
        });
      }
      return;
    }

    // On mobile, use HTTP API
    try {
      String request =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=${Constant.mapAPIKey}';
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        setState(() {
          print(response.body);
          _placeList = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<PlaceDetailsModel?> getLatLang(String placeId) async {
    PlaceDetailsModel? placeDetailsModel;

    print('Getting place details for: $placeId');

    // On web, use Google Maps JavaScript API
    if (kIsWeb) {
      try {
        // Check if Google Maps API is loaded
        if (!_isGoogleMapsLoaded) {
          print('Google Maps API not loaded yet for place details');
          return null;
        }

        print('Creating PlacesService...');
        // Create a div element using JsUtil
        final div =
            JsUtil.callMethod(context['document'], 'createElement', ['div']);
        final service = JsObject(
          context['google']['maps']['places']['PlacesService'],
          [div],
        );

        final request = JsObject.jsify({
          'placeId': placeId,
          'fields': ['geometry', 'formatted_address', 'name'],
        });

        print('Requesting place details...');
        final completer = Completer<PlaceDetailsModel?>();

        service.callMethod('getDetails', [
          request,
          allowInterop((place, status) {
            print('Place details callback - Status: $status');
            if (status == 'OK' && place != null) {
              try {
                // Convert place to JsObject for proper property access
                final placeObj = place as JsObject;

                // Safely extract geometry and location
                final geometry = placeObj['geometry'];
                if (geometry == null) {
                  print('Geometry is null');
                  completer.complete(null);
                  return;
                }

                final geometryObj = geometry as JsObject;
                final location = geometryObj['location'];
                if (location == null) {
                  print('Location is null');
                  completer.complete(null);
                  return;
                }

                final locationObj = location as JsObject;

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
                final double latitude = (lat is num)
                    ? lat.toDouble()
                    : double.parse(lat.toString());
                final double longitude = (lng is num)
                    ? lng.toDouble()
                    : double.parse(lng.toString());

                final result = PlaceDetailsModel(
                  result: Result(
                    geometry: Geometry(
                      location: Location(
                        lat: latitude,
                        lng: longitude,
                      ),
                    ),
                    formattedAddress: formattedAddress,
                    name: name,
                  ),
                );

                print('Successfully created PlaceDetailsModel');
                completer.complete(result);
              } catch (e) {
                print('Error parsing place details: $e');
                print('Error stack trace: ${StackTrace.current}');
                completer.complete(null);
              }
            } else {
              print('Place details failed - Status: $status');
              completer.complete(null);
            }
          })
        ]);

        return await completer.future;
      } catch (e) {
        print('Error getting web place details: $e');
        print('Error stack trace: ${StackTrace.current}');
        return null;
      }
    }

    // On mobile, use HTTP API
    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/details/json';
      String request = '$baseURL?placeid=$placeId&key=${Constant.mapAPIKey}';
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        placeDetailsModel =
            PlaceDetailsModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      print('Error getting mobile place details: $e');
    }
    return placeDetailsModel;
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return Scaffold(
      backgroundColor:
          themeChange.getThem() ? AppThemeData.grey900 : AppThemeData.grey50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppThemeData.primary300,
        centerTitle: false,
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          child: Icon(
            Icons.arrow_back,
            color: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
          ),
        ),
        title: Text(
          'Search Place',
          style: TextStyle(
            color: themeChange.getThem()
                ? AppThemeData.grey900
                : AppThemeData.grey50,
            fontSize: 16,
            fontFamily: AppThemeData.medium,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextFieldWidget(
              hintText: 'Search your location here',
              controller: _controller,
              prefix: const Icon(Icons.map),
              suffix: IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  _controller.clear();
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _placeList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () async {
                      ShowToastDialog.showLoader("Please wait");
                      await getLatLang(_placeList[index]["place_id"])
                          .then((value) {
                        ShowToastDialog.closeLoader();
                        if (value != null) {
                          Get.back(result: value);
                        } else {
                          // Show error message if place details couldn't be fetched
                          ShowToastDialog.showToast(
                              "Unable to get location details. Please try again.");
                        }
                      });
                    },
                    child: ListTile(
                      title: Text(
                        _placeList[index]["description"],
                        style: TextStyle(
                          fontFamily: AppThemeData.regular,
                          color: themeChange.getThem()
                              ? AppThemeData.grey50
                              : AppThemeData.grey900,
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
