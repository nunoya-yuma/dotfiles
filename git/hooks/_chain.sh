# Sourced by git/hooks/* — chains to a repo-local hook of the same name
# before any hook-specific logic runs.
#
# core.hooksPath is set globally (see git/gitconfig), so git stops
# looking at <repo>/.git/hooks/* entirely. That silently disables hooks
# a tool installed directly there — e.g. the `pre-commit` framework
# writes .git/hooks/pre-commit itself, and never learns about this
# global override. Chaining keeps those working: if the local hook
# fails, `set -e` in the caller aborts with its exit code.
chain_to_local_hook() {
  local hook_name="$1"
  shift
  local common_dir local_hook
  common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 0
  local_hook="$common_dir/hooks/$hook_name"
  [ -x "$local_hook" ] || return 0
  [ "$local_hook" -ef "$0" ] && return 0
  "$local_hook" "$@"
}
