import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/relationship.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

/// A printable "if found" card. The QR encodes the contact info AS PLAIN TEXT
/// inside itself, so a stranger who finds the elder can scan it with any phone
/// camera and see who to call — with no app, no account, and no internet.
/// Nothing about the elder is stored on any server.
class IfFoundCardScreen extends StatelessWidget {
  const IfFoundCardScreen({super.key});

  String _buildPayload(AppState app) {
    final elder = app.elder;
    final contacts = app.repo.emergencyContacts();
    final b = StringBuffer();
    b.writeln('I have memory loss. Please help me get home.');
    b.writeln('مجھے یادداشت کی بیماری ہے۔ براہِ کرم میری مدد کریں۔');
    if (elder.name.isNotEmpty || (elder.romanName ?? '').isNotEmpty) {
      b.writeln('Name: ${elder.romanName ?? elder.name}');
    }
    if ((elder.homeAddress ?? '').trim().isNotEmpty) {
      b.writeln('Lives at: ${elder.homeAddress!.trim()}');
    }
    if (elder.hasSafeZone) {
      b.writeln('Home location: https://maps.google.com/?q=${elder.homeLat},${elder.homeLng}');
    }
    if (contacts.isNotEmpty) {
      b.writeln('If found, please call:');
      for (final c in contacts) {
        final rel = relationshipById(c.relationshipId);
        final who = rel?.english ?? 'family';
        b.writeln('- ${c.romanName ?? c.name} ($who): ${c.phone}');
      }
    }
    return b.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final contacts = app.repo.emergencyContacts();
    final payload = _buildPayload(app);

    return Scaffold(
      appBar: AppBar(title: const Text('“If found” card')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (contacts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Add at least one relative with a phone number to generate the card.',
                  style: TextStyle(color: YaadainTheme.muted),
                ),
              ),
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('یادیں · Yaadain',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('If you find me, please scan',
                        style: TextStyle(color: YaadainTheme.muted)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: QrImageView(
                        data: payload,
                        version: QrVersions.auto,
                        size: 220,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (app.elder.name.isNotEmpty)
                      Text(app.elder.romanName ?? app.elder.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('I have memory loss — please help me get home.',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('What the QR contains',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(payload, style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Print this and keep it in the elder’s wallet or on a bracelet. It works '
              'offline: any phone camera reads it. No data leaves the device.',
              style: TextStyle(color: YaadainTheme.muted),
            ),
          ],
        ],
      ),
    );
  }
}
