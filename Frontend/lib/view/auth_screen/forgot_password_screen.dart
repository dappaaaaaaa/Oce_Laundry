import 'package:aplikasi_demo_test/service/api_service.dart';
import 'package:aplikasi_demo_test/utils/app_color.dart';
import 'package:aplikasi_demo_test/utils/custom_text_field.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _status;
  bool _isObscure = true;
  bool _approved = false;

  /// Kirim request reset password
  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final res = await ApiService().requestResetPassword(
          _emailController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Permintaan berhasil")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Cek status reset password
  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().checkStatus(_emailController.text);
      setState(() {
        _status = res["status"];
        _approved = _status == "done" || _status == "approved";
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Status: $_status")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal cek status: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Ganti password baru
  Future<void> _changePassword() async {
    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password baru tidak boleh kosong")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService().changePassword(
        _emailController.text,
        _newPasswordController.text,
        // konfirmasi sama dengan password baru
      );

      // Cek apakah response status berhasil
      if (res['status'] == 'success' || res['message'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Password berhasil diubah")),
        );
        // Baru navigasi balik ke halaman sebelumnya
        Navigator.of(context).pop();
      } else {
        // Jika server mengembalikan error, tampilkan pesan tapi jangan pindah halaman
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res["message"] ?? "Gagal ganti password")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal ganti password: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(245, 250, 253, 1),
        appBar: AppBar(
          title: Text("Halaman Lupa Password"),
          backgroundColor: AppColor.backgroundColorSecondry,
        ),
        body: Center(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                width: 550,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Lupa Password"),
                    Gap(20),
                    TextFormField(
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Email tidak boleh kosong";
                        } else if (!EmailValidator.validate(value)) {
                          return "Mohon isi email dengan format yang benar";
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: CustomTextFieldStyle.inputDecoration(
                        hintText: "Masukan Email",
                      ),
                    ),
                    Gap(20),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(57, 42, 45, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: (Size(double.infinity, 50)),
                      ),
                      child:
                          _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                'Kirim Request Reset',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                    Gap(20),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _checkStatus,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: (Size(double.infinity, 50)),
                      ),
                      child: Text(
                        'Cek Status',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    if (_approved) ...[
                      Gap(20),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _isObscure,
                        decoration: CustomTextFieldStyle.inputDecoration(
                          hintText: "Password Baru",
                          iconButton: IconButton(
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                            icon:
                                _isObscure
                                    ? Icon(
                                      Icons.visibility_off,
                                      color: Colors.black,
                                    )
                                    : Icon(
                                      Icons.visibility,
                                      color: Colors.black,
                                    ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password tidak boleh kosong";
                          }
                          if (value.length < 6) {
                            return "Password minimal 6 karakter";
                          }
                          return null;
                        },
                      ),
                      Gap(20),
                      OutlinedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  if (_formKey.currentState!.validate()) {
                                    _changePassword();
                                  }
                                },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Ganti Password',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
