import 'package:appp_logic_mobile/ui/views/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores de Texto
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controladores Extra (Solo para Registro)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  DateTime? _selectedDate;

  final _formKey = GlobalKey<FormState>();

  // ESTADO: ¿Estamos registrando o logueando?
  bool _isRegistering = false;

  //SELECTOR DE FECHA
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00FF00),
              onPrimary: Colors.black,
              surface: Color(0xFF0D1117),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0D1117),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // DIÁLOGO RECUPERAR CONTRASEÑA
  void _showRecoverPasswordDialog(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final resetEmailController = TextEditingController(
      text: _emailController.text,
    );
    final neonGreen = const Color(0xFF00FF00);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: neonGreen, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: neonGreen),
            const SizedBox(width: 10),
            const Text(
              "RECUPERAR CONTRASEÑA",
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Introduce tu correo electronico para recibir un enlace de restablecimiento.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
              ),
              decoration: InputDecoration(
                labelText: 'Correo Electronico',
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: neonGreen),
                ),
                filled: true,
                fillColor: Colors.black26,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: neonGreen),
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                Navigator.pop(context); // Cerrar diálogo

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Transmitting request..."),
                    backgroundColor: Colors.black,
                  ),
                );

                bool sent = await authVM.resetPassword(
                  resetEmailController.text.trim(),
                );

                if (context.mounted) {
                  if (sent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Link enviado! Revisa tu correo."),
                        backgroundColor: neonGreen,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error: Email no encontrado."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text(
              "ENVIAR",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final neonGreen = const Color(0xFF00FF00);
    final darkBg = const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. LOGO GIGANTE
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.terminal, size: 150, color: neonGreen),
                  ),
                ),

                const SizedBox(height: 40),

                // 2. CAMPOS DE REGISTRO (Solo si _isRegistering es true)
                if (_isRegistering) ...[
                  _buildHackerInput(
                    controller: _nameController,
                    label: 'Codename (Usuario)',
                    icon: Icons.person_outline,
                    neonColor: neonGreen,
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: _buildHackerInput(
                        controller: _dobController,
                        label: 'Fecha de Nacimiento',
                        icon: Icons.calendar_today,
                        neonColor: neonGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. CAMPOS COMUNES (Email y Password)
                _buildHackerInput(
                  controller: _emailController,
                  label: 'Correo Electronico',
                  icon: Icons.alternate_email,
                  neonColor: neonGreen,
                ),
                const SizedBox(height: 16),

                _buildHackerInput(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  neonColor: neonGreen,
                ),

                // 4. LINK "FORGOT PASSWORD" (Solo en Login)
                if (!_isRegistering)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showRecoverPasswordDialog(context),
                      child: const Text(
                        "OLVIDASTE TU CONTRASEÑA?",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontFamily: 'Courier',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 32),

                // 5. MENSAJE DE ERROR
                if (authViewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      '> ERROR: ${authViewModel.errorMessage}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'Courier',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 6. BOTÓN PRINCIPAL (EXECUTE)
                authViewModel.isLoading
                    ? Center(child: CircularProgressIndicator(color: neonGreen))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: neonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            bool success;

                            if (_isRegistering) {
                              if (_selectedDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Error: la fecha es obligatoria.",
                                    ),
                                  ),
                                );
                                return;
                              }

                              success = await authViewModel.register(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                                _nameController.text.trim(),
                                "Agent",
                                _nameController.text.trim(),
                                _selectedDate!,
                              );
                            } else {
                              success = await authViewModel.login(
                                _emailController.text.trim(),
                                _passwordController.text.trim(),
                              );
                            }

                            if (success && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainScreen(),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          _isRegistering ? '> REGISTRAR' : '> INICIAR SESION',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                            fontSize: 16,
                          ),
                        ),
                      ),

                const SizedBox(height: 24),

                // ---------------------------------------------
                // 7. GOOGLE SIGN IN (Integración Nueva)
                // ---------------------------------------------
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[800])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "OR",
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[800])),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.g_mobiledata,
                      size: 30,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "ACCESO CON GOOGLE",
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: authViewModel.isLoading
                        ? null
                        : () async {
                            bool success = await authViewModel
                                .loginWithGoogle();
                            if (success && mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainScreen(),
                                ),
                              );
                            }
                          },
                  ),
                ),

                const SizedBox(height: 24),

                // 8. TOGGLE (Cambiar entre Login/Registro)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.grey,
                      ),
                      children: [
                        TextSpan(
                          text: _isRegistering
                              ? 'Ya tienes una cuenta? '
                              : "No tienes una cuenta? ",
                        ),
                        TextSpan(
                          text: _isRegistering
                              ? 'Iniciar Sesión'
                              : 'Crear Cuenta',
                          style: TextStyle(
                            color: neonGreen,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA LOS INPUTS ---
  Widget _buildHackerInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color neonColor,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white54,
          fontFamily: 'Courier',
        ),
        prefixIcon: Icon(icon, color: neonColor),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: neonColor),
        ),
        filled: true,
        fillColor: Colors.black26,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '> ERROR: Null value detected';
        }
        return null;
      },
    );
  }
}
