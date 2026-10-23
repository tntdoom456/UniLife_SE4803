import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _ScheduleDataSource extends CalendarDataSource {
  _ScheduleDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  List<Appointment> _getDummyAppointments() {
    List<Appointment> jadwal = <Appointment>[];
    final DateTime today = DateTime.now();
    final DateTime startTime = DateTime(
      today.year,
      today.month,
      today.day,
      8,
      30,
      0,
    );
    jadwal.add(
      Appointment(
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        subject: 'Pemrograman Perangkat Bergerak',
        location: 'Gedung TULT 06.01',
        color: Colors.deepPurpleAccent,
      ),
    );
    jadwal.add(
      Appointment(
        startTime: startTime.add(const Duration(hours: 3)),
        endTime: startTime.add(const Duration(hours: 4, minutes: 30)),
        subject: 'Rapat Himpunan',
        location: 'Sekre Himpunan',
        color: Colors.blueAccent,
      ),
    );
    jadwal.add(
      Appointment(
        startTime: startTime.add(const Duration(days: 1, hours: 1)),
        endTime: startTime.add(const Duration(days: 1, hours: 3)),
        subject: 'Deadline UI/UX Design',
        location: 'Submit LMS',
        color: Colors.redAccent,
      ),
    );
    return jadwal;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Lihat Peta Lokasi',
            onPressed: () {
              context.push('/map'); // Navigasi ke halaman MapPage
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambah jadwal')));
        },
      ),

      body: SfCalendar(
        view: CalendarView.workWeek,
        firstDayOfWeek: 1,
        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 7,
          endHour: 22,
          timeFormat: 'HH:mm',
          timeTextStyle: TextStyle(color: Colors.white),
        ),
        dataSource: _ScheduleDataSource(_getDummyAppointments()),
        onTap: (CalendarTapDetails details) {
          if (details.appointments != null) {
            final Appointment app = details.appointments![0];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detail: ${app.subject} di ${app.location}'),
              ),
            );
          }
        },
      ),
    );
  }
}
