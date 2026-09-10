#!/usr/bin/env bash
# create-adr.sh — Non-interactive ADR helper around adr-tools.
#
# adr-tools always writes STATUS=Accepted on `adr new`. This wrapper forces
# Proposed at create time and defers Supercedes until `accept`.
#
# Usage:
#   create-adr.sh [--proposes N]... "Title"
#   create-adr.sh accept <number-or-file>
#   create-adr.sh reject <number-or-file>
#
# Do NOT pass adr-tools -s at create time; that immediately unbinds the old ADR.

set -euo pipefail

export VISUAL=true
export EDITOR=true

if ! command -v adr >/dev/null 2>&1; then
	echo "Error: adr-tools not found (adr). Install adr-tools first." >&2
	exit 1
fi

ADR_PATH="$(command -v adr)"
ADR_BIN="$(dirname "${ADR_PATH}")"

usage() {
	cat >&2 <<'EOF'
Usage:
  create-adr.sh [--proposes N]... "Title of the ADR"
  create-adr.sh accept <number-or-file>
  create-adr.sh reject <number-or-file>

Notes:
  - New ADRs are rewritten from Accepted to Proposed after adr new.
  - --proposes N adds "Proposes to supersede" prose without calling adr new -s.
  - accept applies Supercedes via adr link + _adr_remove_status.
EOF
	exit 2
}

adr_dir() {
	# Prefer adr-tools discovery; fall back for docs/adr without .adr-dir yet.
	if [[ -x "${ADR_BIN}/_adr_dir" ]]; then
		local d
		d="$("${ADR_BIN}/_adr_dir" 2>/dev/null || true)"
		if [[ -n ${d} && -d ${d} ]]; then
			echo "${d}"
			return
		fi
	fi
	if [[ -f .adr-dir ]]; then
		cat .adr-dir
	elif [[ -d docs/adr ]]; then
		echo docs/adr
	elif [[ -d doc/adr ]]; then
		echo doc/adr
	else
		echo "Error: ADR directory not found (run: adr init docs/adr)" >&2
		exit 1
	fi
}

resolve_adr_file() {
	local ref="$1"
	if [[ -f ${ref} ]]; then
		echo "${ref}"
		return
	fi
	# adr-tools resolver (number, basename, or partial title)
	if [[ -x "${ADR_BIN}/_adr_file" ]]; then
		local found
		found="$("${ADR_BIN}/_adr_file" "${ref}" 2>/dev/null || true)"
		if [[ -n ${found} && -f ${found} ]]; then
			echo "${found}"
			return
		fi
	fi
	local dir
	dir="$(adr_dir)"
	if [[ -f "${dir}/${ref}" ]]; then
		echo "${dir}/${ref}"
		return
	fi
	echo "Error: could not resolve ADR reference: ${ref}" >&2
	exit 1
}

adr_number() {
	local base
	base="$(basename "$1")"
	echo "$((10#${base%%-*}))"
}

get_status_line() {
	# Prefer a single known status token in the Status section.
	local line
	if [[ -x "${ADR_BIN}/_adr_status" ]]; then
		line="$("${ADR_BIN}/_adr_status" "$1" | awk 'NF { print; exit }')"
	else
		line="$(awk '
			BEGIN { in_status=0 }
			/^## Status$/ { in_status=1; next }
			in_status && NF { print; exit }
		' "$1")"
	fi
	case "${line}" in
	Proposed | Accepted | Rejected | Deprecated | Superseded)
		echo "${line}"
		;;
	Superceded\ by\ * | Superseded\ by\ *)
		echo "Superseded"
		;;
	*)
		# Fall back to raw first line for display in errors.
		echo "${line}"
		;;
	esac
}

require_proposed() {
	local file="$1"
	local action="$2"
	local status
	status="$(get_status_line "${file}")"
	if [[ ${status} != "Proposed" ]]; then
		echo "Error: ${action} requires Status Proposed (found: ${status}) in ${file}" >&2
		exit 1
	fi
}

set_status() {
	local file="$1"
	local new_status="$2"
	local tmp
	tmp="$(mktemp)"
	awk -v ns="${new_status}" '
		BEGIN { in_status=0; replaced=0 }
		/^## Status$/ { in_status=1; print; next }
		in_status && !replaced && NF {
			print ns
			replaced=1
			in_status=0
			next
		}
		{ print }
	' "${file}" >"${tmp}"
	mv "${tmp}" "${file}"
}

append_proposes_lines() {
	local file="$1"
	shift
	[[ $# -eq 0 ]] && return

	local tmp in_status=0 status_seen=0 line t target_file target_base
	tmp="$(mktemp)"
	{
		while IFS= read -r line || [[ -n ${line} ]]; do
			if [[ ${line} == "## Status" ]]; then
				in_status=1
				printf '%s\n' "${line}"
				continue
			fi
			if [[ ${in_status} -eq 1 && ${status_seen} -eq 0 && -n ${line} ]]; then
				printf '%s\n' "${line}"
				status_seen=1
				for t in "$@"; do
					target_file="$(resolve_adr_file "${t}")"
					target_base="$(basename "${target_file}")"
					printf '\nProposes to supersede [%s](%s)\n' "${target_base%.md}" "${target_base}"
				done
				in_status=0
				continue
			fi
			printf '%s\n' "${line}"
		done <"${file}"
	} >"${tmp}"
	mv "${tmp}" "${file}"
}

extract_propose_targets() {
	sed -n 's/.*Proposes to supersede [^[]*\[\([^]]*\)\](\([^)]*\)).*/\2/p' "$1"
}

cmd_create() {
	local proposes=()
	local title_parts=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--proposes)
			shift
			[[ $# -gt 0 ]] || usage
			proposes+=("$1")
			shift
			;;
		-s | --supercedes | --supersedes)
			echo "Error: do not use -s/--supercedes at create time; use --proposes N then 'accept'." >&2
			exit 1
			;;
		-h | --help)
			usage
			;;
		*)
			title_parts+=("$1")
			shift
			;;
		esac
	done

	[[ ${#title_parts[@]} -gt 0 ]] || usage

	local created
	if ! created="$(adr new "${title_parts[*]}")"; then
		echo "Error: Failed to create ADR." >&2
		exit 1
	fi

	created="${created%%$'\n'*}"
	created="${created//$'\r'/}"
	if [[ ! -f ${created} ]]; then
		created="$(resolve_adr_file "${created}")"
	fi

	set_status "${created}" "Proposed"

	if [[ ${#proposes[@]} -gt 0 ]]; then
		append_proposes_lines "${created}" "${proposes[@]}"
	fi

	echo "${created}"
}

apply_supercedes() {
	local new_file="$1"
	local old_ref="$2"
	local new_num old_file old_num
	new_num="$(adr_number "${new_file}")"
	old_file="$(resolve_adr_file "${old_ref}")"
	old_num="$(adr_number "${old_file}")"

	# Same effect as adr-tools `adr new -s`, deferred until Accept.
	adr link "${new_num}" Supercedes "${old_num}" "Superceded by"
	"${ADR_BIN}/_adr_remove_status" Accepted "${old_num}"
}

cmd_accept() {
	[[ $# -eq 1 ]] || usage
	local file target
	file="$(resolve_adr_file "$1")"
	require_proposed "${file}" "accept"

	set_status "${file}" "Accepted"

	# Collect targets before stripping propose prose.
	local targets=()
	local propose_list
	propose_list="$(extract_propose_targets "${file}")"
	while IFS= read -r target; do
		[[ -z ${target} ]] && continue
		targets+=("${target}")
	done <<<"${propose_list}"

	local tmp
	tmp="$(mktemp)"
	awk '!/Proposes to supersede/' "${file}" >"${tmp}"
	mv "${tmp}" "${file}"

	for target in "${targets[@]}"; do
		apply_supercedes "${file}" "${target}"
	done

	# Refresh index when present; warn if generate fails.
	local dir
	dir="$(adr_dir)"
	if [[ -f "${dir}/README.md" || -f "${dir}/index.md" ]]; then
		if ! adr generate toc >"${dir}/README.md"; then
			echo "Warning: adr generate toc failed; index may be stale." >&2
		fi
	fi

	echo "${file}"
}

cmd_reject() {
	[[ $# -eq 1 ]] || usage
	local file
	file="$(resolve_adr_file "$1")"
	require_proposed "${file}" "reject"
	set_status "${file}" "Rejected"
	echo "${file}"
}

main() {
	[[ $# -gt 0 ]] || usage
	case "$1" in
	accept)
		shift
		cmd_accept "$@"
		;;
	reject)
		shift
		cmd_reject "$@"
		;;
	-h | --help)
		usage
		;;
	*)
		cmd_create "$@"
		;;
	esac
}

main "$@"
