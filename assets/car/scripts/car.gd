extends VehicleBody

var SettingspanelPath = preload("../scenes/settings.tscn")
var mousedt = Vector2()

# Camera variables

export(bool) var use_camera = true
var lookSensitivity = 0.1
var minLookAngle = -130.0
var maxLookAngle = 25.0
var followCameraAngle = 20
var camera_onoff = true
export(int) var cameraTimerSecond = 2
onready var cameraTimer = 0
var cameraOrbit
var followCameraY = 0
var max_zoom = 3.0
var min_zoom = 0.5
var zoom_speed = 0.09
var zoom = 0.4
var mouse_moving = false

# Car variables
export(bool) var use_controls = true
export(bool) var show_settings = true
# These become just placeholders if presets are in use
var MAX_ENGINE_FORCE = 180.0
var MAX_BRAKE = 5.0
var MAX_STEERING = 0.5
var STEERING_SPEED = 3

################################################
################## Car Script ##################
################################################

func _ready():
	# A camera node is attached if `Use Camera is checked
	if(use_camera):
		cameraOrbit = Spatial.new()
		var aCameraNode : Camera = Camera.new()
		aCameraNode.translate(Vector3(0, 0, 0))
		aCameraNode.rotation_degrees.y = 180
		aCameraNode.far = 750
		# You can change the camera position here
		# It is currently placed on the hood
		cameraOrbit.translate(Vector3(0, 0.6, 0.4))
		cameraOrbit.add_child(aCameraNode)
		add_child(cameraOrbit)
		
		# When the scene starts, the mouse disappeares
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# ..and the Settingspanel gets instanced
	var SettingsPanel = SettingspanelPath.instance()
	SettingsPanel.visible = false
	SettingsPanel.CarNode = self
	call_deferred("add_child", SettingsPanel)

func _physics_process(dt):
	# This variable turns the camera when the car turns
	followCameraY = 0
	# If user wants to control the car
	if(!use_controls):
		return
	var steer_val = 0.0
	var throttle_val = 0.0
	var brake_val = 0.0

	if Input.is_action_pressed("accelerate"):
		throttle_val = 1.0
	if Input.is_action_pressed("reverse"):
		throttle_val = -0.5
	if Input.is_action_pressed("handbrake"):
		brake_val = 1.0
	if Input.is_action_pressed("turn_left"):
		steer_val = 1.0
		if(use_camera): followCameraY = 10
	if Input.is_action_pressed("turn_right"):
		steer_val = -1.0
		if(use_camera): followCameraY = -10
	if Input.is_action_just_pressed("reset"):
		self.rotation.z  = 0
		self.translation.y += 1
	
	if Input.is_action_just_pressed("ui_cancel"):
		# Show or hide the Settingspanel with pressing ESC
		if (show_settings):
			if(get_node("Settings").visible):
				get_node("Settings").visible = false
				camera_onoff = !camera_onoff
			else:
				get_node("Settings").visible = true
				camera_onoff = !camera_onoff
		# Show/hide the mouse with pressing ESC if there is a camera attached to the car
		if (use_camera):
			if(Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE):
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	engine_force = throttle_val * MAX_ENGINE_FORCE
	brake = brake_val * MAX_BRAKE
	
	# Using lerp for a smooth steering
	steering = lerp(steering, steer_val * MAX_STEERING, STEERING_SPEED * dt)

################################################
################# Camera Script ################
################################################

func _input(event):
	if event is InputEventMouseMotion:
		mousedt = event.relative

func _unhandled_input(event):
	mouse_moving = false
	if event.is_action_pressed("cam_zoom_in"):
		mouse_moving = true
		zoom += zoom_speed
	
	if event.is_action_pressed("cam_zoom_out"):
		mouse_moving = true
		zoom -= zoom_speed
	
	zoom = clamp(zoom, min_zoom, max_zoom)
	cameraOrbit.translation.z = zoom

func _process(dt):
	# If user wants to use the car camera
	if(!use_camera || !use_controls):
		return
	
	var rot = Vector3(mousedt.y, mousedt.x, 0) * lookSensitivity
	
	# Checking if the Settingspanel is active or not
	if(camera_onoff):
		# If the mouse is moving then camera turns around the car
		if(mousedt != Vector2() or mouse_moving):
			cameraOrbit.rotation_degrees.x = clamp(cameraOrbit.rotation_degrees.x, minLookAngle, maxLookAngle)
			cameraOrbit.rotation_degrees.x -= rot.x
			cameraOrbit.rotation_degrees.y -= rot.y
			
			# ..and the timer gets activated so that the
			# camera doesn't follow the car for the duration of the timer
			cameraTimer = cameraTimerSecond
		
		if(cameraTimer > 0):
			cameraTimer -= dt
		else:
			
			# If the timer is up / mouse did not move for the duration of the timer
			# The camera smoothly moves to the follow position
#			cameraOrbit.translation.z = lerp(cameraOrbit.translation.z, 0.4, dt * 10)
			cameraOrbit.rotation_degrees.x = lerp(cameraOrbit.rotation_degrees.x, followCameraAngle, dt * 10)
			cameraOrbit.rotation_degrees.y = lerp(cameraOrbit.rotation_degrees.y, followCameraY, dt * 10)
	
	# Recorded mouse positions are being deleted
	# so that we can capture the next movement
	mousedt = Vector2()
