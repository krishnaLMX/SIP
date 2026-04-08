import 'dart:io';

void main() async {
  final dir = Directory('lib');
  int count = 0;
  await for (FileSystemEntity entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        if (content.contains('â‚¹')) {
          final updatedContent = content.replaceAll('â‚¹', '₹');
          await entity.writeAsString(updatedContent);
          print('Fixed ${entity.path}');
          count++;
        }
      } catch (e) {
        // print('Skipped ${entity.path}');
      }
    }
  }
  print('Total files fixed: $count');
}
