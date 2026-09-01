#!/usr/bin/env sh
# One reader for the question both URL checks ask: does this address still
# serve what the project points a reader at?
#
# There are two lists, the values in facts/ and the addresses written into
# prose, and they are reported differently because the remedy differs: one is
# an edit to facts/, the other an edit to a page and its counterpart. The
# question and the possible answers are the same, so they live here. It is the
# argument scripts/lib/facts.sh makes for keeping one facts reader, and the
# copies had already drifted: check-fact-urls.sh filed a public issue when a
# host declined to answer a script, while check-content-urls.sh recorded the
# same status as the host's bot policy and moved on.
#
# Four answers, sorted by what the run learned rather than by which list the
# address came from:
#
#   ok         2xx or 3xx. The address serves something.
#   refused    401, 403, 405 or 429. The address is live and declines automated
#              clients. It contradicts nothing: an address whose material moved
#              answers 404 or 301, never 403.
#   differs    any other status. The address is live and says the project is
#              wrong about it.
#   unreached  no status at all. Nothing was learned, and that includes whether
#              the address or the runner's own network is the subject.
#
# A refusal is an answer and an absence is not, which is why only `unreached`
# holds a run at exit 2. A refusal is also a standing property of a host rather
# than a passing condition, so gating the exit code on it would mean one forum
# that always declines curl stops every future run from closing anything.

# One request, keeping both halves of what curl says: the status, on stdout,
# and the reason there is no status, on stderr. Sets `code` and `reason`, and
# needs a writable directory in `work`.
#
# The status is read from stdout and never reconstructed from the exit code.
# curl writes its `--write-out` output before exiting non-zero, so a `|| echo
# 000` fallback appends a second 000 to a status that already said 000. The
# result is `000000`, which matches none of the statuses below, and it was
# published as though a server had sent it.
#
# `work` belongs to the caller and `reason` is read by it. Neither of those is
# visible to the linter from inside this file.
# shellcheck disable=SC2154,SC2034
probe() {
  code=$(curl -sSL -o /dev/null -w '%{http_code}' --max-time 20 \
    -A 'thi-setup-notes link check' "$1" 2>"$work/reason") || true
  [ -n "$code" ] || code=000
  reason=$(tr -d '\r' <"$work/reason" | tail -n 1)
}

# Which of the four answers a status is. The callers print it their own way.
classify() {
  case "$1" in
    2* | 3*) echo ok ;;
    401 | 403 | 405 | 429) echo refused ;;
    000) echo unreached ;;
    *) echo differs ;;
  esac
}

# The verdict for a whole run, and the exit code the workflow reads from it:
#
#   0  nothing contradicted the project and every address was reached
#   1  an address answered, and what it answered differs
#   2  an address was never reached, so this run saw an incomplete picture
#
# A contradiction outranks an absence: a run that saw one address moved has
# something to say even if it could not reach another. An absence outranks
# nothing at all, because closing an open issue on a run that could not see
# every address would be closing it on an assumption.
#
# The caller supplies report_differs() and report_ok(), which are the two texts
# that genuinely differ between the lists. The note for a run that reached
# nothing is the same for both and stays here.
verdict() {
  _differs=$1
  _unreached=$2

  if [ "$_differs" -gt 0 ]; then
    report_differs
    return 1
  fi

  if [ "$_unreached" -gt 0 ]; then
    echo
    echo "No status was seen for $_unreached address(es), so nothing was observed"
    echo "about those. That is an account of the network this run had, not of the"
    echo "documentation, and there is nothing to report from it."
    return 2
  fi

  report_ok
  return 0
}
