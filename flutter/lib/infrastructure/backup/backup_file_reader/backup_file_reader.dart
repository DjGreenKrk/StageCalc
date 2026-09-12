export 'backup_file_reader_stub.dart'
    if (dart.library.io) 'backup_file_reader_native.dart'
    if (dart.library.js_interop) 'backup_file_reader_web.dart';
