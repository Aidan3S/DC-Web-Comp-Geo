extends KinematicBody

onready var camera = $CameraRotator/Camera
onready var camera_rotator = $CameraRotator

const MOUSE_SENS = 0.11
const BASE_SPEED = 3
const SLOW_SPEED = 1
const FAST_SPEED = 10


var last_mouse_pos = Vector2()
var speed = BASE_SPEED


func _physics_process(_delta):
	var camera_pos = camera.get_global_transform()
	
	if Input.is_action_pressed("sprint"):
		speed = FAST_SPEED
	elif Input.is_action_pressed("crouch"):
		speed = SLOW_SPEED
	else:
		speed = BASE_SPEED
	
	var input_vector = Vector3()
	
	if Input.is_action_pressed("move_forward"):
		input_vector.z -= 1.0
	if Input.is_action_pressed("move_backward"):
		input_vector.z += 1.0
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1.0
	if Input.is_action_pressed("move_up"):
		input_vector.y += 1.0
	if Input.is_action_pressed("move_down"):
		input_vector.y -= 1.0
	
	var dir = camera_pos.basis * input_vector
	
	dir.normalized()
	dir *= speed
	
	var _res = move_and_slide(dir, Vector3(0, 1, 0), 0.05, 4, deg2rad(40))

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotator.rotate_x(deg2rad(event.relative.y * MOUSE_SENS * -1))
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENS * -1))
		
		var camera_rot = camera_rotator.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -90, 90)
		camera_rotator.rotation_degrees = camera_rot
		
	if event is InputEventMouseButton:
		if event.pressed:
			last_mouse_pos = get_viewport().get_mouse_position()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_viewport().warp_mouse(last_mouse_pos)
