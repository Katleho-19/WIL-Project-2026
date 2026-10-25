//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: main.dart is the entry point of the Flutter parent app. It runs first when the app
// starts, connects the app to the Supabase backend and then launches the root widget (PhehelloApp).

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

/// main() - the function Flutter calls when the app starts.
/// 1. Makes sure Flutter's engine is ready (needed before any async/platform work).
/// 2. Initialises the Supabase client with the project URL and the public (publishable) key,
///    waiting until it is ready so that login and database calls work from the first screen.
/// 3. Starts the app by running PhehelloApp as the root widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tpamgrvjwbinuqnsursl.supabase.co',
    publishableKey: 'sb_publishable_tIF0J4EJyD8YbSf0aiUDvQ_hBthlEtS',
  );
  runApp(const PhehelloApp());
}
