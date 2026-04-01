#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define YYCTYPE         char
#define YYPEEK()        *s
#define YYSKIP()        ++s
#define YYBACKUP()      marker = s
#define YYRESTORE()     s = marker
#define YYMTAGP(tl)     yytaglist(&tl, s, &yytlp)
#define YYMTAGN(tl)     yytaglist(&tl, NULL, &yytlp)

typedef struct yytaglist_t {
    struct yytaglist_t *list;
    const YYCTYPE *tag;
} yytaglist_t;

typedef struct yytaglistpool_t {
    yytaglist_t *head;
    yytaglist_t *next;
    yytaglist_t *last;
} yytaglistpool_t;

static void yytaglistpool_clear(yytaglistpool_t *tlp)
{
    tlp->next = tlp->head;
}

static void yytaglistpool_init(yytaglistpool_t *tlp)
{
    static const unsigned size = 1024 * 1024;
    tlp->head = (yytaglist_t*)malloc(size * sizeof(yytaglist_t));
    tlp->next = tlp->head;
    tlp->last = tlp->head + size;
}

static void yytaglistpool_free(yytaglistpool_t *tlp)
{
    free(tlp->head);
    tlp->head = tlp->next = tlp->last = NULL;
}

static yytaglist_t *yytaglistpool_next(yytaglistpool_t *tlp)
{
    if (tlp->next == tlp->last) {
        const unsigned size = tlp->last - tlp->head;
        yytaglist_t *head = (yytaglist_t*)malloc(2 * size * sizeof(yytaglist_t));
        memcpy(head, tlp->head, size * sizeof(yytaglist_t));
        free(tlp->head);
        tlp->head = head;
        tlp->next = head + size;
        tlp->last = head + size * 2;
    }
    return tlp->next++;
}

static void yytaglist(yytaglist_t **ptl, const YYCTYPE *t, yytaglistpool_t *tlp)
{
    yytaglist_t *tl = yytaglistpool_next(tlp);
    tl->list = *ptl;
    tl->tag = t;
    *ptl = tl;
}

static void lex(const char *s)
{
    const char *marker;
    /*!re2c
        re2c:yyfill:enable = 0;
        re2c:flags:tags = 1;
        re2c:flags:input = custom;
    */

    yytaglistpool_t yytlp;
    yytaglistpool_init(&yytlp);
    /*!mtags:re2c format = "yytaglist_t *@@ = NULL\n;"; */
    yytaglist_t *e, *k, *v;

    /*!re2c
        key = [a-z]+;
        val = [a-z]*;

        * {
            printf("error\n");
            goto end;
        }
        (#k key "=" #v val ";" #e)* {
            for (; k != NULL; k = k->list, v = v->list, e = e->list) {
                printf("%.*s = %.*s\n",
                    v->tag - k->tag - 1, k->tag,
                    e->tag - v->tag - 1, v->tag);
            }
            goto end;
        }
    */
end:
    yytaglistpool_free(&yytlp);
}

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; ++i) {
        lex(argv[i]);
    }
    return 0;
}
