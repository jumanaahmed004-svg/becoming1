import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const kCategories = ['Academic', 'Project', 'Skill', 'Certificate', 'Personal'];
const kStatuses = ['In progress', 'Completed'];
const kImpactLabels = ['Small step', 'Steady', 'Meaningful', 'Big win', 'Life-changing'];

class CategoryStyle {
  const CategoryStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}

const _categoryStyles = <String, CategoryStyle>{
  'Academic': CategoryStyle(Icons.school_rounded, Color(0xFF8AB4FF)),
  'Project': CategoryStyle(Icons.rocket_launch_rounded, Color(0xFFB79CFF)),
  'Skill': CategoryStyle(Icons.bolt_rounded, Color(0xFFFFD166)),
  'Certificate': CategoryStyle(Icons.workspace_premium_rounded, Color(0xFF6EE7B7)),
  'Personal': CategoryStyle(Icons.favorite_rounded, Color(0xFFFF9E7A)),
};

CategoryStyle categoryStyle(String name) =>
    _categoryStyles[name] ?? const CategoryStyle(Icons.star_rounded, Color(0xFFB79CFF));

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// One achievement record, stored at users/{uid}/achievements/{id}.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.date,
    this.reflection = '',
    this.impact = 3,
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String category;
  final String status;
  final DateTime date;
  final String reflection;
  final int impact; // 1 to 5
  final bool isFeatured;

  bool get isCompleted => status == 'Completed';

  factory Achievement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['achievementDate'];
    final rawImpact = d['impact'];
    return Achievement(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      category: (d['category'] ?? 'Personal') as String,
      status: (d['status'] ?? 'In progress') as String,
      date: ts is Timestamp ? ts.toDate() : DateTime.now(),
      reflection: (d['reflection'] ?? '') as String,
      impact: rawImpact is num ? rawImpact.toInt().clamp(1, 5).toInt() : 3,
      isFeatured: d['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category,
        'status': status,
        'achievementDate': Timestamp.fromDate(date),
        'reflection': reflection,
        'impact': impact,
        'isFeatured': isFeatured,
      };
}
