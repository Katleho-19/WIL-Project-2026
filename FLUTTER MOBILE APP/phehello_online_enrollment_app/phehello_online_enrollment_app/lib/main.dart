import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tpamgrvjwbinuqnsursl.supabase.co',
    publishableKey: 'sb_publishable_tIF0J4EJyD8YbSf0aiUDvQ_hBthlEtS',
  );
  runApp(const PhehelloApp());
}
