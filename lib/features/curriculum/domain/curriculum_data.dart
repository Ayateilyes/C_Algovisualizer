import 'package:flutter/material.dart';

/// Difficulty level for a curriculum module.
enum ModuleDifficulty {
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
    ModuleDifficulty.beginner => 'Beginner',
    ModuleDifficulty.intermediate => 'Intermediate',
    ModuleDifficulty.advanced => 'Advanced',
  };

  Color get color => switch (this) {
    ModuleDifficulty.beginner => const Color(0xFF00C896),
    ModuleDifficulty.intermediate => const Color(0xFFFF9800),
    ModuleDifficulty.advanced => const Color(0xFFFF4444),
  };

  IconData get icon => switch (this) {
    ModuleDifficulty.beginner => Icons.eco_rounded,
    ModuleDifficulty.intermediate => Icons.local_fire_department_rounded,
    ModuleDifficulty.advanced => Icons.bolt_rounded,
  };
}

/// A single lesson inside a module.
class Lesson {
  const Lesson({required this.id, required this.title, this.description = ''});

  final String id;
  final String title;
  final String description;
}

/// A curriculum module containing a set of lessons.
class CurriculumModule {
  const CurriculumModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.difficulty,
    required this.lessons,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final ModuleDifficulty difficulty;
  final List<Lesson> lessons;
  final Color accentColor;

  int get totalLessons => lessons.length;
}

/// All 11 curriculum modules.
const kCurriculumModules = <CurriculumModule>[
  CurriculumModule(
    id: 'hello_world',
    title: 'Hello World',
    subtitle: 'Your first C program, compilation, and printf',
    icon: Icons.waving_hand_rounded,
    difficulty: ModuleDifficulty.beginner,
    accentColor: Color(0xFF7C4DFF),
    lessons: [
      Lesson(id: 'hw_01', title: 'What is C?'),
      Lesson(id: 'hw_02', title: 'Your first program'),
      Lesson(id: 'hw_03', title: 'printf and formatting'),
      Lesson(id: 'hw_04', title: 'Comments and style'),
    ],
  ),
  CurriculumModule(
    id: 'variables',
    title: 'Variables & Types',
    subtitle: 'int, float, char, and type casting',
    icon: Icons.data_object_rounded,
    difficulty: ModuleDifficulty.beginner,
    accentColor: Color(0xFF00BCD4),
    lessons: [
      Lesson(id: 'var_01', title: 'Declaring variables'),
      Lesson(id: 'var_02', title: 'Integer types'),
      Lesson(id: 'var_03', title: 'Floating-point numbers'),
      Lesson(id: 'var_04', title: 'Characters and ASCII'),
      Lesson(id: 'var_05', title: 'Type casting'),
    ],
  ),
  CurriculumModule(
    id: 'operators',
    title: 'Operators',
    subtitle: 'Arithmetic, relational, logical, and bitwise',
    icon: Icons.calculate_rounded,
    difficulty: ModuleDifficulty.beginner,
    accentColor: Color(0xFF4CAF50),
    lessons: [
      Lesson(id: 'op_01', title: 'Arithmetic operators'),
      Lesson(id: 'op_02', title: 'Relational operators'),
      Lesson(id: 'op_03', title: 'Logical operators'),
      Lesson(id: 'op_04', title: 'Bitwise operators'),
    ],
  ),
  CurriculumModule(
    id: 'control_flow',
    title: 'Control Flow',
    subtitle: 'if/else, switch, loops: for, while, do-while',
    icon: Icons.alt_route_rounded,
    difficulty: ModuleDifficulty.beginner,
    accentColor: Color(0xFFFF9800),
    lessons: [
      Lesson(id: 'cf_01', title: 'if and else'),
      Lesson(id: 'cf_02', title: 'switch statement'),
      Lesson(id: 'cf_03', title: 'for loops'),
      Lesson(id: 'cf_04', title: 'while and do-while'),
      Lesson(id: 'cf_05', title: 'break and continue'),
    ],
  ),
  CurriculumModule(
    id: 'functions',
    title: 'Functions',
    subtitle: 'Declarations, parameters, return values, recursion',
    icon: Icons.functions_rounded,
    difficulty: ModuleDifficulty.intermediate,
    accentColor: Color(0xFF9C27B0),
    lessons: [
      Lesson(id: 'fn_01', title: 'Function basics'),
      Lesson(id: 'fn_02', title: 'Parameters and return'),
      Lesson(id: 'fn_03', title: 'Function prototypes'),
      Lesson(id: 'fn_04', title: 'Recursion'),
    ],
  ),
  CurriculumModule(
    id: 'arrays',
    title: 'Arrays',
    subtitle: '1D and 2D arrays, string handling with char[]',
    icon: Icons.view_array_rounded,
    difficulty: ModuleDifficulty.intermediate,
    accentColor: Color(0xFF2196F3),
    lessons: [
      Lesson(id: 'arr_01', title: '1D arrays'),
      Lesson(id: 'arr_02', title: 'Array operations'),
      Lesson(id: 'arr_03', title: '2D arrays'),
      Lesson(id: 'arr_04', title: 'Strings with char[]'),
    ],
  ),
  CurriculumModule(
    id: 'pointers',
    title: 'Pointers',
    subtitle: 'Address-of, dereference, pointer arithmetic',
    icon: Icons.point_of_sale_rounded,
    difficulty: ModuleDifficulty.intermediate,
    accentColor: Color(0xFFE91E63),
    lessons: [
      Lesson(id: 'ptr_01', title: 'What are pointers?'),
      Lesson(id: 'ptr_02', title: '& and * operators'),
      Lesson(id: 'ptr_03', title: 'Pointer arithmetic'),
      Lesson(id: 'ptr_04', title: 'Pointers and arrays'),
      Lesson(id: 'ptr_05', title: 'Pointers to functions'),
    ],
  ),
  CurriculumModule(
    id: 'memory',
    title: 'Dynamic Memory',
    subtitle: 'malloc, calloc, realloc, free, and memory leaks',
    icon: Icons.memory_rounded,
    difficulty: ModuleDifficulty.advanced,
    accentColor: Color(0xFFFF5722),
    lessons: [
      Lesson(id: 'mem_01', title: 'Stack vs heap'),
      Lesson(id: 'mem_02', title: 'malloc and free'),
      Lesson(id: 'mem_03', title: 'calloc and realloc'),
      Lesson(id: 'mem_04', title: 'Memory leaks'),
    ],
  ),
  CurriculumModule(
    id: 'structs',
    title: 'Structs & Unions',
    subtitle: 'Custom data types, nested structs, typedef',
    icon: Icons.account_tree_rounded,
    difficulty: ModuleDifficulty.intermediate,
    accentColor: Color(0xFF795548),
    lessons: [
      Lesson(id: 'st_01', title: 'Defining structs'),
      Lesson(id: 'st_02', title: 'Accessing members'),
      Lesson(id: 'st_03', title: 'Nested structs'),
      Lesson(id: 'st_04', title: 'typedef'),
    ],
  ),
  CurriculumModule(
    id: 'file_io',
    title: 'File I/O',
    subtitle: 'fopen, fclose, fread, fwrite, and file modes',
    icon: Icons.folder_open_rounded,
    difficulty: ModuleDifficulty.advanced,
    accentColor: Color(0xFF607D8B),
    lessons: [
      Lesson(id: 'fio_01', title: 'Opening and closing files'),
      Lesson(id: 'fio_02', title: 'Reading from files'),
      Lesson(id: 'fio_03', title: 'Writing to files'),
      Lesson(id: 'fio_04', title: 'File modes'),
    ],
  ),
  CurriculumModule(
    id: 'sorting',
    title: 'Sorting Algorithms',
    subtitle: 'Bubble, selection, insertion, merge, quick sort',
    icon: Icons.sort_rounded,
    difficulty: ModuleDifficulty.advanced,
    accentColor: Color(0xFFFF4081),
    lessons: [
      Lesson(id: 'sort_01', title: 'Bubble sort'),
      Lesson(id: 'sort_02', title: 'Selection sort'),
      Lesson(id: 'sort_03', title: 'Insertion sort'),
      Lesson(id: 'sort_04', title: 'Merge sort'),
      Lesson(id: 'sort_05', title: 'Quick sort'),
    ],
  ),
];
