import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mini_habit_tracker/components/my_heat_map.dart';
import 'package:mini_habit_tracker/database/habit_database.dart';
import 'package:mini_habit_tracker/models/habit.dart';
import 'package:mini_habit_tracker/theme/theme_provider.dart';
import 'package:provider/provider.dart';

import '../components/my_drawer.dart';
import '../components/my_habit.tile.dart';
import '../util/habit_util.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Provider.of<HabitDatabase>(
      context,
      listen: false,
    ).readHabit();
  }

  final TextEditingController _textController = TextEditingController();

  // create new habit method
  void createNewHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(
              hintText: "Create a new habit",
              hintStyle: TextStyle(
                color: Colors.grey[400],
              )),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              // get new habit name
              String newHabitName = _textController.text;

              // save to db
              context.read<HabitDatabase>().addHabbit(newHabitName);

              // pop box
              Navigator.pop(context);

              // clear controller
              _textController.clear();
            },
            child: Text('Save'),
          ),
          MaterialButton(
            onPressed: () {
              // pop box
              Navigator.pop(context);

              // clear controller
              _textController.clear();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  //  check habit on & off
  void checkHabitOnOff(bool? value, Habit habit) {
    // update habit completion status
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  // edit habit box
  void editHabitBox(Habit habit) {
    // set the controller's text to the habit's current name
    _textController.text = habit.name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(
              hintText: "Create a new habit",
              hintStyle: TextStyle(
                color: Colors.grey[400],
              )),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              // get new habit name
              String newHabitName = _textController.text;

              // save to db
              context
                  .read<HabitDatabase>()
                  .updateHabitName(habit.id, newHabitName);

              // pop box
              Navigator.pop(context);

              // clear controller
              _textController.clear();
            },
            child: Text('Save'),
          ),
          MaterialButton(
            onPressed: () {
              // pop box
              Navigator.pop(context);

              // clear controller
              _textController.clear();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // delete habit box
  void deleteHabitBox(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Are you sure you want to delete?',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              // delete from db
              context.read<HabitDatabase>().deleteHabit(habit.id);

              // pop box
              Navigator.pop(context);
            },
            child: Text('Confirm'),
          ),
          MaterialButton(
            onPressed: () {
              // pop box
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
        onPressed: createNewHabit,
      ),
      body: ListView(
        children: [
          // HEATMAP
          _buildHeatMap(),
          // HABIT LIST
          _buildHabitList(),
        ],
      ),
    );
  }

  Widget _buildHabitList() {
    // habit db
    final habitDatabase = context.watch<HabitDatabase>();
    // current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // return list of habits UI
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentHabits.length,
      itemBuilder: (context, index) {
        // get each individual habit
        final habit = currentHabits[index];
        // check if the habit is completed today
        bool isCompletedToday = isHabitCompletedToday(habit.completedDays);
        // return habit tile UI
        return MyHabitTile(
          text: habit.name,
          isCompleted: isCompletedToday,
          onChanged: (value) => checkHabitOnOff(value, habit),
          editHabit: (context) => editHabitBox(habit),
          deleteHabit: (context) => deleteHabitBox(habit),
        );
      },
    );
  }

  Widget _buildHeatMap() {
    // habit database
    final habitDatabase = context.watch<HabitDatabase>();

    // current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // return heat map UI
    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // once the data is available -> build heatmap

          return MyHeatMap(
            startDate: snapshot.data!,
            datasets: prepareHeatMapDataset(currentHabits),
          );
        } else {
          // handle case where no data is returned
          return Container();
        }
      },
    );
  }
}
