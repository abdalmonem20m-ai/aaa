import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'therapy_service.dart';
import 'user_model.dart';

class AdminCreateGroupScreen extends StatefulWidget {
  @override
  _AdminCreateGroupScreenState createState() => _AdminCreateGroupScreenState();
}

class _AdminCreateGroupScreenState extends State<AdminCreateGroupScreen> {
  final TherapyService _therapyService = TherapyService();
  final _nameController = TextEditingController();
  AppUser? _selectedSupervisor;
  AppUser? _selectedAssistant;
  bool _isButtonPressed = false;

  InputDecoration _buildNeonInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.greenAccent.withOpacity(0.7)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.greenAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: StreamBuilder<List<AppUser>>(
            stream: _therapyService.getAllUsers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
              
              final supervisors = snapshot.data!.where((u) => u.role == UserRole.supervisor).toList();
              final assistants = snapshot.data!.where((u) => u.role == UserRole.assistantSupervisor).toList();

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    AppBar(title: Text("إنشاء مجموعة علاجية"), backgroundColor: Colors.transparent),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: Colors.white),
                      decoration: _buildNeonInput("اسم المجموعة"),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<AppUser>(
                      decoration: _buildNeonInput("تعيين المشرف"),
                      dropdownColor: Color(0xFF001a09),
                      items: supervisors.map((u) => DropdownMenuItem(value: u, child: Text(u.name, style: TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _selectedSupervisor = val),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<AppUser>(
                      decoration: _buildNeonInput("تعيين المساعد"),
                      dropdownColor: Color(0xFF001a09),
                      items: assistants.map((u) => DropdownMenuItem(value: u, child: Text(u.name, style: TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _selectedAssistant = val),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) => setState(() => _isButtonPressed = false),
                      onTapCancel: () => setState(() => _isButtonPressed = false),
                      child: AnimatedScale(
                        scale: _isButtonPressed ? 0.95 : 1.0,
                        duration: Duration(milliseconds: 100),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(_isButtonPressed ? 0.6 : 0.4),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: (_selectedSupervisor != null && _selectedAssistant != null && _nameController.text.isNotEmpty)
                                ? _handleCreateGroup
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              minimumSize: Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Text("إنشاء المجموعة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleCreateGroup() async {
    await _therapyService.createTherapyGroup(
      name: _nameController.text,
      supervisorId: _selectedSupervisor!.uid,
      assistantId: _selectedAssistant!.uid,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إنشاء المجموعة بنجاح")));
  }
}