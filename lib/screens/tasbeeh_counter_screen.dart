import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class TasbeehCounterScreen extends StatefulWidget {
  final Map<String, dynamic> zikar;
  final int index;
  final Function(int) onUpdate;

  const TasbeehCounterScreen({
    super.key,
    required this.zikar,
    required this.index,
    required this.onUpdate
  });

  @override
  State<TasbeehCounterScreen> createState() => _TasbeehCounterScreenState();
}

class _TasbeehCounterScreenState extends State<TasbeehCounterScreen> {
  late int _counter;

  @override
  void initState() {
    super.initState();
    _counter = widget.zikar['count'];
  }

  void _increment() async {
    // Logic: Agar counter goal tak pohnch gaya hai to mazeed increment nahi hoga
    if (_counter >= widget.zikar['goal']) {
      return;
    }

    setState(() {
      _counter++;
    });
    widget.onUpdate(_counter);

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 60);
    }

    if (_counter == widget.zikar['goal']) {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: 500);
      }
      _showSuccessDialog();
    }
  }

  void _reset() {
    setState(() {
      _counter = 0;
    });
    widget.onUpdate(0);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text("MashAllah! ❤️")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 10),
            Text("Aapne ${widget.zikar['name']} ka target poora kar liya!"),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Text("Alhamdulillah"),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isGoalReached = _counter >= widget.zikar['goal'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.zikar['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: "Reset Counter",
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _increment,
              child: Container(color: Colors.transparent),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isGoalReached ? "Goal Reached! Click Reset to start again." : "Target: ${widget.zikar['goal']}",
                    style: TextStyle(fontSize: 18, color: isGoalReached ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGoalReached ? Colors.green.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.05),
                      border: Border.all(color: isGoalReached ? Colors.green : Theme.of(context).primaryColor, width: 8),
                      boxShadow: [
                        BoxShadow(
                            color: (isGoalReached ? Colors.green : Theme.of(context).primaryColor).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5
                        )
                      ],
                    ),
                    child: Center(
                      child: Text("$_counter",
                          style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: isGoalReached ? Colors.green : Theme.of(context).primaryColor
                          )),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isGoalReached ? "COMPLETED" : "TAP ANYWHERE TO COUNT",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isGoalReached ? Colors.green : Colors.grey
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}