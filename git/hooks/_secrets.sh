# Sourced by git/hooks/pre-commit. Lightweight, dependency-free secret
# scan: a filename blocklist plus a handful of high-confidence content
# patterns (real key formats, not generic "key=..." assignments, to
# keep false positives rare). Not a replacement for gitleaks/detect-secrets
# — just a cheap last line of defense for personal use.
#
# False positive? Adjust the patterns below, or bypass once with
# `git commit --no-verify`.

SECRET_FILENAME_PATTERNS=(
  '(^|/)\.env(\..+)?$'
  '(^|/)id_(rsa|dsa|ecdsa|ed25519)$'
  '\.pem$'
  '\.p12$'
  '\.pfx$'
  '(^|/)credentials\.json$'
  '(^|/)service[-_]?account.*\.json$'
)

SECRET_FILENAME_ALLOWLIST=(
  '\.env\.(example|sample|template)$'
)

SECRET_CONTENT_PATTERNS=(
  '-----BEGIN (RSA |EC |OPENSSH |DSA |PGP )?PRIVATE KEY-----'
  'AKIA[0-9A-Z]{16}'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  'sk-ant-[A-Za-z0-9_-]{20,}'
  'sk-[A-Za-z0-9]{20,}'
)

check_secret_filenames() {
  local path pattern allow ok found=0
  # -z: without it, git quotes/escapes unusual filenames (e.g. embedded
  # quotes) in a way a plain line read never unwraps, so a secret file
  # with such a name would silently pass the pattern check below.
  while IFS= read -r -d '' path; do
    ok=1
    for pattern in "${SECRET_FILENAME_PATTERNS[@]}"; do
      [[ "$path" =~ $pattern ]] || continue
      for allow in "${SECRET_FILENAME_ALLOWLIST[@]}"; do
        [[ "$path" =~ $allow ]] && ok=0
      done
      if [ "$ok" -eq 1 ]; then
        echo "pre-commit: staged file looks like a secret file: $path" >&2
        found=1
      fi
    done
  done < <(git diff --cached --name-only -z --diff-filter=ACMR)
  return $found
}

check_secret_patterns() {
  local current_file="" content pattern found=0
  while IFS= read -r line; do
    case "$line" in
    "+++ b/"*)
      current_file="${line#+++ b/}"
      ;;
    "+"*)
      content="${line#+}"
      for pattern in "${SECRET_CONTENT_PATTERNS[@]}"; do
        if [[ "$content" =~ $pattern ]]; then
          echo "pre-commit: possible secret in $current_file (matches: $pattern)" >&2
          found=1
        fi
      done
      ;;
    esac
  done < <(git diff --cached -U0 --diff-filter=ACMR)
  return $found
}
