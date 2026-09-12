export 'local_file_writer_stub.dart'
    if (dart.library.io) 'local_file_writer_native.dart'
    if (dart.library.js_interop) 'local_file_writer_web.dart';
