import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'adhkar_model.dart';

class AdhkarScreen extends StatefulWidget {
  @override
  _AdhkarScreenState createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  // بيانات تجريبية (يتم جلبها من Firestore مستقبلاً)
  final List<Dhikr> _morningAdhkar = [
    Dhikr(id: "1", category: "صباح", text: "أصبحنا وأصبح الملك لله", count: 3),
    Dhikr(id: "2", category: "صباح", text: "سبحان الله وبحمده", count: 100),
  ];

  Map<String, int> _counters = {};

  @override
  void initState() {
    super.initState();
    for (var d in _morningAdhkar) {
      _counters[d.id] = d.count;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(title: Text("أذكار الصباح والمساء"), backgroundColor: Colors.transparent),
              Expanded(
                child: ListView.builder(
                  itemCount: _morningAdhkar.length,
                  itemBuilder: (context, index) {
                    final dhikr = _morningAdhkar[index];
                    final current = _counters[dhikr.id] ?? 0;
                    
                    return GestureDetector(
                      onTap: () {
                        if (current > 0) {
                          setState(() => _counters[dhikr.id] = current - 1);
                        }
                      },
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: current == 0 ? Colors.green.withOpacity(0.3) : Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: current == 0 ? Colors.green : Colors.white24),
                        ),
                        child: Column(
                          children: [
                            Text(dhikr.text, style: TextStyle(color: Colors.white, fontSize: 18), textAlign: TextAlign.center),
                            SizedBox(height: 15),
                            CircleAvatar(
                              backgroundColor: current == 0 ? Colors.green : Colors.amber,
                              child: Text("$current", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}