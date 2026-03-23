// 🛠️ UTILITIES - Optimized
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'dart:async'; // Added for Timer
import 'package:github_wallpaper/core/errors/app_exceptions.dart';
import 'package:github_wallpaper/core/theme/app_theme.dart';


part 'app_utils_error_handling.dart';
part 'app_utils_strings.dart';
part 'app_utils_constants.dart';
part 'app_utils_refresh.dart';
part 'app_utils_misc.dart';

final messengerKey = GlobalKey<ScaffoldMessengerState>();
