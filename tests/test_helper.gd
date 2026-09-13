## Minimal assertion collector for the headless test runner.
class_name TestHelper
extends RefCounted

var checks := 0
var failures: Array[String] = []

var _current := ""


func start(suite_and_test: String) -> void:
	_current = suite_and_test


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append("%s: %s" % [_current, message])


func equals(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s: %s (expected %s, got %s)" % [_current, message, expected, actual])
