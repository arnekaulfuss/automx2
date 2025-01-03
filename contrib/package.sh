#!/usr/bin/env bash
# vim: ts=4 sw=4 noet
# shellcheck disable=1091,2155
#
# Script to package automx2 for distribution and to handle PyPI uploads.
# You need Python modules 'wheel' and 'twine' to publish to PyPI, and
# Ruby Gems 'asciidoctor' and 'asciidoctor-diagram' to generate HTML
# documentation.

set -euo pipefail

function usage() {
	local n="$(basename "${0}")"
	cat >&2 <<EOT
Usage: ${n} {clean | distro | docs | pypi}
       ${n} setver {version}
EOT
	exit 1
}

function _clean() {
	rm -fr build/* dist/*
	find automx2 -type d -name __pycache__ -print0 | xargs -0r rm -r
}

function _distro() {
	python -m build --no-isolation
}

function _docs() {
	local ad="${HOME}/.gem/ruby/3.1.0/bin/asciidoctor"
	local opt=(
		'-r' 'asciidoctor-diagram'
		'-v'
		'automx2.adoc'
	)
	pushd docs >/dev/null
	"${ad}-pdf" -a toc=preamble "${opt[@]}"
	"${ad}" -a toc=right -o index.html "${opt[@]}"
	popd >/dev/null
}

function _pypi() {
	twine upload dist/*
}

function _setver() {
	[[ $# -gt 0 ]] || usage
	sed -E -i -e "s/^(VERSION =).*/\1 '${1}'/" automx2/__init__.py
	sed -E -i -e "s/^(version =).*/\1 ${1}/" setup.cfg
	sed -E -i -e "s/^(:revnumber:).+/\1 ${1}/" docs/automx2.adoc
	sed -E -i -e "s/^(:revdate:).+/\1 $(date +%F)/" docs/automx2.adoc
}

[[ $# -gt 0 ]] || usage
declare -r verb="${1}"
shift
case "${verb}" in
clean | docs)
	_"${verb}"
	;;
distro | pypi)
	. .venv/bin/activate
	_"${verb}" "$@"
	;;
setver)
	_"${verb}" "$@"
	;;
*)
	usage
	;;
esac
