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
                      decoration: InputDecoration(
                        labelText: "اسم المجموعة",
                        labelStyle: TextStyle(color: Colors.amber),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      ),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<AppUser>(
                      decoration: InputDecoration(labelText: "تعيين المشرف", labelStyle: TextStyle(color: Colors.white70)),
                      dropdownColor: Color(0xFF003311),
                      items: supervisors.map((u) => DropdownMenuItem(value: u, child: Text(u.name, style: TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _selectedSupervisor = val),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<AppUser>(
                      decoration: InputDecoration(labelText: "تعيين المساعد", labelStyle: TextStyle(color: Colors.white70)),
                      dropdownColor: Color(0xFF003311),
                      items: assistants.map((u) => DropdownMenuItem(value: u, child: Text(u.name, style: TextStyle(color: Colors.white)))).toList(),
                      onChanged: (val) => setState(() => _selectedAssistant = val),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: (_selectedSupervisor != null && _selectedAssistant != null && _nameController.text.isNotEmpty)
                          ? _handleCreateGroup
                          : null,
                      child: Container(width: double.infinity, alignment: Alignment.center, child: Text("إنشاء المجموعة")),
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