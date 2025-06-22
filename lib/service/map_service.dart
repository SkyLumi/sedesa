import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPicker extends StatelessWidget {
  final double? lat;
  final double? lng;
  final Function(double, double) onLocationPicked;

  const LocationPicker({
    super.key,
    this.lat,
    this.lng,
    required this.onLocationPicked,
  });

  void _openFullscreenMap(BuildContext context) async {
    LatLng? tempLatLng = lat != null && lng != null
        ? LatLng(lat!, lng!)
        : const LatLng(-8.169062, 113.718067);

    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        final mapController = MapController();
        final searchController = TextEditingController();
        ValueNotifier<LatLng> markerPosition = ValueNotifier<LatLng>(tempLatLng);

        Future<void> searchLocation(String query) async {
          final url = Uri.parse(
              'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
          final response = await http.get(url, headers: {
            'User-Agent': 'FlutterMapLocationPicker/1.0'
          });
          if (response.statusCode == 200) {
            final List data = json.decode(response.body);
            if (data.isNotEmpty) {
              final lat = double.parse(data[0]['lat']);
              final lon = double.parse(data[0]['lon']);
              final newLatLng = LatLng(lat, lon);
              markerPosition.value = newLatLng;
              mapController.move(newLatLng, 15.0);
            }
          }
        }

        return Dialog(
          insetPadding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Stack(
              children: [
                ValueListenableBuilder<LatLng>(
                  valueListenable: markerPosition,
                  builder: (context, value, child) {
                    return FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: value,
                        initialZoom: 15.0,
                        onTap: (tapPosition, point) {
                          markerPosition.value = point;
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 40.0,
                              height: 40.0,
                              point: value,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 60,
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            if (searchController.text.isNotEmpty) {
                              searchLocation(searchController.text);
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          searchLocation(value);
                        }
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Pilih Lokasi'),
                    onPressed: () {
                      Navigator.of(context).pop(markerPosition.value);
                    },
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      onLocationPicked(result.latitude, result.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pilih Lokasi yang Ingin diambil',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.fullscreen),
              tooltip: 'Buka Peta Layar Penuh',
              onPressed: () => _openFullscreenMap(context),
            ),
          ],
        ),
        SizedBox(
          height: 200,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat ?? -8.169062, lng ?? 113.718067),
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                onLocationPicked(point.latitude, point.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (lat != null && lng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: LatLng(lat!, lng!),
                      child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (lat != null && lng != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Lat: $lat, Lng: $lng'),
          ),
      ],
    );
  }
}