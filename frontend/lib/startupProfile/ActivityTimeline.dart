import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimelineEvent {
  final String month;
  final String keyObjective;
  final String majorMilestone;
  final Color color;
  final IconData icon;

  TimelineEvent({
    required this.month,
    required this.keyObjective,
    required this.majorMilestone,
    required this.color,
    required this.icon,
  });
}

class StartupTimeline extends StatelessWidget {
  StartupTimeline({super.key});

  final List<TimelineEvent> events = [
    TimelineEvent(
      month: "January",
      keyObjective: "Define product roadmap",
      majorMilestone:
          "MVP design finalized with all core features mapped and workflow diagrams completed",
      color: Color(0xFFFF6B2C),
      icon: Icons.analytics,
    ),
    TimelineEvent(
      month: "February",
      keyObjective: "Start development sprint",
      majorMilestone:
          "Backend setup complete, including database schemas, API endpoints, and initial integrations",
      color: Color(0xFFFF6B2C),
      icon: Icons.bar_chart,
    ),
    TimelineEvent(
      month: "March",
      keyObjective: "UI/UX Design Completion",
      majorMilestone:
          "Prototype ready for testing with all user flows and interactive screens implemented",
      color: Color(0xFFFF6B2C),
      icon: Icons.desktop_mac,
    ),
    TimelineEvent(
      month: "April",
      keyObjective: "Alpha Testing",
      majorMilestone:
          "Initial user feedback collected, critical bugs identified, and usability improvements planned",
      color: Color(0xFFFF6B2C),
      icon: Icons.lightbulb,
    ),
    TimelineEvent(
      month: "May",
      keyObjective: "Beta Release",
      majorMilestone:
          "Public beta launched with comprehensive documentation and user onboarding materials",
      color: Color(0xFFFF6B2C),
      icon: Icons.show_chart,
    ),
    TimelineEvent(
      month: "June",
      keyObjective: "Product Launch",
      majorMilestone:
          "Official release and marketing kickoff, including press coverage and initial customer onboarding",
      color: Color(0xFFFF6B2C),
      icon: Icons.launch,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Card(
          elevation: 4,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "Activity Timeline",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: List.generate(events.length, (index) {
                    final event = events[index];
                    final isLast = index == events.length - 1;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline Column
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: event.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                event.icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 80,
                                color: Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Card
                        Expanded(
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.month,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Key Objective: ${event.keyObjective}",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Major Milestone: ${event.majorMilestone}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

void main() => runApp(
  MaterialApp(debugShowCheckedModeBanner: false, home: StartupTimeline()),
);
