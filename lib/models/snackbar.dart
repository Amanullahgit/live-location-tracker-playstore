import 'package:flutter/material.dart';

class ShowSnack {
  final String msg;
  ShowSnack(this.msg);
  SnackBar get snackBar {
    return SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.fixed,
      backgroundColor: Colors.black45,
      padding: EdgeInsets.only(left: 10),
    );
  }
}
