extends Area3D

var _velocity: Vector3 = Vector3.ZERO
var _damage: float = 0.0
var _lifetime: float = 4.0
var _hit: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # only collide with environment (barrier, floor)
	body_entered.connect(_on_body_entered)

func launch(dir: Vector3, speed: float, damage: float) -> void:
	_velocity = dir.normalized() * speed
	_damage = damage

func _process(delta: float) -> void:
	if _hit:
		return
	global_position += _velocity * delta
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _hit:
		return
	_hit = true
	if body.has_method("take_damage"):
		body.take_damage(_damage, self)
	queue_free()
