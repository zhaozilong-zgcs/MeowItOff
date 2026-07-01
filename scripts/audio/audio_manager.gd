class_name AudioManager
extends Node

const TRACK_PATHS := {
	&"BGM_MENU": "res://assets/bgm/BGM_MENU.mp3",
	&"BGM_PLAY_L1": "res://assets/bgm/BGM_PLAY_L1.mp3",
	&"BGM_PLAY_L2": "res://assets/bgm/BGM_PLAY_L1.mp3",
	&"BGM_PLAY_L3": "res://assets/bgm/BGM_PLAY_L1.mp3",
	&"BGM_DARK": "res://assets/bgm/BGM_DARK.mp3",
	&"BGM_TENSE": "res://assets/bgm/BGM_DARK.mp3",
	&"BGM_EDITOR": "res://assets/bgm/BGM_EDITOR.mp3",
	&"STING_WIN": "res://assets/bgm/STING_WIN.mp3",
	&"STING_LOSE": "res://assets/bgm/STING_LOSE.mp3",
	&"STING_CATCH": "res://assets/bgm/STING_CATCH.mp3",
}

var music_player: AudioStreamPlayer
var sting_player: AudioStreamPlayer
var current_bgm_id: StringName = &""
var missing_warned := {}


func _ready() -> void:
	_ensure_players()


func play_bgm(track_id: StringName) -> void:
	_ensure_players()
	if current_bgm_id == track_id and music_player.playing:
		return

	var stream := _load_stream(track_id, true)
	if stream == null:
		return

	current_bgm_id = track_id
	music_player.stream = stream
	music_player.play()


func stop_bgm() -> void:
	current_bgm_id = &""
	if music_player:
		music_player.stop()


func play_sting(sting_id: StringName) -> void:
	_ensure_players()
	var stream := _load_stream(sting_id, false)
	if stream == null:
		return

	sting_player.stop()
	sting_player.stream = stream
	sting_player.play()


func _ensure_players() -> void:
	if music_player and sting_player:
		return

	if not music_player:
		music_player = AudioStreamPlayer.new()
		music_player.volume_db = -7.0
		add_child(music_player)

	if not sting_player:
		sting_player = AudioStreamPlayer.new()
		sting_player.volume_db = -1.5
		add_child(sting_player)


func _load_stream(track_id: StringName, should_loop: bool) -> AudioStream:
	if not TRACK_PATHS.has(track_id):
		push_warning("Audio track is not registered: %s" % track_id)
		return null

	var path := TRACK_PATHS[track_id] as String
	if not ResourceLoader.exists(path):
		if not missing_warned.has(track_id):
			missing_warned[track_id] = true
			push_warning("Audio file is missing: %s" % path)
		return null

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("Audio file could not be loaded: %s" % path)
		return null

	_set_stream_looping(stream, should_loop)
	return stream


func _set_stream_looping(stream: AudioStream, should_loop: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = should_loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = should_loop
