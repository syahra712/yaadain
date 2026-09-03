import '../models/family_member.dart';

/// Toggle for previewing the UI with a sample family (no real data saved).
/// Only safe to enable together with kPreviewTree (which never persists).
/// MUST be false for real use.
const bool kUseDemoSeed = false;

/// A sample joint family spanning four generations, for previewing the tree.
/// Names only — no photos/audio — so avatars fall back to relationship emoji.
List<FamilyMember> demoFamily(String Function() newId) => [
      // Elders
      FamilyMember(id: newId(), name: 'عبد اللہ', romanName: 'Abdullah', relationshipId: 'walid'),
      // Peers
      FamilyMember(id: newId(), name: 'رقیہ', romanName: 'Ruqayya', relationshipId: 'biwi'),
      FamilyMember(id: newId(), name: 'اسلم', romanName: 'Aslam', relationshipId: 'bhai'),
      FamilyMember(id: newId(), name: 'نسیم', romanName: 'Naseem', relationshipId: 'behn'),
      // Children
      FamilyMember(id: newId(), name: 'بلال', romanName: 'Bilal', relationshipId: 'beta'),
      FamilyMember(id: newId(), name: 'فاطمہ', romanName: 'Fatima', relationshipId: 'beti'),
      FamilyMember(id: newId(), name: 'عائشہ', romanName: 'Ayesha', relationshipId: 'bahu'),
      // Grandchildren
      FamilyMember(id: newId(), name: 'زید', romanName: 'Zaid', relationshipId: 'pota'),
      FamilyMember(id: newId(), name: 'مریم', romanName: 'Maryam', relationshipId: 'poti'),
      FamilyMember(id: newId(), name: 'حسن', romanName: 'Hassan', relationshipId: 'nawasa'),
    ];
