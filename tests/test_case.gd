extends RefCounted
## Minimal base class for headless tests. Methods named test_* are run by run_tests.gd.

var failures: Array[String] = []
var tree_root: Node

var _owned_nodes: Array[Node] = []


## Adds a node to the scene tree for the duration of one test.
func add_to_tree(node: Node) -> Node:
	tree_root.add_child(node)
	_owned_nodes.append(node)
	return node


## Frees a node after the test without adding it to the tree.
func track(node: Node) -> Node:
	_owned_nodes.append(node)
	return node


func cleanup() -> void:
	for node: Node in _owned_nodes:
		if is_instance_valid(node):
			node.free()
	_owned_nodes.clear()


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])


func assert_almost_eq(actual: float, expected: float, message: String, epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
