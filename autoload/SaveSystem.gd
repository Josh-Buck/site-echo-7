extends Node

# Persistence to user:// (which is IndexedDB on web).
# Versioned JSON. Atomic writes via tmp+rename.

const SAVE_VERSION: int = 1
const META_PATH: String = "user://meta.save"
const META_TMP_PATH: String = "user://meta.save.tmp"
const BACKUP_PATHS: Array[String] = [
	"user://meta.save.bak.1",
	"user://meta.save.bak.2",
	"user://meta.save.bak.3",
]

func _ready() -> void:
	print("[SaveSystem] ready")

func save_meta() -> bool:
	# Rotate existing backup chain so a corrupted save can fall back to
	# meta.save.bak.1 (most recent), then .bak.2, .bak.3.
	_rotate_backups()
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

func _rotate_backups() -> void:
	# Shift bak.2 -> bak.3, bak.1 -> bak.2, meta.save -> bak.1. Best-effort: ignore
	# rename failures (a missing source just skips that step).
	if not FileAccess.file_exists(META_PATH):
		return
	# Drop the oldest if it exists.
	if FileAccess.file_exists(BACKUP_PATHS[2]):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATHS[2]))
	# bak.2 -> bak.3
	if FileAccess.file_exists(BACKUP_PATHS[1]):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(BACKUP_PATHS[1]), ProjectSettings.globalize_path(BACKUP_PATHS[2]))
	# bak.1 -> bak.2
	if FileAccess.file_exists(BACKUP_PATHS[0]):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(BACKUP_PATHS[0]), ProjectSettings.globalize_path(BACKUP_PATHS[1]))
	# meta.save -> bak.1 (via copy so the original stays in case rename fails).
	var src := FileAccess.open(META_PATH, FileAccess.READ)
	if src == null:
		return
	var txt := src.get_as_text()
	src.close()
	var dst := FileAccess.open(BACKUP_PATHS[0], FileAccess.WRITE)
	if dst == null:
		return
	dst.store_string(txt)
	dst.close()

func load_meta() -> bool:
	if _try_load_from(META_PATH):
		return true
	# Primary corrupt or missing — try the rotating backups in order.
	for path in BACKUP_PATHS:
		if FileAccess.file_exists(path):
			push_warning("[SaveSystem] primary save unusable, attempting backup: %s" % path)
			if _try_load_from(path):
				# Re-save so the working copy is the primary.
				save_meta()
				return true
	print("[SaveSystem] no save found, starting fresh")
	return false

func _try_load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("[SaveSystem] malformed save: %s" % path)
		return false
	var payload: Dictionary = parsed
	var version: int = payload.get("version", 0)
	if version != SAVE_VERSION:
		payload = _migrate(payload, version)
		if payload.is_empty():
			push_warning("[SaveSystem] save version %d unmigratable (current %d): %s" % [version, SAVE_VERSION, path])
			return false
	var data: Dictionary = payload.get("data", {})
	MetaProgress.from_dict(data)
	print("[SaveSystem] loaded meta save from %s: lifetime_score=%d" % [path, MetaProgress.lifetime_score])
	return true

func _migrate(payload: Dictionary, from_version: int) -> Dictionary:
	# Stepwise schema migrations. Return {} to refuse and start fresh.
	# Future bumps: while from_version < SAVE_VERSION: payload = _migrate_<n>_to_<n+1>(payload); from_version += 1
	if from_version > SAVE_VERSION:
		return {}
	payload["version"] = SAVE_VERSION
	return payload

func wipe_meta() -> void:
	if FileAccess.file_exists(META_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
	MetaProgress.reset_all()
	print("[SaveSystem] wiped meta save")
