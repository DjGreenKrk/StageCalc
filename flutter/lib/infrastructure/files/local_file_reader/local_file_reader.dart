export 'local_file_reader_stub.dart'
    if (dart.library.io) 'local_file_reader_native.dart'
    if (dart.library.js_interop) 'local_file_reader_web.dart';
