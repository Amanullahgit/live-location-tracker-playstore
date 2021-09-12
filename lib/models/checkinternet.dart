import 'dart:io';

class InternetStatus {
  Future<bool> get checkInternet async {
    try {
      final result = await InternetAddress.lookup('google.com');
      print(result);
      print(result[0].rawAddress);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      print('not connected');
      return false;
    }
  }
}
