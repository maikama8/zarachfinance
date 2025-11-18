import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import 'package:table_calendar/table_calendar.dart';

class PaymentCalendarScreen extends StatefulWidget {
  const PaymentCalendarScreen({super.key});

  @override
  State<PaymentCalendarScreen> createState() => _PaymentCalendarScreenState();
}

class _PaymentCalendarScreenState extends State<PaymentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<PaymentEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadPaymentSchedule();
  }

  Future<void> _loadPaymentSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('device_id') ?? '';
      
      if (deviceId.isEmpty) return;

      try {
        final schedule = await ApiClient.getPaymentSchedule(deviceId);
        _events = _convertScheduleToEvents(schedule);
        setState(() {});
      } catch (e) {
        debugPrint('Error loading payment schedule: $e');
      }
    } catch (e) {
      debugPrint('Error loading payment schedule: $e');
    }
  }

  Map<DateTime, List<PaymentEvent>> _convertScheduleToEvents(PaymentSchedule schedule) {
    final events = <DateTime, List<PaymentEvent>>{};
    
    for (final item in schedule.schedule) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.dueDate);
      final day = DateTime(date.year, date.month, date.day);
      
      if (!events.containsKey(day)) {
        events[day] = [];
      }
      
      events[day]!.add(PaymentEvent(
        amount: item.amount,
        status: item.status,
        date: date,
      ));
    }
    
    return events;
  }

  List<PaymentEvent> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<PaymentEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          Expanded(
            child: _buildEventList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Text(
          'No payments scheduled for this day',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: event.status == 'paid'
                  ? Colors.green
                  : event.status == 'overdue'
                      ? Colors.red
                      : Colors.orange,
              child: Icon(
                event.status == 'paid'
                    ? Icons.check
                    : event.status == 'overdue'
                        ? Icons.warning
                        : Icons.schedule,
                color: Colors.white,
              ),
            ),
            title: Text('₦${event.amount.toStringAsFixed(2)}'),
            subtitle: Text(event.status.toUpperCase()),
            trailing: event.status == 'pending'
                ? ElevatedButton(
                    onPressed: () {
                      // Navigate to payment screen
                    },
                    child: const Text('Pay'),
                  )
                : null,
          ),
        );
      },
    );
  }
}

class PaymentEvent {
  final double amount;
  final String status;
  final DateTime date;

  PaymentEvent({
    required this.amount,
    required this.status,
    required this.date,
  });
}

