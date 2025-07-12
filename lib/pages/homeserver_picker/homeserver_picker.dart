import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ignore: unused_import
import 'package:collection/collection.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher_string.dart';

import 'package:wokytoky/config/app_config.dart';
import 'package:wokytoky/l10n/l10n.dart';
import 'package:wokytoky/utils/file_selector.dart';
import 'package:wokytoky/utils/platform_infos.dart';
import 'package:wokytoky/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:wokytoky/widgets/matrix.dart';
import '../../utils/localized_exception_extension.dart';

import 'package:wokytoky/utils/tor_stub.dart'
    if (dart.library.html) 'package:tor_detector_web/tor_detector_web.dart';

class HomeserverPicker extends StatefulWidget {
  final bool addMultiAccount;
  const HomeserverPicker({required this.addMultiAccount, super.key});

  @override
  HomeserverPickerController createState() => HomeserverPickerController();
}

class HomeserverPickerController extends State<HomeserverPicker> {
  bool isLoading = false;
  String? error;
  bool isTorBrowser = false;
  List<LoginFlow>? loginFlows;

  @override
  void initState() {
    super.initState();
    _checkTorBrowser();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLoginToWoky();
    });
  }

  Future<void> _checkTorBrowser() async {
    if (!kIsWeb) return;

    Hive.openBox('test').then((value) => null).catchError((e, s) async {
      await showOkAlertDialog(
        context: context,
        title: L10n.of(context).indexedDbErrorTitle,
        message: L10n.of(context).indexedDbErrorLong,
      );
      _checkTorBrowser();
    });

    final isTor = await TorBrowserDetector.isTorBrowser;
    isTorBrowser = isTor;
  }

  Future<void> _autoLoginToWoky() async {
    setState(() {
      error = null;
      isLoading = true;
    });

    final l10n = L10n.of(context);
    final homeserver = Uri.https('woky.to', '');

    try {
      final client = await Matrix.of(context).getLoginClient();
      final (_, _, loginFlows) = await client.checkHomeserver(homeserver);
      this.loginFlows = loginFlows;
      client.homeserver = homeserver;

      if (_supportsFlow('m.login.sso')) {
        if (!PlatformInfos.isMobile) {
          final consent = await showOkCancelAlertDialog(
            context: context,
            title: l10n.appWantsToUseForLogin('woky.to'),
            message: l10n.appWantsToUseForLoginDescription,
            okLabel: l10n.continueText,
          );
          if (consent != OkCancelResult.ok) return;
        }
        return _ssoLogin(client);
      }

      context.go('/home/login', extra: client);
    } catch (e) {
      setState(() {
        error = (e).toLocalizedString(
          context,
          ExceptionContext.checkHomeserver,
        );
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _supportsFlow(String flowType) =>
      loginFlows?.any((flow) => flow.type == flowType) ?? false;

  Future<void> _ssoLogin(Client client) async {
    final redirectUrl = kIsWeb
        ? Uri.parse(html.window.location.href)
            .resolveUri(Uri(pathSegments: ['auth.html']))
            .toString()
        : PlatformInfos.isMobile || PlatformInfos.isWeb || PlatformInfos.isMacOS
            ? '${AppConfig.appOpenUrlScheme.toLowerCase()}://login'
            : 'http://localhost:3001//login';

    final url = client.homeserver!.replace(
      path: '/_matrix/client/v3/login/sso/redirect',
      queryParameters: {'redirectUrl': redirectUrl},
    );

    final urlScheme = Uri.parse(redirectUrl).scheme;
    final result = await FlutterWebAuth2.authenticate(
      url: url.toString(),
      callbackUrlScheme: urlScheme,
      options: const FlutterWebAuth2Options(),
    );

    final token = Uri.parse(result).queryParameters['loginToken'];
    if (token?.isEmpty ?? true) return;

    setState(() {
      error = null;
      isLoading = true;
    });

    try {
      await client.login(
        LoginType.mLoginToken,
        token: token,
        initialDeviceDisplayName: PlatformInfos.clientName,
      );
    } catch (e) {
      setState(() {
        error = e.toLocalizedString(context);
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
