#! /bin/sh
# you need to source this to your shell
# . ./export-kubeconfig.sh

# shellcheck disable=SC2155
# shellcheck disable=SC2128
# shellcheck disable=SC2039
# shellcheck disable=SC3053
# FIXME: I'd rather use $(terraform output k8s_admin_conf) but that only works
#        from top-level dir :(

# Stupid bash
if [ -n "$BASH_SOURCE" ]; then
# > In POSIX sh, array references are undefined.
# for sure, I'm trying to support systems which use bash as sh
# shellcheck disable=SC3054
	THIS_SCRIPT="${BASH_SOURCE[0]}"
else
	THIS_SCRIPT="$0"
fi

export KUBECONFIG=$(realpath "$(dirname "$THIS_SCRIPT")/../data/kubectl.conf")
