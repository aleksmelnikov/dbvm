/**
 *  Copyright (c) 2026 DBVM (dbvm.com). All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License, version 3,
 *  as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#if !defined(_ACP_FALLTHROUGH_H_)
#define _ACP_FALLTHROUGH_H_

/**
 * @file acpFallthrough.h
 *
 * ACP_FALLTHROUGH: portable "fall through" hint for switch statements.
 *
 * Place "ACP_FALLTHROUGH;" before a case label to tell the compiler that the
 * fall through is intentional; the semantics exactly reproduce the effect of
 * the __attribute__((fallthrough)) / [[clang::fallthrough]] attributes without
 * breaking old compilers (C and C++98/03).
 *
 * Selection rules (verified on gcc 4.6/4.8/5.4/7.5/8/9/14 and clang
 * 3.0/3.4/3.6...3.8/3.9...5.0/6.0/7.0/8.0/9.0/10.0/11.0/21.0, C and C++):
 * - C++ on clang >= 6 with C++11 or newer: [[clang::fallthrough]]; on clang 6+
 *   neither the GNU attribute nor the do{}+comment fallback silences
 *   -Wimplicit-fallthrough any more.
 * - C++98/03: the [[...]] syntax does not exist there (hard error), so it is
 *   never used; clang >= 10 (which still emits -Wimplicit-fallthrough in that
 *   mode) gets the GNU statement attribute, clang < 10 gets a neutral fallback
 *   (clang < 10 does not emit -Wimplicit-fallthrough in C++98/03 at all), and
 *   gcc >= 7 gets the GNU attribute.
 * - C++ on gcc >= 7 (any standard): __attribute__((__fallthrough__)).
 * - C: GNU-syntax statement attribute is broken in C on clang 3.4..9.0 (a
 *   "declaration does not declare anything" trap even though
 *   __has_attribute(__fallthrough__) reports 1), so it is forced to fallback
 *   by version (clang < 10) and used only on clang >= 10 and gcc >= 7.
 * - Everything else (older gcc, non-GNU): do { } while (0) + comment, which is
 *   a valid statement everywhere; those compilers have no
 *   -Wimplicit-fallthrough flag at all.
 */
/* ================================ C++ ================================ */
#if defined(__cplusplus)
#  if (__cplusplus >= 201103L)
      /* C++11 and later. */
#    if defined(__clang__)
      /* clang in C++11+: only [[clang::fallthrough]] works; the GNU statement
       * attribute and the do{}+comment fallback no longer silence
       * -Wimplicit-fallthrough (verified on clang++ 6.0..11). */
#      define ACP_FALLTHROUGH            [[clang::fallthrough]]
#    elif defined(__GNUC__) && (__GNUC__ > 7 || (__GNUC__ == 7 && __GNUC_MINOR__ >= 0))
      /* gcc >= 7: use the GNU attribute. */
#      define ACP_FALLTHROUGH            __attribute__((__fallthrough__))
#    else
      /* Other C++ compilers (gcc < 7 etc.): no -Wimplicit-fallthrough; keep a
       * neutral empty statement so the code stays valid everywhere. */
#      define ACP_FALLTHROUGH            do { } while (0)  /* fallthrough */
#    endif
#  else
      /* C++98/03. The [[...]] attribute syntax does not exist in this mode
       * (hard error on every clang), and clang >= 10 still emits
       * -Wimplicit-fallthrough here, where only the GNU statement attribute
       * silences it (verified on clang++ 10/11 with c++98/c++03/gnu++98.
       * clang < 10 does not emit the warning in C++98/03 at all, so a neutral
       * fallback is correct there. */
#    if (defined(__clang__) && defined(__clang_major__) && (__clang_major__ >= 10)) \
        || (defined(__GNUC__) && (__GNUC__ > 7 || (__GNUC__ == 7 && __GNUC_MINOR__ >= 0)))
#      define ACP_FALLTHROUGH            __attribute__((__fallthrough__))
#    else
#      define ACP_FALLTHROUGH            do { } while (0)  /* fallthrough */
#    endif
#  endif

/* ================================ C ================================ */
#elif defined(__has_attribute)
  /* C mode. __has_attribute is not a macro on gcc < 5, so it must be tested
   * from a nested #if block: a bare "#if __has_attribute(...)" breaks the
   * preprocessor there ("missing binary operator before token (") on
   * gcc 4.6/4.8. */
#  if __has_attribute(__fallthrough__)
#    if defined(__clang__) && defined(__clang_major__) && (__clang_major__ < 10)
      /* Trap on clang 3.4..9 in C: __has_attribute(__fallthrough__) == 1 but
       * the statement attribute is broken ("declaration does not declare
       * anything"); only clang >= 10 supports it in C. The version guard beats
       * the lying has_attribute, so fallback is forced below clang 10. */
#      define ACP_FALLTHROUGH            do { } while (0)  /* fallthrough */
#    else
#      define ACP_FALLTHROUGH            __attribute__((__fallthrough__))
#    endif
#  else
    /* No __fallthrough__ attribute (older clang, non-GNU): fallback. */
#    define ACP_FALLTHROUGH              do { } while (0)  /* fallthrough */
#  endif
#else
  /* No __has_attribute at all (e.g. gcc < 5): plain valid fallback. */
#  define ACP_FALLTHROUGH                do { } while (0)  /* fallthrough */
#endif

#endif
