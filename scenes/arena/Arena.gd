extends Node3D

@onready var nav_region: NavigationRegion3D = $NavRegion

func _ready() -> void:
	# Bake navmesh at runtime if it hasn't been baked in the editor.
	# Single-threaded web build ignores the on_thread flag.
	var nm: NavigationMesh = nav_region.navigation_mesh
	if nm != null and nm.get_polygon_count() == 0:
		nav_region.bake_navigation_mesh(false)
		print("[Arena] navmesh baked at runtime")
	var sp_count := get_tree().get_nodes_in_group("spawn_points").size()
	print("[Arena] ready, spawn_points=%d" % sp_count)
