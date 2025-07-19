import 'dart:math' as math;

import 'package:calculator/calculator_models.dart';

class CalculatorLogic {
  static const int maxDigits = 12;
  static const String errorMessage = "Error";

  // Main calculation logic
  static CalculatorState processInput(CalculatorState state, String input) {
    switch (input) {
      case "0":
      case "1":
      case "2":
      case "3":
      case "4":
      case "5":
      case "6":
      case "7":
      case "8":
      case "9":
        return _handleNumber(state, input);
      case ".":
        return _handleDecimal(state);
      case "+":
      case "-":
      case "×":
      case "÷":
        return _handleOperation(state, input);
      case "=":
        return _handleEquals(state);
      case "C":
        return _handleClear(state);
      case "CE":
        return _handleClearEntry(state);
      case "±":
        return _handlePlusMinus(state);
      case "%":
        return _handlePercent(state);
      case "√":
        return _handleSquareRoot(state);
      case "MC":
        return _handleMemoryClear(state);
      case "MR":
        return _handleMemoryRecall(state);
      case "M+":
        return _handleMemoryAdd(state);
      case "M-":
        return _handleMemorySubtract(state);
      case "sin":
      case "cos":
      case "tan":
      case "log":
      case "ln":
      case "x^2":
      case "x^n":
      case "1/x":
        return _handleExpanded(state, input);
      default:
        return state;
    }
  }

  static CalculatorState _handleNumber(CalculatorState state, String number) {
    if (state.shouldResetDisplay || state.display == "0") {
      return state.copyWith(
        display: number,
        currentValue: double.parse(number),
        shouldResetDisplay: false,
      );
    }

    if (state.display.length >= maxDigits) {
      return state;
    }

    final newDisplay = state.display + number;
    return state.copyWith(
      display: newDisplay,
      currentValue: double.parse(newDisplay),
    );
  }

  static CalculatorState _handleDecimal(CalculatorState state) {
    if (state.shouldResetDisplay) {
      return state.copyWith(
        display: "0.",
        currentValue: 0.0,
        shouldResetDisplay: false,
      );
    }

    if (state.display.contains(".")) {
      return state;
    }

    final newDisplay = state.display + ".";
    return state.copyWith(
      display: newDisplay,
      currentValue: double.parse(newDisplay),
    );
  }

  static CalculatorState _handleExpanded(
    CalculatorState state,
    String operation,
  ) {
    // if (state.currentValue != null) {
    //   // Perform pending calculation first
    //   final result = _calculate(
    //     state.previousValue ?? 1,
    //     state.currentValue ?? 0,
    //     "",
    //   );
    //   if (result == null) {
    //     return state.copyWith(display: errorMessage);
    //   }

    //   return state.copyWith(
    //     display: _formatDisplay(result),
    //     currentValue: result,
    //     previousValue: result,
    //     operation: operation,
    //     shouldResetDisplay: true,
    //   );
    // }

    return state.copyWith(
      previousValue: state.currentValue ?? 1,
      display: state.display,
      operation: operation,
      shouldResetDisplay: true,
    );
  }

  static CalculatorState _handleOperation(
    CalculatorState state,
    String operation,
  ) {
    if (state.operation != null &&
        state.previousValue != null &&
        !state.shouldResetDisplay) {
      // Perform pending calculation first
      final result = _calculate(state);
      if (result == null) {
        return state.copyWith(display: errorMessage);
      }

      return state.copyWith(
        display: _formatDisplay(result),
        currentValue: result,
        previousValue: result,
        operation: operation,
        shouldResetDisplay: true,
      );
    }

    return state.copyWith(
      previousValue: state.currentValue ?? 0,
      operation: operation,
      shouldResetDisplay: true,
    );
  }

  static CalculatorState _handleEquals(CalculatorState state) {
    if (state.operation == null ||
        state.previousValue == null ||
        state.currentValue == null) {
      return state;
    }

    final result = _calculate(state);
    if (result == null) {
      return state.copyWith(display: errorMessage);
    }

    // Add to history
    final expression =
        "${_formatDisplay(state.previousValue!)} ${state.operation} ${_formatDisplay(state.currentValue!)}";
    final historyItem = CalculationHistory(
      expression: expression,
      result: _formatDisplay(result),
      timestamp: DateTime.now(),
    );

    final newHistory = [...state.history, historyItem];

    return state.copyWith(
      display: _formatDisplay(result),
      currentValue: result,
      previousValue: null,
      operation: null,
      shouldResetDisplay: true,
      history: newHistory,
    );
  }

  static CalculatorState _handleClear(CalculatorState state) {
    return CalculatorState(
      display: "0",
      memory: 0, // Preserve memory for MC vs C distinction
      rad: state.rad,
    );
  }

  static CalculatorState _handleClearEntry(CalculatorState state) {
    return state.copyWith(
      display: "0",
      currentValue: 0,
      shouldResetDisplay: false,
    );
  }

  static CalculatorState _handlePlusMinus(CalculatorState state) {
    final current = state.currentValue ?? 0;
    final newValue = -current;

    return state.copyWith(
      display: _formatDisplay(newValue),
      currentValue: newValue,
    );
  }

  static CalculatorState _handlePercent(CalculatorState state) {
    final current = state.currentValue ?? 0;
    final result = current / 100;

    return state.copyWith(
      display: _formatDisplay(result),
      currentValue: result,
    );
  }

  static CalculatorState _handleSquareRoot(CalculatorState state) {
    final current = state.currentValue ?? 0;
    if (current < 0) {
      return state.copyWith(display: errorMessage);
    }

    final result = math.sqrt(current);
    return state.copyWith(
      display: _formatDisplay(result),
      currentValue: result,
    );
  }

  static CalculatorState _handleMemoryClear(CalculatorState state) {
    return state.copyWith(memory: 0);
  }

  static CalculatorState _handleMemoryRecall(CalculatorState state) {
    return state.copyWith(
      display: _formatDisplay(state.memory),
      currentValue: state.memory,
      shouldResetDisplay: true,
    );
  }

  static CalculatorState _handleMemoryAdd(CalculatorState state) {
    final current = state.currentValue ?? 0;
    return state.copyWith(
      memory: state.memory + current,
      shouldResetDisplay: true,
    );
  }

  static CalculatorState _handleMemorySubtract(CalculatorState state) {
    final current = state.currentValue ?? 0;
    return state.copyWith(memory: state.memory - current);
  }

  static double? _calculate(CalculatorState state) {
    try {
      final operation = state.operation;
      final a = state.previousValue!;
      final b = state.currentValue!;
      switch (operation) {
        case "+":
          return a + b;
        case "-":
          return a - b;
        case "×":
          return a * b;
        case "÷":
          if (b == 0) return null; // Division by zero
          return a / b;
        case "sin":
          return a * math.sin(_degreeConversion(state.rad, b));
        case "cos":
          return a * math.cos(_degreeConversion(state.rad, b));
        case "tan":
          return a * math.tan(_degreeConversion(state.rad, b));
        case "log":
          return a * math.log(_degreeConversion(state.rad, b));
        case "ln":
          return a * math.log(_degreeConversion(state.rad, b));
        case "x^2":
          return math.pow(a, 2).toDouble();
        case "x^n":
          return math.pow(a, b).toDouble();
        case "1/x":
          return 1 / b;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  static double _degreeConversion(bool isRad, double rad) {
    if (isRad) {
      return rad;
    }
    return rad * math.pi / 180;
  }

  static String _formatDisplay(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    String formatted = value.toStringAsFixed(8);
    formatted = formatted.replaceAll(RegExp(r"0*$"), "");
    formatted = formatted.replaceAll(RegExp(r"\.$"), "");

    if (formatted.length > maxDigits) {
      return value.toStringAsExponential(6);
    }

    return formatted;
  }

  static String formatDisplay(double value) => _formatDisplay(value);
}
