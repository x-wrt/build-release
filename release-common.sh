# Shared configuration parsing for workflow generation and packaging.
release_check_name() {
	case "$2" in
		''|*[!A-Za-z0-9._-]*) echo "Invalid $1: $2" >&2; return 1 ;;
	esac
}

release_devices() {
	awk '/^CONFIG_TARGET_DEVICE_.*_DEVICE_.*=y$/ && !/^CONFIG_TARGET_DEVICE_PACKAGES_/ {
		sub(/^CONFIG_TARGET_DEVICE_/, "")
		sub(/=y$/, "")
		sub(/_DEVICE_/, " ")
		print
	}' "$1"
}

release_config_value() {
	awk -F '"' -v key="$2" '$1 == key "=" { print $2; count++ }
		END { if (count != 1) exit 1 }' "$1"
}
