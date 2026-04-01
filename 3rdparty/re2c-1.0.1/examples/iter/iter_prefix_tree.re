#include <stdio.h>
#include <vector>

struct taglist_t
{
    int pred;
    const char *tag;
};
typedef std::vector<taglist_t> taglistpool_t;

static void taglist(int *ptl, const char *t, taglistpool_t *tlp)
{
    taglist_t l = {*ptl, t};
    *ptl = (int)tlp->size();
    tlp->push_back(l);
}

#define YYCTYPE        char
#define YYPEEK()       *s
#define YYSKIP()       ++s
#define YYBACKUP()     m = s
#define YYRESTORE()    s = m
#define YYMTAGP(tl)    taglist(&tl, s, &tlp)
#define YYMTAGN(tl)    taglist(&tl, NULL, &tlp)

static void lex(const char *s)
{
    const char *m;
    taglistpool_t tlp;
    /*!mtags:re2c format = "int @@ = -1;"; */
    int e, k, v;

    /*!re2c
        re2c:yyfill:enable = 0;
        re2c:flags:tags = 1;
        re2c:flags:input = custom;

        key = [a-z]+;
        val = [a-z]*;

        * { printf("error\n"); return; }

        (#k key "=" #v val ";" #e)* {
            for (; k != -1; k = tlp[k].pred, v = tlp[v].pred, e = tlp[e].pred) {
                const char *pk = tlp[k].tag, *pv = tlp[v].tag, *pe = tlp[e].tag;
                printf("%.*s = %.*s\n", pv - pk - 1, pk, pe - pv - 1, pv);
            }
            return;
        }
    */
}

int main(int argc, char **argv)
{
    for (int i = 1; i < argc; ++i) {
        lex(argv[i]);
    }
    return 0;
}
