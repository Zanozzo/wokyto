// login_view.dart

import 'package:flutter/material.dart';

import 'package:wokytoky/l10n/l10n.dart';
import 'package:wokytoky/widgets/layouts/login_scaffold.dart';
import 'package:wokytoky/widgets/matrix.dart';
import 'login.dart';

class LoginView extends StatelessWidget {
  final LoginController controller;

  const LoginView(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final homeserver = controller.widget.client.homeserver
        .toString()
        .replaceFirst('https://', '');
    final title = L10n.of(context).logInTo(homeserver);
    final titleParts = title.split(homeserver);

    return LoginScaffold(
      enforceMobileMode:
          Matrix.of(context).widget.clients.any((client) => client.isLogged()),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 0,
      ),
      body: Builder(
        builder: (context) {
          return AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: <Widget>[
                Hero(
                  tag: 'info-logo',
                  child: Image.asset('assets/banner_transparent.png'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    readOnly: controller.loading,
                    autocorrect: false,
                    autofocus: true,
                    onChanged: controller.checkWellKnownWithCoolDown,
                    controller: controller.usernameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints:
                        controller.loading ? null : [AutofillHints.username],
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.account_box_outlined),
                      errorText: controller.usernameError,
                      errorStyle: const TextStyle(color: Colors.orange),
                      hintText: '@username:domain',
                      labelText: L10n.of(context).emailOrUsername,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextField(
                    readOnly: controller.loading,
                    autocorrect: false,
                    autofillHints:
                        controller.loading ? null : [AutofillHints.password],
                    controller: controller.passwordController,
                    textInputAction: TextInputAction.go,
                    obscureText: !controller.showPassword,
                    onSubmitted: (_) => controller.login(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outlined),
                      errorText: controller.passwordError,
                      errorStyle: const TextStyle(color: Colors.orange),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleShowPassword,
                        icon: Icon(
                          controller.showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black,
                        ),
                      ),
                      hintText: '******',
                      labelText: L10n.of(context).password,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7ED6D2),
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: controller.loading ? null : controller.login,
                    child: controller.loading
                        ? const LinearProgressIndicator()
                        : Text(L10n.of(context).login),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: OutlinedButton(
                    onPressed: controller.loading ? null : controller.register,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text('Create new account'),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: TextButton(
                    onPressed: controller.loading
                        ? () {}
                        : controller.passwordForgotten,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: Text(L10n.of(context).passwordForgotten),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
