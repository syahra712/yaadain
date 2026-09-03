import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/family_member.dart';
import '../../models/memory_story.dart';
import '../../models/relationship.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/voice_recorder.dart';

/// Add / edit one relative: name, relationship (from elder's POV), photo,
/// their spoken greeting, phone, and reminiscence stories with flashback
/// triggers. Media is captured to temp paths and imported to permanent
/// storage on save.
class EditMemberScreen extends StatefulWidget {
  final String? memberId;
  const EditMemberScreen({super.key, this.memberId});

  @override
  State<EditMemberScreen> createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _picker = ImagePicker();
  late FamilyMember _draft;
  bool get _isNew => widget.memberId == null;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AppState>().repo;
    final existing = widget.memberId == null ? null : repo.memberById(widget.memberId!);
    _draft = existing == null
        ? FamilyMember(id: repo.newId(), name: '', relationshipId: 'beti')
        : FamilyMember.fromJson(existing.toJson()); // deep-ish copy
  }

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 55);
    if (x != null) setState(() => _draft.photoPath = x.path);
  }

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 55);
    if (x != null) setState(() => _draft.photoPath = x.path);
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    final repo = app.repo;
    _draft.photoPath = await repo.ensureStored(_draft.photoPath);
    _draft.greetingAudioPath = await repo.ensureStored(_draft.greetingAudioPath);
    for (final st in _draft.stories) {
      st.audioPath = await repo.ensureStored(st.audioPath);
      st.photoPath = await repo.ensureStored(st.photoPath);
    }
    await app.upsertMember(_draft);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove relative?'),
        content: Text('Remove ${_draft.name} from Yaadain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AppState>().removeMember(_draft.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _draft.photoPath != null && File(_draft.photoPath!).existsSync();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add relative' : 'Edit relative'),
        actions: [
          if (!_isNew)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.black12,
                backgroundImage: hasPhoto ? FileImage(File(_draft.photoPath!)) : null,
                child: hasPhoto ? null : const Icon(Icons.add_a_photo, size: 34),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(onPressed: _takePhoto, icon: const Icon(Icons.camera_alt), label: const Text('Camera')),
                TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo), label: const Text('Gallery')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _field(
            label: 'Name (as the elder knows them)',
            initial: _draft.name,
            onChanged: (v) => _draft.name = v,
          ),
          _field(
            label: 'Roman-Urdu name (optional)',
            initial: _draft.romanName ?? '',
            onChanged: (v) => _draft.romanName = v.isEmpty ? null : v,
          ),
          const SizedBox(height: 8),
          _RelationshipPicker(
            value: _draft.relationshipId,
            onChanged: (v) => setState(() => _draft.relationshipId = v),
          ),
          const SizedBox(height: 8),
          _field(
            label: 'Phone',
            helper: 'For the "if found" card & alerts',
            initial: _draft.phone ?? '',
            keyboard: TextInputType.phone,
            onChanged: (v) => _draft.phone = v.isEmpty ? null : v,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('In memoriam (passed away)'),
            subtitle: const Text('Handled gently — the elder is never told bluntly'),
            value: _draft.isDeceased,
            onChanged: (v) => setState(() => _draft.isDeceased = v),
          ),
          const SizedBox(height: 8),
          const Text('Their greeting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('e.g. “Assalam-o-alaikum Abba, main aapki beti Fatima hoon”',
              style: TextStyle(color: YaadainTheme.muted)),
          const SizedBox(height: 8),
          VoiceRecorder(
            initialPath: _draft.greetingAudioPath,
            hint: 'Record this relative saying who they are to the elder.',
            onRecorded: (p) => _draft.greetingAudioPath = p,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Memories & flashbacks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => setState(() => _draft.stories.add(
                      MemoryStory(id: DateTime.now().microsecondsSinceEpoch.toString(), title: ''),
                    )),
                icon: const Icon(Icons.add),
                label: const Text('Add memory'),
              ),
            ],
          ),
          ..._draft.stories.map((st) => _StoryEditor(
                key: ValueKey(st.id),
                story: st,
                onRemove: () => setState(() => _draft.stories.remove(st)),
              )),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    TextInputType? keyboard,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        initialValue: initial,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _RelationshipPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _RelationshipPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Relationship to the elder',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: kRelationships
              .map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text('${r.emoji}  ${r.roman} — ${r.english}'),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _StoryEditor extends StatelessWidget {
  final MemoryStory story;
  final VoidCallback onRemove;
  const _StoryEditor({super.key, required this.story, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: story.title,
                    decoration: const InputDecoration(
                      labelText: 'Memory title (e.g. “Eid in the village”)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => story.title = v,
                  ),
                ),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: story.triggers.join('، '),
              decoration: const InputDecoration(
                labelText: 'Flashback triggers (comma-separated)',
                helperText: 'Words that bring this memory up: names, places, “Eid”, “shaadi”…',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => story.triggers = v
                  .split(RegExp(r'[,،]'))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
            const SizedBox(height: 10),
            VoiceRecorder(
              initialPath: story.audioPath,
              hint: 'Record the family member telling this story.',
              onRecorded: (p) => story.audioPath = p,
            ),
          ],
        ),
      ),
    );
  }
}
