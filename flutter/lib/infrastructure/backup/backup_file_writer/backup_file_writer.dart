export 'backup_file_writer_stub.dart'
    if (dart.library.io) 'backup_file_writer_native.dart'
    if (dart.library.js_interop) 'backup_file_writer_web.dart';
