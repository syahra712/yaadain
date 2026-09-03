import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';

/// Set the elder's name, photo, and preferred script. Kept minimal.
class ElderProfileScreen extends StatefulWidget {
  const ElderProfileScreen({super.key});

  @override
  State<ElderProfileScreen> createState() => _ElderProfileScreenState();
}

class _ElderProfileScreenState extends State<ElderProfileScreen> {
  final _picker = ImagePicker();

  Future<void> _pickPhoto(ImageSource src) async {
    final app = context.read<AppState>();
    final x = await _picker.pickImage(source: src, maxWidth: 800, imageQuality: 55);
    if (x == null) return;
    final stored = await app.repo.ensureStored(x.path);
    app.elder.photoPath = stored;
    await app.saveElder();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final elder = app.elder;
    final hasPhoto = elder.photoPath != null && File(elder.photoPath!).existsSync();

    return Scaffold(
      appBar: AppBar(title: const Text('The elder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _pickPhoto(ImageSource.gallery),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.black12,
                backgroundImage: hasPhoto ? FileImage(File(elder.photoPath!)) : null,
                child: hasPhoto ? null : const Icon(Icons.add_a_photo, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(spacing: 8, children: [
              TextButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera')),
              TextButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery')),
            ]),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: elder.name,
            decoration: const InputDecoration(labelText: 'Name (Urdu)', border: OutlineInputBorder()),
            onChanged: (v) => elder.name = v,
            onEditingComplete: () => context.read<AppState>().saveElder(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: elder.romanName ?? '',
            decoration: const InputDecoration(labelText: 'Name (Roman-Urdu)', border: OutlineInputBorder()),
            onChanged: (v) => elder.romanName = v.isEmpty ? null : v,
            onEditingComplete: () => context.read<AppState>().saveElder(),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show elder screens in Roman-Urdu'),
            subtitle: const Text('Otherwise Urdu script (اردو), right-to-left'),
            value: elder.preferRomanScript,
            onChanged: (_) => context.read<AppState>().toggleScript(),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              await context.read<AppState>().saveElder();
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Saved')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: YaadainTheme.primary),
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
