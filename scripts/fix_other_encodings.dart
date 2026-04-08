import 'dart:io';

void main() async {
  final file = File('lib/features/settings/settings_screen.dart');
  var content = await file.readAsString();

  content = content.replaceAll('à®¤à®®à®¿à®´à¯  (Tamil)', 'தமிழ் (Tamil)');
  content = content.replaceAll('à°¤à±†à°²à± à°—à±  (Telugu)', 'తెలుగు (Telugu)');
  content = content.replaceAll('English / à®¤à®®à®¿à®´à¯  / à°¤à±†à°²à± à°—à± ', 'English / தமிழ் / తెలుగు');

  await file.writeAsString(content);
  print('Fixed settings_screen.dart');
}
