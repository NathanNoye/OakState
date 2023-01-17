<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

"State on demand for the widgets that need it"
Simple state management library for apps

## Features
Injection focused, simple state management that's decoupled.
Lets you inject managers (think of viewmodels or blocs) that hold your business logic for their widget and make changes anywhere without needing to pass it in

## Getting started
Getting started is fast and easy - there's only 4 steps

### Step one: add the intialization code to your main.dart.
This sets up the app to handle the manager injection

```dart
void main() async {
  await setupOakTree(callback: () {
    // we'll add more here in step 4
  });
  runApp(const MyApp());
}
```

### Step two: Create a manager
Managers are simple classes that extend the BaseManager. 
Note - There's some bells and whistles under the hood but don't worry about those yet.
We'll create a manager with only one set of business logic to keep it easy to understand

A few things to note - "setViewState" is a function from the BaseManager. It updates the view state of the current manager. There are 4 state: idle, busy, error, and success.
The great thing about managers is they have two kinds of state: view state and internal state.
The view state is ultra-generic and let you handle simple view state that should work for 90% - 99% of tasks. The internal state can be anything: an enum, an int, error message - anything. You can have as many as you want. You can even mix the two together. Don't worry about that now though - there'll be more examples later

```dart
import 'package:oak_tree/oak_tree.dart';

class TestManager extends BaseManager {
  int counter = 0;

  void increase() async {
    setViewState(ViewState.busy);
    counter++;
    await Future.delayed(const Duration(seconds: 2));
    setViewState(ViewState.idle);
  }
}
```


### Step three: Create a view 
This view will bind the view to it's manager
Note - Notice how the build function returns a builder that uses the type "TestManager". This is how you bind the TestView to the TestManager and get access to the internal state and functions.
You can see how the builder is checking the view state to determine how to build the view. 
You'll also notice the textbutton has access to the manager's function we just built called "increase". Without needing to set the state - the widget will rebuild itself with the most up to date state automatically.

```dart
import 'package:flutter/material.dart';
import 'package:oak_tree/oak_tree.dart';
import 'package:test_app/test_manager.dart';

class TestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseView<TestManager>(
      builder: (BuildContext context, TestManager manager, _) {
        if (manager.viewstate.isBusy) {
          return const CircularProgressIndicator();
        }

        return Column(
          children: [
            Text('Counter: ${manager.counter}'),
            TextButton(
              onPressed: () {
                manager.increase();
              },
              child: const Text('Tap to increase'),
            )
          ],
        );
      },
    );
  }
}

```

### Step Four: Add manager to the setupOakTree function
Go back to your main.dart and make this change:
```dart
void main() async {
  await setupLocator(callback: () {
    locator.registerLazySingleton(() => TestManager()); // <------ That's the change
  });
  runApp(const MyApp());
}
```

This change adds your manager to the magic. Now you can do all sorts of great things like accessing this manager from other managers, it'll allow you to manipulate the state of any manager and subsequently update the


## Usage

 Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

 Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
