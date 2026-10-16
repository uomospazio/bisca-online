extends RefCounted
## Animate the layout factor, leaving child hover and wheel rotation independent.
var amount := 1.0
var tween: Tween

func play(page: Control, fit: Callable) -> void:
	if tween and tween.is_valid(): tween.kill()
	amount = 0.0
	fit.call()
	tween = page.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.15)
	tween.tween_method(func(value: float):
		amount = value
		fit.call(), 0.0, 1.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
