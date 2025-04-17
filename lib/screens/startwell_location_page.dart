import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startwell/themes/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class StartwellLocationPage extends StatefulWidget {
  const StartwellLocationPage({Key? key}) : super(key: key);

  @override
  State<StartwellLocationPage> createState() => _StartwellLocationPageState();
}

class _StartwellLocationPageState extends State<StartwellLocationPage> {
  late GoogleMapController _controller;
  MapType _mapType = MapType.normal;

  static const LatLng _startwellLatLng = LatLng(19.090167, 73.004089);
  static const String _startwellAddress =
      "Shop Number 14, Ground Floor, A2 Wing, Gami Industrial Park, Pawne, Navi Mumbai Municipal Corporation, Maharashtra 400705";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Startwell Location",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        backgroundColor: AppTheme.purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _startwellLatLng,
              zoom: 16,
            ),
            mapType: _mapType,
            markers: {
              const Marker(
                markerId: MarkerId("startwell"),
                position: _startwellLatLng,
                infoWindow: InfoWindow(
                  title: "Startwell HQ",
                  snippet: "Gami Industrial Park, Pawne, Navi Mumbai",
                ),
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Map Type Toggle Button
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "mapToggle",
              onPressed: () {
                setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                });
              },
              backgroundColor: AppTheme.purple,
              mini: true,
              child: const Icon(
                Icons.layers,
                color: AppTheme.white,
              ),
            ),
          ),

          // Address Card at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Startwell HQ",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _startwellAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openGoogleMapsDirections,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.directions,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Get Directions",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoogleMapsDirections() async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=19.090167,73.004089&destination_place_id=Startwell&travelmode=driving');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps'),
          ),
        );
      }
    }
  }
}
