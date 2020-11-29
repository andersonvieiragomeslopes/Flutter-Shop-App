import 'package:flutter/material.dart';

import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../widgets/rounded_button.dart';
import '../../size_config.dart';
import '../../constants.dart';
import '../../routes_handler.dart';
import '../../providers/auth.dart';

class AuthScreen extends StatelessWidget {
  final bool isRegistering;
  const AuthScreen(this.isRegistering);

  void goBackToWelcomeScreen(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(welcomeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        goBackToWelcomeScreen(context);
        return true;
      },
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.arrow_back),
          onPressed: () => goBackToWelcomeScreen(context),
        ),
        body: Container(
          height: SizeConfig.screenHeight + 24,
          width: SizeConfig.screenWidth,
          child: Stack(
            children: [
              BackgroundAnimation(),
              Positioned(
                top: SizeConfig.getHeightPercentage(10),
                left: 10,
                right: 10,
                child: Column(
                  children: [
                    Text(
                      isRegistering ? welcomeOnBoardText : welcomeBackText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: SizeConfig.getHeightPercentage(15)),
                    AuthForm(isRegistering, context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundAnimation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.screenHeight + 24,
      width: SizeConfig.screenWidth,
      child: Lottie.asset(
        'assets/animations/floating-in-balloons.json',
        fit: BoxFit.cover,
      ),
    );
  }
}

class AuthForm extends StatefulWidget {
  final bool isRegistering;
  final BuildContext pageContext;
  AuthForm(this.isRegistering, this.pageContext);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  String email, password, confirmPassword;

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final isFormValid = _formKey.currentState.validate();
    final authProvider = Provider.of<Auth>(context, listen: false);

    if (!isFormValid) return;

    try {
      if (widget.isRegistering) {
        await authProvider.signUp(email, password);
      } else {
        await authProvider.signIn(email, password);
      }

      Navigator.of(context).pushReplacementNamed(homeRoute);
    } catch (error) {
      // TODO: implement proper error handling
      print(error);
    }
  }

  String validatePassword(String password) {
    if (password.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    } else {
      return null;
    }
  }

  String validateEmail(String email) {
    if (!email.contains('@')) {
      return 'Você precisa fornecer um email válido.';
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.screenHeight,
      width: SizeConfig.screenWidth,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              generateFormField(
                text: widget.isRegistering
                    ? 'Digite seu melhor email'
                    : 'Digite seu email',
                validator: validateEmail,
                onFieldSubmitted: (value) {
                  email = value;
                  _passwordFocusNode.requestFocus();
                },
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 15),
              generateFormField(
                text: widget.isRegistering
                    ? 'Crie uma senha segura'
                    : 'Digite sua senha',
                validator: validatePassword,
                onFieldSubmitted: (value) {
                  password = value;

                  if (widget.isRegistering) {
                    _confirmPasswordFocusNode.requestFocus();
                  } else {
                    _submitForm();
                  }
                },
                textInputAction: widget.isRegistering
                    ? TextInputAction.next
                    : TextInputAction.done,
                focusNode: _passwordFocusNode,
                obscureText: true,
              ),
              SizedBox(height: 15),
              if (widget.isRegistering)
                generateFormField(
                  text: 'Digite a senha novamente, só pra ter certeza',
                  textInputAction: TextInputAction.done,
                  focusNode: _confirmPasswordFocusNode,
                  obscureText: true,
                  validator: (value) {
                    if (value != password) {
                      return 'Ops, parece que as duas senhas são diferentes. Tente novamente.';
                    } else {
                      return null;
                    }
                  },
                  onFieldSubmitted: (value) {
                    confirmPassword = value;
                    _submitForm();
                  },
                ),
              if (widget.isRegistering) SizedBox(height: 15),
              RoundedButton(
                text: widget.isRegistering
                    ? 'Tudo certo, pode criar a minha conta!'
                    : 'Pronto, vamos entrar!',
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget generateFormField({
    String text,
    bool obscureText = false,
    FocusNode focusNode,
    Function(String) onFieldSubmitted,
    String Function(String) validator,
    TextInputType keyboardType,
    TextInputAction textInputAction,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.transparent),
    );

    return TextFormField(
      obscureText: obscureText,
      focusNode: focusNode,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        border: InputBorder.none,
        fillColor: Theme.of(context).primaryColor,
        errorStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        errorBorder: border,
        focusedErrorBorder: border,
        hintText: text,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}