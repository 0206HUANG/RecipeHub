import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/login_vm.dart';
import '../view/admin/adminsignuppage.dart';
import '../view/user/usersignuppage.dart';
import '../view/user/userhomepage.dart';
import '../view/admin/adminHomePage.dart';
import '../view/banned_account.dart';
import '../view/forgot_password_page.dart';
import '../view/main_page.dart';
import '../main.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        backgroundColor: Color.fromRGBO(209, 224, 166, 1),
        resizeToAvoidBottomInset: true,
        body: Consumer<LoginViewModel>(
          // Listening for ViewModel changes
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/background.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                Container(color: Color.fromARGB(6, 116, 116, 116)),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                        left: 30.0, right: 30.0, top: 60.0, bottom: 80),
                    child: Form(
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('HEALTH COOKING',
                                    style: TextStyle(
                                      fontFamily: 'Norwester',
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      height: 1.0,
                                    )),
                                Text('RECIPE APP',
                                    style: TextStyle(
                                      fontFamily: 'Norwester',
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      height: 1.0,
                                    )),
                                Text('IBITES',
                                    style: TextStyle(
                                      fontFamily: 'Norwester',
                                      fontSize: 80,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                      height: 1.0,
                                    )),
                                Text(
                                  'Cook. Share. Stay Fit.',
                                  style: TextStyle(
                                    fontFamily: 'Norwester',
                                    fontSize: 28,
                                    color: const Color.fromARGB(
                                        255, 255, 247, 201),
                                    fontWeight: FontWeight.w500,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            child: Column(children: [
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        400, // fixed max width on large screens
                                  ),
                                  child: TextFormField(
                                    controller: viewModel.emailController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color.fromARGB(
                                          175, 255, 255, 255),
                                      border: UnderlineInputBorder(),
                                      labelText: 'Enter your email',
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 4),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        400, // fixed max width on large screens
                                  ),
                                  child: TextFormField(
                                    obscureText: true,
                                    controller: viewModel.passwordController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color.fromARGB(
                                          175, 255, 255, 255),
                                      border: UnderlineInputBorder(),
                                      labelText: 'Enter your password',
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 4),
                                    ),
                                  ),
                                ),
                              ),
                              if (viewModel.errorMessageController.text != "")
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(86, 0, 0, 0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      viewModel.errorMessageController.text,
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordPage())),
                                child: Text("Forgot Password",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 255, 235, 153),
                                      decoration: TextDecoration.none,
                                      height: 1.0,
                                    )),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => UserSignUpPage())),
                                child: Text("Sign Up as User",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 255, 235, 153),
                                      decoration: TextDecoration.none,
                                      height: 1.0,
                                    )),
                              ),
                              TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminSignUpPage())),
                                child: Text("Sign Up as Admin",
                                    style: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 255, 235, 153),
                                      decoration: TextDecoration.none,
                                      height: 1.0,
                                    )),
                              ),
                            ]),
                          ),
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () {
                                      viewModel.login(
                                        context,
                                        () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminHomePage())),
                                        () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => MainScreen())),
                                        (reason) => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    BannedAccountPage(
                                                        reason: reason))),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 255, 147, 39),
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0)),
                              ),
                              child: viewModel.isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text('Log In',
                                      style: TextStyle(
                                          fontFamily: 'Norwester',
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
