#!/bin/sh
# This script is part of Martin V\"ath's archwrap project.
# It provides shell functions for scripts like "tgzd" "zipd" "u"

YesNo() {
	case ${1:-n} in
	[nNfF]*|[oO][fF]*|0|-)
		return 1;;
	esac
	:
}

which=`command -v which` || which=
MakeExternal() {
	[ x"$which" = x'which' ] && eval $1=\`which $2\` \
		|| eval $1=\`command -v $2\` || eval $1=
	eval ": \${$1:=$2}"
}

OptExternal() {
	eval "[ -n \"\${$1:++}\" ]" || MakeExternal "$1" "${2-$1}"
}

Echo() {
	printf '%s\n' "$*"
}

ErrMessage() {
	Echo "${0##*/}: $*" >&2
}

retvalue=0
Error() {
	e='. '
	[ $1 -gt $retvalue ] && retvalue=$1
	shift
	case $* in
	*'.')
		e=' ';;
	*' '|*'
')
		e=;;
	esac
	if $errbreak
	then	ErrMessage "$*$eStopped."
		exit $retvalue
	else	ErrMessage "$*$e(proceeding)"
		return $retvalue
	fi
}

Exit() {
	[ $retvalue -eq 0 ] && exit
	ErrMessage 'Proceeded despite earlier errors.'
	exit $retvalue
}

Push() {
	PushA_=`push.sh 2>/dev/null` || Fatal \
"push.sh from https://github.com/vaeth/push (v2.0 or newer) required"
	eval "$PushA_"
	Push "$@"
}

tempname=
RmTemp() {
	trap : EXIT HUP INT TERM
	[ -n "${tempname:++}" ] && rm -f -- "$tempname"
	tempname=
	trap - EXIT HUP INT TERM
}

MkTemp() {
	[ -n "${tempname:++}" ] && return
	if [ -z "${havemktemp:++}" ]
	then	command -v mktemp >/dev/null 2>&1 && \
			havemktemp=: || havemktemp=false
	fi
	trap RmTemp EXIT HUP INT TERM
	if $havemktemp
	then	tempname=`umask 077 && mktemp -- "${TMPDIR:-/tmp}/${0##*/}.XXXXXXXX"` \
			&& [ -n "${tempname:++}" ] && test -f "$tempname" \
			&& return
		ErrMessage 'cannot create temporary file'
		return 2
	fi
	if [ -z "${have_random:++}" ]
	then	r=${RANDOM-}
		if [ x"$r" = x"${RANDOM-}" ] && [ x"$r" = x"${RANDOM-}" ]
		then	have_random=false
			r=`od -d -N2 /dev/random 2>/dev/null` || r=
			r=`printf '%s' $r`
			if [ -z "${r:++}" ]
			then	r=1
			else	r=$(( $r % 32768 ))
				[ "$r" -eq 0 ] && r=1
			fi
		else	have_random=:
		fi
		t=
	fi
	c=0
	while [ $c -le 999 ]
	do	if [ -n "${t:++}" ]
		then	if $have_random
			then	r=$RANDOM
			else	r=$(( $r * 13821 ))
				r=$(( $r % 32768 ))
			fi
		fi
		t=${TMPDIR:-/tmp}/${0##*/}.$$$c$r
		(
			umask 077
			set -C
			: >"$t"
		) && tempname=$t && return
		c=$(( $c + 1 ))
	done
	ErrMessage 'cannot create temporary file'
	return 2
}


Cd() {
	case $1 in
	/*)
		cd "$1" >/dev/null 2>&1 || Error 2 "cd $1 failed";;
	*)
		cd "./${1#./}" >/dev/null 2>&1 \
			|| Error 2 "cd $PWD/${1#./} failed";;
	esac
}

PushTopack() {
	Push -c topack
	set +f
	for topacki in .* *
	do	case $topacki in
		.|..)
			continue;;
		esac
		test -r "$topacki" && Push topack "$topacki"
	done
	set -f
	[ -n "${topack:++}" ]
}

CalcGnuTarVersion() {
	OptExternal tarprg tar
	[ -n "${GNUTARVERSION++}" ] || \
		GNUTARVERSION=`"$tarprg" --version 2>/dev/null` \
		|| GNUTARVERSION=
	GNUTARVERSION=${GNUTARVERSION%%'
'*}
	GNUTARVERSION=${GNUTARVERSION##*' '}
}

CalcStarHasNoFsync() {
	star_has_nofsync=:
	if [ -n "${STAR_HAS_NOFSYNC++}" ]
	then	YesNo "$STAR_HAS_NOFSYNC" || star_has_nofsync=false
		return
	fi
	OptExternal tarprg star
	"$tarprg" -c -no-fsync >/dev/null 2>&1 || star_has_nofsync=false
}

CalcGzipbest() {
	if $1 || ! command -v zopfli >/dev/null 2>&1
	then	MakeExternal gzipbest gzipbest
		gziptext=gzip
	else	MakeExternal gzipbest zopflibest
		gziptext=zopfli
	fi
	CalcGzipbest() {
:
}
}

CalcXattr() {
	xattr=:
	YesNo "${XATTR-}" || xattr=false
}

SetTarPrg() {
	tar_knows_sparse=:
	tar_needs_errfile=false
	tar_knows_use_compress_program=:
	tar_knows_gzip=:
	tar_knows_bzip=:
	tar_knows_lzma=false
	tar_knows_xz=false
	tar_knows_numeric_owner=:
	tar_knows_xattr=false
	tar_knows_no_auto_compress=false
	tar_knows_sort=false
	if $use_star
	then	MakeExternal tarprg star
		CalcStarHasNoFsync
		tar_knows_sparse=false
		tar_knows_use_compress_program=false
		tar_knows_xattr=:
		return
	fi
	MakeExternal tarprg tar
	CalcGnuTarVersion
# X >= 1.28: --sort=names
# X >= 1.27: --xattrs
# X >= 1.22: --xz
# X >= 1.21: --no-auto-compress
# X >= 1.20: --lzma
# X >= 1.13.6: --bzip2
# X >= 1.12: --numeric-owner
# X >= 1.11.2: --gzip
	case " $GNUTARVERSION" in
	' ')
		tar_needs_errfile=:
		tar_knows_sparse=false
		tar_knows_use_compress_program=false
		tar_knows_numeric_owner=false
		tar_knows_gzip=false;;
	*' 0.'*|*' 1.0'*|*' 1.10'*|*' 1.11'|*' 1.11.'[01]*)
		tar_knows_use_compress_program=false
		tar_knows_numeric_owner=false
		tar_knows_gzip=false;;
	*' 1.1'[0-1]|*' 1.1'[0-1]'.'*)
		tar_knows_numeric_owner=false
		tar_knows_bzip=false;;
	*' 1.1'[23]|*' 1.1'3.[0-5]*)
		tar_knows_bzip=false;;
	*' 1.1'*)
		:;;
	*' 1.20')
		tar_knows_lzma=:;;
	*' 1.21')
		tar_knows_lzma=:
		tar_knows_no_auto_compress=:;;
	*' 1.2'[2-6])
		tar_knows_lzma=:
		tar_knows_no_auto_compress=:
		tar_knows_xz=:;;
	*' 1.27'|*' 1.27.'*)
		tar_knows_lzma=:
		tar_knows_no_auto_compress=:
		tar_knows_xz=:
		tar_knows_xattr=:;;
	*)
		tar_knows_lzma=:
		tar_knows_no_auto_compress=:
		tar_knows_xz=:
		tar_knows_xattr=:
		tar_knows_sort=:;;
	esac
}
