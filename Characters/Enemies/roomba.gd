class_name Roomba
extends Enemy

@export var search_delay = 1.0

var parts_collected := 0
var is_looking := false

@onready var wait_for_parts_timer = $"Wait For Parts"
@onready var animation_tree = $AnimationTree

func _ready():
	enemy_init()
	current_target = find_closest_part()
	if current_target != null:
		is_looking = true
	else:
		wait_for_parts_timer.start()

func _process(delta):
	if current_target != null:	
		animation_tree.set("parameters/conditions/is_idle", false)
		animation_tree.set("parameters/conditions/is_moving", true)
		animation_tree.set("parameters/Idle/blend_position", input)
		animation_tree.set("parameters/Move/blend_position", input)
		
		if $Roomba/Sprite.flip_h and input.x > 0 or not $Roomba/Sprite.flip_h and input.x < 0:
			var opposite = not $Roomba/Sprite.flip_h
			$Roomba/Sprite.flip_h = opposite
			$Blender/Sprite.flip_h = opposite
			$Coffee/Sprite.flip_h = opposite
			$Refrigerator/Sprite.flip_h = opposite
			$Fan/Sprite.flip_h = opposite
	else:
		animation_tree.set("parameters/conditions/is_idle", true)
		animation_tree.set("parameters/conditions/is_moving", false)

func find_closest_part():
	
	var parts = get_tree().get_nodes_in_group("collectible")
	
	var closest_sqr_distance : float
	var closest_part = null
	if parts.size() > 0:
		var this_distance = global_position.distance_squared_to(parts[0].global_position)
		closest_sqr_distance = this_distance
		closest_part = parts[0]
	
	
	for part in parts:
		var this_distance = global_position.distance_squared_to(part.global_position)

		if this_distance < closest_sqr_distance:
			closest_sqr_distance = this_distance
			closest_part = part
			
	
	return closest_part

func look_for_another():
	current_target = null
	await get_tree().create_timer(search_delay)
	current_target = find_closest_part()
	if current_target == null:
		wait_for_parts_timer.start()
	else:
		is_looking = true

func collect_part():
	parts_collected += 1
	MusicController.p_metallic()
	$Sprite2D.visible = true
	look_for_another()

func take_away_parts():
	player.add_health(parts_collected)
	parts_collected = 0
	$Sprite2D.visible = false

func get_hit(dmg):
	super.get_hit(dmg)
	if health <= 0:
		for i in parts_collected:
			var inst = collectible.instantiate()
			get_parent().add_child(inst)
			var random_offset = Vector2(randi_range(-3, 3), randi_range(-3, 3))
			inst.global_position = global_position + random_offset


func _on_target_refresh_timeout():
	if is_looking and current_target == null:
		is_looking = false
		look_for_another()


# executed when there are no parts in the scene
func _on_wait_for_parts_timeout():
	if get_tree().get_nodes_in_group("collectible").size() > 0:
		look_for_another()
		wait_for_parts_timer.stop()
