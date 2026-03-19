import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the Gyan Call bottom sheet is currently open.
/// AppShell watches this to hide the FABs when the sheet is open.
final gyanCallOpenProvider = StateProvider<bool>((ref) => false);
