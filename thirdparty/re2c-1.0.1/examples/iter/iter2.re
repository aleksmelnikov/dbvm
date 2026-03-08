#include <stdio.h>
#include <string.h>
#include <vector>

struct taglist_t
{
    int pred;
    long tag;
};
typedef std::vector<taglist_t> taglistpool_t;

/*!max:re2c*/

/* at least maximal lexeme length plus YYMAXFILL */
static const size_t SIZE = 4096 * 1024;

struct input_t {
    char buf[SIZE + YYMAXFILL];
    char *lim;
    char *cur;
    char *mar;
    char *tok;
    /*!mtags:re2c format = "int @@;"; */
    bool eof;
    taglistpool_t tlp;

    input_t()
        : buf()
        , lim(buf + SIZE)
        , cur(lim)
        , mar(lim)
        , tok(lim)
        /*!mtags:re2c format = ", @@(-1)"; */
        , eof(false)
        , tlp()
    {}
    bool fill(size_t need)
    {
        if (eof) {
            printf("\nfill: underflow - 1\n");
            return false;
        }
        const size_t free = tok - buf;
        if (free < need) {
            printf("\nfill: underflow - 2\n");
            return false;
        }
        memmove(buf, tok, lim - tok);
        lim -= free;
        cur -= free;
        mar -= free;
        tok -= free;
        lim += fread(lim, 1, free, stdin);
        if (lim < buf + SIZE) {
            eof = true;
            memset(lim, 0, YYMAXFILL);
            lim += YYMAXFILL;
        }
        return true;
    }
};

static void taglist(int *ptl, char *s, input_t *in)
{
    taglist_t l = {*ptl, s ? s - in->tok : 0};
    *ptl = (int)in->tlp.size();
    in->tlp.push_back(l);
}

#define YYPEEK()       *in.cur
#define YYSKIP()       ++in.cur
#define YYBACKUP()     in.mar = in.cur
#define YYRESTORE()    in.cur = in.mar
#define YYMTAGP(tl)    taglist(&tl, in.cur, &in)
#define YYMTAGN(tl)    taglist(&tl, NULL, &in)
#define YYLESSTHAN(n)  in.lim - in.cur < n

static void lex(input_t &in)
{
    in.tok = in.cur;
    int k, v, e;
    /*!re2c
        re2c:define:YYCTYPE = char;
        re2c:define:YYFILL = "if (!in.fill(@@)) { printf(\"error\\n\"); return; }";
        re2c:define:YYFILL:naked = 1;
        re2c:flags:input = custom;
        re2c:flags:tags = 1;
        re2c:tags:expression = "in.@@";

        end = "\x00";
        key = [a-z]+;
        val = [a-z]*;

        * { printf("error\n"); return; }

        (#k key "=" #v val ";" #e)* end {
            taglistpool_t &tlp = in.tlp;
            for (; k != -1; k = tlp[k].pred, v = tlp[v].pred, e = tlp[e].pred) {
                const char *pk = in.tok + tlp[k].tag, *pv = in.tok + tlp[v].tag, *pe = in.tok + tlp[e].tag;
                printf("%.*s = %.*s\n", pv - pk - 1, pk, pe - pv - 1, pv);
            }
            return;
        }
    */
}

int main(int argc, char **argv)
{
    input_t in;
    lex(in);
    return 0;
}
