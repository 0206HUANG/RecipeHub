import '../../conditional_import.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/usersignup_vm.dart';

class UserSignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSignUpViewModel(),
      child: Consumer<UserSignUpViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          backgroundColor: Color.fromRGBO(215, 210, 178, 1),
          appBar: AppBar(
            title: Text("IBITES User - Signup",
                style: TextStyle(
                    fontFamily: 'Norwester',
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 153, 119, 106),
          ),
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background2.png'),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Form(
                    key: viewModel.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: viewModel.fullname,
                          decoration: InputDecoration(
                              labelText: 'Full Name',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: viewModel.gender,
                          onChanged: (val) => viewModel.gender = val,
                          items: [
                            'Male',
                            'Female',
                            'Other',
                            'Prefer not to say'
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          decoration: InputDecoration(
                              labelText: 'Gender',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: viewModel.height,
                          decoration: InputDecoration(
                              labelText: 'Height (cm)',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: viewModel.weight,
                          decoration: InputDecoration(
                              labelText: 'Weight (kg)',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: viewModel.email,
                          decoration: InputDecoration(
                              labelText: 'Email',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: viewModel.contactNo,
                          decoration: InputDecoration(
                              labelText: 'Contact Number',
                              hintText: '+60123456789',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Contact number is required';
                            }

                            final pattern = r'^\+[0-9]{11,12}$';
                            final regex = RegExp(pattern);

                            if (!regex.hasMatch(value.trim())) {
                              return 'Enter a valid Phone number (e.g. +60123456789)';
                            }

                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: viewModel.password,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4)),
                          obscureText: true,
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: viewModel.confirmPassword,
                          decoration:
                              InputDecoration(labelText: 'Confirm Password'),
                          obscureText: true,
                          validator: (value) {
                            if (value!.isEmpty) return 'Required';
                            if (value != viewModel.password.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: viewModel.isChecked,
                              fillColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              checkColor:
                                  const Color.fromARGB(255, 24, 109, 24),
                              onChanged: (val) {
                                viewModel.isChecked = val ?? false;
                                viewModel.notifyListeners();
                              },
                            ),
                            Expanded(
                              child: Text(
                                  "I have read and agreed to abide by the rules & regulations"),
                            )
                          ],
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 100,
                          child: ElevatedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () async {
                                    if (viewModel.formKey.currentState!
                                        .validate()) {
                                      final error =
                                          await viewModel.signUp(context);
                                      if (error == null) {
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                      }
                                    }
                                    viewModel.isLoading = false;
                                    viewModel.notifyListeners();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 255, 147, 39),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0)),
                            ),
                            child: viewModel.isLoading
                                ? CircularProgressIndicator()
                                : Text("Sign Up",
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
          ),
        ),
      ),
    );
  }
}
