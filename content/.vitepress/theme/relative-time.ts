/**
 * One relative phrase, shared by everything on the site that prints a date.
 *
 * Three places show one: the marker on each page, the status board, and the
 * last-edited line in the footer. They said the same thing three different ways
 * until this existed, and a reader comparing "checked 2026-08-08" against
 * "edited three weeks ago" has to do arithmetic to find out which came first.
 *
 * Always formatted after mount, never during the build, for two reasons. The
 * build machine and the reader are not in the same timezone, so formatting the
 * same timestamp twice produces two strings and a hydration mismatch. And
 * "three weeks ago" is measured from now rather than from whenever the site was
 * last built, so counting it at build time makes it quietly wrong.
 */

/**
 * Whole days between an ISO day (`2026-08-08`) and now, never negative.
 *
 * A date is the local calendar day a person did something, compared here
 * against a UTC midnight. Somebody recording late in the evening is otherwise a
 * few hours "in the future", which would floor to -1 and print "tomorrow".
 */
export function daysSince(day: string, now: number = Date.now()): number | null {
  const then = new Date(`${day}T00:00:00Z`)
  if (Number.isNaN(then.getTime())) return null
  return Math.max(0, Math.floor((now - then.getTime()) / 86400000))
}

/**
 * How long ago that was, in the reader's language.
 *
 * `numeric: 'auto'` is what turns 1 day into "yesterday", which is the phrase a
 * person would use. It is deliberately not used for the larger units, where it
 * produces "last week" and "last month": those name a calendar period rather
 * than a distance, and a page checked on the 1st is not "last month" on the 3rd.
 */
export function relativeDays(days: number, locale: string): string {
  const near = new Intl.RelativeTimeFormat(locale, { numeric: 'auto' })
  const far = new Intl.RelativeTimeFormat(locale, { numeric: 'always' })

  if (days < 1) return near.format(0, 'day')
  if (days < 7) return near.format(-days, 'day')
  if (days < 30) return far.format(-Math.round(days / 7), 'week')
  if (days < 365) return far.format(-Math.round(days / 30), 'month')
  return far.format(-Math.round(days / 365), 'year')
}

/** The full date, for the tooltip. The exact day stays available everywhere. */
export function exactDate(day: string, locale: string): string {
  const then = new Date(`${day}T00:00:00Z`)
  if (Number.isNaN(then.getTime())) return day
  return new Intl.DateTimeFormat(locale, { dateStyle: 'long', timeZone: 'UTC' }).format(then)
}
