extends Node

# Persistence to user:// (which is IndexedDB on web).
# Versioned JSON. Atomic writes via tmp+rename.

const SAVE_VERSION: int = 1
const META_PATH: String = "user://meta.save"
const META_TMP_PATH: String = "user://meta.save.tmp"

func _ready() -> void:
	print("[SaveSystem] ready")

func save_meta() -> bool:
	var payload := {
		"version": SAVE_VERSION,
		"data": MetaProgress.to_dict(),
	}
	var json := JSON.stringify(payload)
	var f := FileAccess.open(META_TMP_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[SaveSystem] failed to open tmp save path")
		return false
	f.store_string(json)
	f.close()
	# Atomic-ish rename. On web (IndexedDB) this is still a safer pattern than direct write.
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(META_TMP_PATH), ProjectSettings.globalize_path(META_PATH))
	if err != OK:
		# Fallback: direct write (some platforms reject the rename — web is fine, native may not)
		var f2 := FileAccess.open(META_PATH, FileAccess.WRITE)
		if f2 == null:
			return false
		f2.store_string(json)
		f2.close()
	return true

func load_meta() -> bool:
	if not FileAccess.file_exists(META_PATH):
		print("[SaveSystem] no save found, starting fresh")
		return false
	var f := FileAccess.open(META_PATH, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("[SaveSystem] malformed save, ignoring")
		return false
	var payload: Dictionary = parsed
	var version: int = payload.get("version", 0)
	if version != SAVE_VERSION:
		# Migration hook for future schema bumps. For now, refuse and start fresh.
		push_warning("[SaveSystem] save version mismatch (%d vs %d), starting fresh" % [version, SAVE_VERSION])
		return false
	var data: Dictionary = payload.get("data", {})
	MetaProgress.from_dict(data)
	print("[SaveSystem] loaded meta save: lifetime_score=%d" % MetaProgress.lifetime_score)
	return true

func wipe_meta() -> void:
	if FileAccess.file_exists(META_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
	MetaProgress.reset_all()
	print("[SaveSystem] wiped meta save")
