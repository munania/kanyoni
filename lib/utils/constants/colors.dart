import 'package:flutter/widgets.dart';

class AppColor {
  // Private constructor which prevents the class from being instantiated
  AppColor._();

  static Color get primary => const Color(0xffC35BD1);
  static Color get focus => const Color(0xffD9519D);
  static Color get unfocused => const Color(0xff63666E);
  static Color get focusStart => const Color(0xffED8770);

  static Color get secondaryStart => primary;
  static Color get secondaryEnd => const Color(0xff657DDF);

  static Color get org => const Color(0xffE1914B);

  static Color get primaryText => const Color(0xffFFFFFF);
  static Color get primaryText80 => const Color(0xffFFFFFF).withOpacity(0.8);
  static Color get primaryText60 => const Color(0xffFFFFFF).withOpacity(0.6);
  static Color get primaryText35 => const Color(0xffFFFFFF).withOpacity(0.35);
  static Color get primaryText28 => const Color(0xffFFFFFF).withOpacity(0.28);
  static Color get secondaryText => const Color(0xff585A66);


  static List<Color> get primaryG => [ focusStart, focus ];
  static List<Color> get secondaryG => [secondaryStart, secondaryEnd];

  static Color get bg => const Color(0xff181B2C);
  static Color get darkGray => const Color(0xff383B49);
  static Color get lightGray => const Color(0xffD0D1D4);
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';

  // static const Color blackColor = Color.fromARGB(100, 56, 59, 73);
  // static const Color lighterBlackColor = Color.fromARGB(100, 88, 90, 102);
  // static const Color darkerWhite = Color.fromARGB(100, 206, 209, 212);
  // static const Color orangeColor = Color.fromARGB(100, 225, 145, 75);
  // static const Color backgroundColor = Color.fromARGB(100, 24, 27, 44);
  // static const Color paleRedColor = Color.fromARGB(100, 237, 135, 112);
  // static const Color pinkColor = Color.fromARGB(100, 217, 81, 157);
  // static const Color whiteColor = Color.fromARGB(100, 255, 255, 255);
  static const Gradient purpleBlueLinearGradient = LinearGradient(
      begin: Alignment(0.0, 0.0),
      end: Alignment(0.707, -0.707),
      colors: [
        Color.fromARGB(100, 195, 91, 209),
        Color.fromARGB(100, 101, 125, 223),
      ]);
  static const Gradient orangeRedLinearGradient = LinearGradient(
      begin: Alignment(0.0, 0.0),
      end: Alignment(0.707, -0.707),
      colors: [
        Color.fromARGB(100, 237, 135, 112),
        Color.fromARGB(100, 217, 81, 157),
      ]);
}
