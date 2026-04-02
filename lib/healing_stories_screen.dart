import 'package:flutter/material.dart';
import 'animated_background.dart';
import 'case_model.dart';
import 'therapy_service.dart';

class HealingStoriesScreen extends StatelessWidget {
  final TherapyService _therapyService = TherapyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              AppBar(
                title: Text("قصص الشفاء والإثباتات"),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: StreamBuilder<List<HealingCase>>(
                  stream: _therapyService.getApprovedStories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                    final stories = snapshot.data!;
                    if (stories.isEmpty) return Center(child: Text("لا توجد قصص منشورة حالياً", style: TextStyle(color: Colors.white)));

                    return ListView.builder(
                      itemCount: stories.length,
                      itemBuilder: (context, index) => _buildStoryCard(context, stories[index]),
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

  Widget _buildStoryCard(BuildContext context, HealingCase story) {
    return Card(
      margin: EdgeInsets.all(12),
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text("حالة شفاء بفضل الله", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            subtitle: Text("تاريخ الإتمام: ${story.createdAt.toString().split(' ')[0]}", style: TextStyle(color: Colors.white70)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(story.report, style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          if (story.evidenceUrls.isNotEmpty)
            Container(
              height: 150,
              padding: EdgeInsets.all(16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: story.evidenceUrls.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      story.evidenceUrls[i],
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.white24),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}