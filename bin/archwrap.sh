#! /bin/sh
# This script is part of Martin V\"ath's archwrap project.
# It provides shell functions for scripts like "tgzd" "zipd" "u"

Echo() {
	printf '%s\n' "${*}"
}

ErrMessage() {
	printf '%s: %s\n' "${0##*/}" "${*}" >&2
}

retvalue=0
Error() {
	e='. '
	[ "${1}" -gt "${retvalue}" ] && retvalue=${1}
	shift
	case ${*} in
	*'.')	e=' ';;
	*' '|*'
')	e=;;
	esac
	if ${errbreak}
	then	ErrMessage "${*}${e}Stopped."
		exit ${retvalue}
	else	ErrMessage "${*}${e}(proceeding)"
		return ${retvalue}
	fi
}

Exit() {
	[ ${retvalue} -eq 0 ] && exit
	ErrMessage 'Proceeded despite earlier errors.'
	exit ${retvalue}
}

tempname=
RmTemp() {
	trap : EXIT HUP INT TERM
	[ -n "${tempname}" ] && rm -f -- "${tempname}"
	tempname=
	trap - EXIT HUP INT TERM
}

MkTemp() {
	[ -n "${tempname}" ] && return
	if [ -z "${havemktemp}" ]
	then	command -v mktemp >/dev/null 2>&1 && \
			havemktemp=: || havemktemp=false
	fi
	trap RmTemp EXIT HUP INT TERM
	if ${havemktemp}
	then	tempname=`mktemp "/tmp/${0##*/}.XXXXXXXX"` && \
			[ -n "${tempname}" ] && return
		ErrMessage 'cannot create temporary file'
		return 2
	fi
	if [ -z "${have_random}" ]
	then	r=${RANDOM}
		if [ "${r}" = "${RANDOM}" ] && \
			[ "${r}" = "${RANDOM}" ]
		then	have_random=false
			r=`od -d -N2 /dev/random 2>/dev/null` || r=
			r=`printf '%s' ${r}`
			if [ -z "${r}" ]
			then	r=1
			else	r=$(( ${r} % 32768 ))
				[ "${r}" -eq 0 ] && r=1
			fi
		else	have_random=:
		fi
		t=
	fi
	c=0
	while [ ${c} -le 999 ]
	do	if [ -n "${t}" ]
		then	if ${have_random}
			then	r=${RANDOM}
			else	r=$(( ${r} * 13821 ))
				r=$(( ${r} % 32768 ))
			fi
		fi
		t="/tmp/${0##*/}.${$}${c}${r}"
		(
			set -C
			: >"${t}"
		) && tempname=${t} && return
		c=$(( ${c} + 1 ))
	done
	ErrMessage 'cannot create temporary file'
	return 2
}

Push() {
	case ${1} in
	-*)	shift
		eval ${1}=;;
	esac
	PushD_=${1}
	shift
	eval "for PushA_
	do	[ -z \"\${${PushD_}}\" ] && ${PushD_}=\\' \
			|| ${PushD_}=\"\${${PushD_}} '\"
		PushB_=\${PushA_}
		while {
			PushC_=\${PushB_%%\\'*}
			[ \"\${PushC_}\" != \"\${PushB_}\" ]
		}
		do	${PushD_}=\"\${${PushD_}}\${PushC_}'\\\\''\"
			PushB_=\${PushB_#*\\'}
		done
		${PushD_}=\"\${${PushD_}}\${PushB_}'\"
	done"
}

Cd() {
	cd -- "${1}" >/dev/null 2>&1 && return
	Error 2 "cd ${PWD}/${1} failed"
}

PushTopack() {
	Push -c topack
	set +f
	for topacki in .* *
	do	case ${topacki} in
		.|..)	continue;;
		esac
		test -r "${topacki}" && Push topack "${topacki}"
	done
	set -f
	[ -n "${topack}" ]
}
