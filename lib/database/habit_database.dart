import 'package:flutter/material.dart';
import 'package:mini_habit_tracker/models/app_settings.dart';
import 'package:mini_habit_tracker/models/habit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  /* 
  SETUP
  */

  // INITIALIZE - DATABASE
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [HabitSchema, AppSettingsSchema],
      directory: dir.path,
    );
  }

  // Save first date of app startup (for heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      // there is not has exist settings
      final settings = AppSettings();
      settings.firstLaunchDate = DateTime.now();
      await isar.writeTxn(
        // put settings to database
        () => isar.appSettings.put(settings),
      );
    }
  }

  // Get first date of app startup (for heatmap)
  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  /*
  CRUD X OPERATIONS
  */

  // List of habits
  final List<Habit> currentHabits = [];
  // CREATE - add a new habit
  Future<void> addHabbit(String habitName) async {
    // create a new habit
    final newHabit = Habit();
    newHabit.name = habitName;
    // save to db
    await isar.writeTxn(
      () => isar.habits.put(newHabit),
    );
    // re-read from db
    readHabit();
  }

  // READ - read saved habits from database
  Future<void> readHabit() async {
    // fetch all habits from db
    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    // give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    // update UI
    notifyListeners();
  }

  // UPDATE - check habit on and off
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    // find the specific habit
    final habit = await isar.habits.get(id);

    // update completion status
    if (habit != null) {
      await isar.writeTxn(() async {
        // if habit is completed -> add the current date to the completedDays list

        if (isCompleted &&
            !habit.completedDays.contains(
              DateTime.now(),
            )) {
          // add the current date if it's not already in the list
          habit.completedDays.add(
            DateTime.now(),
          );
        } else {
          // if habit is NOT completed -> remove the current date from the list
          habit.completedDays.removeWhere(
            (date) =>
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day,
          );
        }
        // save the updated habits back to the db
        await isar.habits.put(habit);
      });
      readHabit();
    }
  }

  // UPDATE - edit habit name
  Future<void> updateHabitName(int id, String newName) async {
    // find the specific habit
    final habit = await isar.habits.get(id);

    // update habit name
    if (habit != null) {
      await isar.writeTxn(() async {
        habit.name = newName;

        // save updated habit back to the db
        isar.habits.put(habit);
      });
    }

    // re-read from db
    readHabit();
  }

  // DELETE - delete habit
  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
    // re-read from db
    readHabit();
  }
}
