import 'package:flutter/material.dart';
import 'models/measure.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Measure> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    // Using mock data instead of database
    setState(() {
      _measurements = Measure.getMockMeasures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Measurement History'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
            decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade500,
            ],
          ),
        ),
        child: _measurements.isEmpty
            ? Center(
                child: Text(
                  'No measurements yet',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: _measurements.length,
                padding: EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                  final measure = _measurements[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    color: Colors.white.withOpacity(0.9),
                    child: ListTile(
                      title: Text(
                        'Heart Rate: ${measure.heartRate} BPM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SpO₂: ${measure.oxygenLevel.toStringAsFixed(1)}%',
                            style: TextStyle(color: Colors.black87),
                              ),
                              Text(
                            'BP: ${measure.systolic.toStringAsFixed(0)}/${measure.diastolic.toStringAsFixed(0)} mmHg',
                            style: TextStyle(color: Colors.black87),
                          ),
                          Text(
                            'Date: ${measure.timestamp.toString().split('.')[0]}',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
