extends Area2D

## Same shape as slow_zone.gd: the effect is only active while a body is
## actually standing in the zone, clearing the instant it leaves (unlike
## drug_trap.gd's own fixed duration -- suds don't cling the way a drug
## dose does).


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.has_method("set_on_slippery"):
		body.set_on_slippery(true)


func _on_body_exited(body: Node) -> void:
	if body.has_method("set_on_slippery"):
		body.set_on_slippery(false)
