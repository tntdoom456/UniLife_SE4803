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

  void _AddScheduleForm(BuildContext contex){
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (contex){
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(contex).viewInsets.bottom,
            left: 16, right: 16, top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Jadwal Baru',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16,),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Nama matkul/kegiatan',
                  filled: true,
                  fillColor: const Color.fromARGB(255, 32, 32, 32),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                ),
              ),
              const SizedBox(height: 12,),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Waktu Mulai',
                        hintText: '06:00',
                        filled: true,
                        fillColor: const Color.fromARGB(255, 32, 32, 32),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      ),
                    )
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Waktu Selesai',
                        hintText: '06:00',
                        filled: true,
                        fillColor: const Color.fromARGB(255, 32, 32, 32),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      ),
                    )
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Lokasi',
                  filled: true,
                  fillColor: const Color.fromARGB(255, 32, 32, 32),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: (){
                    Navigator.pop(contex);
                    ScaffoldMessenger.of(contex).showSnackBar(
                      const SnackBar(content: Text('Jadwal Berhasil Ditambahkan'))
                    );
                  }, child: const Text('Simpan jadwal', style: TextStyle(color: Colors.white, fontSize: 16))
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  @override
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
        onPressed: () => _AddScheduleForm(context)
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
