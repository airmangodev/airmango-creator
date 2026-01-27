import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool> handlePermissionDenied(BuildContext context, String permissionName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$permissionName Permission Required"),
        content: Text("Airmango needs $permissionName access to help you capture and organize your journey memories. Please enable it in settings."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Not Now")),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context, true);
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    ) ?? false;
  }
}
