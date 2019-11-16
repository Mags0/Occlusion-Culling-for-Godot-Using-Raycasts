extends Node

export var get_camera_node = "" #Sets parent if left blank
export var camera_is_self : bool #Script is on camera
export var cull_group = "Occlusion_Culling" #Group to be culled
export var occlusion_accuracy = 1000.0 #amount of rays
export var scans_per_second = 10.0
var occ_acc_nums : Array = [0.0, 0.0, 0.0] #ray screen position values
var cam #Camera reference
var line : Array = [1.0, 1.0] #Ray position
var all_meshes : Array #All MeshInstances in group
var auto_update : float #Updates nodes in group
var reOcclude : float #Time for rescaning
onready var occ_cull_meshes = get_tree().get_nodes_in_group(cull_group)

func _ready():
	reOcclude = 2
	_camera_is_self(camera_is_self)
	_set_occlusion_accuracy(occlusion_accuracy)
	pass

func _physics_process(delta):
	if reOcclude > 1.0/scans_per_second:
		for i in occ_cull_meshes.size():
			if !occ_cull_meshes[i] is MeshInstance:
				var cur_children = occ_cull_meshes[i].get_children()
				for child in cur_children.size():
					if cur_children[child] is MeshInstance:
						all_meshes.append(cur_children[child])
			elif occ_cull_meshes[i] is MeshInstance:
				all_meshes.append(occ_cull_meshes[i])
		for i in all_meshes.size():
			all_meshes[i].visible = false
		line[0] = 1.0
		line[1] = 1.0
		while (get_viewport().size.y * occ_acc_nums[1]) * line[1] < get_viewport().size.y:
			var point = Vector2((get_viewport().size.x * occ_acc_nums[0]) * line[0], (get_viewport().size.y * occ_acc_nums[1]) * line[1])
			var cull_pos = cam.project_ray_origin(point)
			var far_cull = cull_pos + cam.project_ray_normal(point) * cam.far
			var cull_object = cam.get_world().direct_space_state.intersect_ray(cull_pos, far_cull, [cam], true, true)
			if !cull_object:
				pass
			else:
				var obj = cull_object.collider
				if all_meshes.has(obj.get_parent()):
					obj.get_parent().visible = true
				else:
					var children = obj.get_children()
					for index in children.size():
						if all_meshes.has(children[index]):
							children[index].visible = true
			line[0] += 1
			if line[0] > occ_acc_nums[2]:
				line[0] = 1.0
				line[1] += 1
		all_meshes.clear()
		reOcclude = 0
	else:
		reOcclude += delta
		pass

func _process(delta):
	if auto_update < 5:
		auto_update += delta
	else:
		auto_update = 0.0
		_set_occlusion_group(cull_group)
	pass

func _set_occlusion_group(group):
	occ_cull_meshes = get_tree().get_nodes_in_group(group)
	cull_group = group
	pass

func _set_occlusion_accuracy(value):
	occlusion_accuracy = value
	occ_acc_nums[0] = 1/(value/20)
	occ_acc_nums[1] = 1/(value/50)
	occ_acc_nums[2] = value*0.05
	pass

func _get_camera_node(theCamera):
	if camera_is_self:
		camera_is_self = false
	
	if theCamera == "" || theCamera == null:
		cam = get_parent()
	else:
		cam = get_node(theCamera)
	pass

func _camera_is_self(is_self):
	if is_self == true:
		camera_is_self = true
		cam = self
	else:
		camera_is_self = false
		_get_camera_node(get_camera_node)
	pass