#include <assert.h>
#include <stddef.h>
#include <stdio.h>
#include <vector>

typedef std::vector<const char*> taglist_t;

static void lex(const char *s)
{
#define YYPEEK()       *s
#define YYSKIP()       ++s
#define YYBACKUP()     marker = s
#define YYRESTORE()    s = marker
#define YYMTAGP(t)     t.push_back(s)
#define YYMTAGN(t)     t.push_back(NULL)
    const char *marker;
    /*!re2c
        re2c:define:YYCTYPE = char;
        re2c:yyfill:enable = 0;
        re2c:flags:tags = 1;
        re2c:flags:input = custom;
    */
    /*!mtags:re2c format = "taglist_t @@;"; */
    taglist_t k, v, e;

    /*!re2c
        key = [a-z]+;
        val = [a-z]*;

        * { printf("error\n"); return; }

        (#k key "=" #v val ";" #e)* {
            const size_t n = k.size();
            for (size_t i = 0; i < n; ++i) {
                printf("%.*s = %.*s\n",
                    v[i] - k[i] - 1, k[i],
                    e[i] - v[i] - 1, v[i]);
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
