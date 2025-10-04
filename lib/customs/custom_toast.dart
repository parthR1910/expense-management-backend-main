import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  static void showToast(String message,
      {Color backgroundColor = Colors.black, Color textColor = Colors.white}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor, // this will show correctly now
      textColor: textColor,
      fontSize: 16.0,
    );
  }
}
