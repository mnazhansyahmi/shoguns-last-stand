class_name UltimateSkill
extends Node
## The samurai's Ultimate: when the UltimateMeter is full the samurai raises his blade (invulnerable),
## then an ink-brush sweep crosses the whole screen and hits every enemy in view for a heavy hit,
## while the game freezes for a short dramatic pause. Damage goes through the normal
## hitbox/hurtbox validation (faction, invulnerability, death), so enemies react as to any hit.
## The sweep drawing is visual only (UltimateSweep).

signal activated
## The sweep landed: how many enemies it hit.
signal released(hits: int)
## The key was pressed before the meter was full.
signal not_ready(ratio: float)

enum Result { OK, NOT_READY, CANNOT_ACT, NO_PLAYER }

## The game stays frozen this long (real seconds) while the sweep is on screen.
const PAUSE_SECONDS: float = 0.4
## Enemies this far outside the screen edge are still hit (their bodies reach into view).
const RANGE_MARGIN: float = 90.0
## Without a camera, the strike covers this far from the samurai on each side.
const FALLBACK_HALF_WIDTH: float = 950.0
const SWEEP_LAYER: int = 3

var player: Player
var camera: BattleCamera
var meter: UltimateMeter

var _hitbox: HitboxComponent
## Real seconds the freeze lasts (a test can shorten it).
var pause_seconds: float = PAUSE_SECONDS


func _ready() -> void:
	_hitbox = HitboxComponent.new()
	_hitbox.name = "UltimateHitbox"
	_hitbox.faction = Faction.Type.DEFENDERS
	add_child(_hitbox)


func setup(p_player: Player, p_camera: BattleCamera, p_meter: UltimateMeter) -> void:
	if is_instance_valid(player) and player.ultimate_released.is_connected(_on_released):
		player.ultimate_released.disconnect(_on_released)
	player = p_player
	camera = p_camera
	meter = p_meter
	if is_instance_valid(player):
		player.ultimate_released.connect(_on_released)


## The ultimate button/key was pressed.
func request() -> Result:
	if not is_instance_valid(player) or not is_instance_valid(meter):
		return Result.NO_PLAYER
	if not player.can_use_ultimate():
		return Result.CANNOT_ACT
	if not meter.is_ready():
		not_ready.emit(meter.get_ratio())
		return Result.NOT_READY
	if not player.start_ultimate():
		return Result.CANNOT_ACT
	meter.try_consume()
	AudioManager.play(&"ultimate")
	activated.emit()
	return Result.OK


## World x range the sweep covers: what the screen shows, or around the samurai without a camera.
func get_strike_range(origin: Vector2) -> Vector2:
	if is_instance_valid(camera):
		var view: Rect2 = camera.get_view_rect()
		return Vector2(view.position.x - RANGE_MARGIN, view.end.x + RANGE_MARGIN)
	return Vector2(origin.x - FALLBACK_HALF_WIDTH, origin.x + FALLBACK_HALF_WIDTH)


## Hits every living enemy in range once. Returns how many it hit.
func strike(origin: Vector2) -> int:
	var damage: float = player.stats.base_damage * player.stats.ultimate_damage_multiplier
	var span: Vector2 = get_strike_range(origin)
	_hitbox.source = player
	_hitbox.global_position = origin
	_hitbox.knockback_direction_x = 0.0
	# The sweep's own hits must not refill the meter.
	meter.locked = true
	_hitbox.activate(damage, player.stats.ultimate_knockback, -1.0, true)
	var hits: int = 0
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: Enemy = node as Enemy
		if enemy == null or not enemy.is_inside_tree() or enemy.is_dead():
			continue
		var x: float = enemy.global_position.x
		if x < span.x or x > span.y:
			continue
		if _hitbox.try_hit(enemy.get_hurtbox()):
			hits += 1
	_hitbox.deactivate()
	meter.locked = false
	return hits


func _on_released(origin: Vector2, facing: int) -> void:
	var hits: int = strike(origin)
	_play_feedback(facing)
	released.emit(hits)


func _play_feedback(facing: int) -> void:
	if is_instance_valid(BattleFeedback.active):
		BattleFeedback.active.hit_stop(pause_seconds)
		BattleFeedback.active.shake(16.0, 0.5)
		BattleFeedback.active.vibrate(90)
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = SWEEP_LAYER
	var sweep: UltimateSweep = UltimateSweep.new()
	sweep.setup(facing, pause_seconds)
	layer.add_child(sweep)
	add_child(layer)
	# The layer is only a holder for the sweep: free it with the sweep.
	sweep.tree_exited.connect(layer.queue_free)
