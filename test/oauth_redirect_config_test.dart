import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest contains the AppAuth redirect receiver', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
        manifest, contains('net.openid.appauth.RedirectUriReceiverActivity'));
    expect(manifest, contains('android:scheme="gitwall"'));
    expect(manifest, contains('android:host="oauth"'));
    expect(manifest, contains('android:path="/callback"'));
  });

  test('iOS Info.plist uses the gitwall callback scheme', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('<string>gitwall</string>'));
    expect(
        infoPlist, isNot(contains('com.rahulreddy.githubwallpaper</string>')));
  });

  test('iOS project bundle identifier is aligned to production id', () {
    final projectFile =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(
        projectFile,
        contains(
            'PRODUCT_BUNDLE_IDENTIFIER = com.rahulreddy.githubwallpaper;'));
    expect(
        projectFile,
        isNot(contains(
            'PRODUCT_BUNDLE_IDENTIFIER = com.example.githubWallpaper;')));
  });
}
