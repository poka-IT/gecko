// import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:logger/logger.dart';

// --- THIS IS WIP ---

class GeckoStyles {
  TextStyle successBold(List<String> pars) {
    return TextStyle(
      color: Colors.green.shade600,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle success() {
    return TextStyle(color: Colors.green.shade600);
  }

  TextStyle error500(List<String> pars) {
    return const TextStyle(
      fontSize: 20,
      color: Colors.redAccent,
      fontWeight: FontWeight.w500,
    );
  }

  TextStyle error() {
    return const TextStyle(fontSize: 20, color: Colors.redAccent);
  }

  TextStyle builder(Map<String, dynamic> pars) {
    // pars["hola"] = 20;
    // //int a = double.tryParse(source) pars["hola"];
    // return const TextStyle( fontSize: double.tryParse(pars["hola"]),
    //                         color: Colors.redAccent,
    //                         fontWeight: FontWeight.w500
    //                       );
    return const TextStyle();
  }
}
