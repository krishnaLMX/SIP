import 'package:flutter/material.dart';

enum KycStatus { pending, submitted, verified, rejected }

class KycStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final KycStatus status;
  final String route;

  KycStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.route,
  });
}

