%{
#include <string>
%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]
DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
ID {LETRA}({LETRA}|{NUM})*

%%

"//".* { }
"/*"(.|\n)*?"*/" { }
"\n"           {}
{DELIM}        {}
"principal"    { yylval.label = "principal"; return TK_ID; }
"inteiro"      { return TK_TIPO_INT; }
"flutuante"    { return TK_TIPO_FLOAT; }
"caractere"    { return TK_TIPO_CHAR; }
"booleano"     { return TK_TIPO_BOOLEAN; }
"verdadeiro"   { yylval.label = "true"; return TK_TRUE; }
"falso"        { yylval.label = "false"; return TK_FALSE; }
"palavra"      { return TK_STRING; }
"se"           { return TK_IF; }
"senao"        { return TK_ELSE; }
"enquanto"     { return TK_WHILE; }
"fazer"        { return TK_DO; }
"para"         { return TK_FOR; }
"escolha"      { return TK_SWITCH; }
"encerrar"     { return TK_BREAK; }
"pular"        { return TK_CONTINUE; }
"caso"         { return TK_CASE; }
"padrao"       { return TK_DEFAULT; }
"ler"          { return TK_SCAN; }
"escrever"     { return TK_PRINT; }
"retornar"     { return TK_RETURN; }
"vazio"        { return TK_TIPO_VOID; }
"enumeracao"   { return TK_ENUM; }
[(){}[\];:,]   { return *yytext; }
[+\-*/]        { return *yytext; }
"<"            { return '<'; }
"<="           { return TK_MENOR_IGUAL; }
">"            { return '>'; }
">="           { return TK_MAIOR_IGUAL; }
"=="           { return TK_IGUAL_IGUAL; }
"!="           { return TK_DIFERENTE; }
"="            { return '='; }
"&&"           { return TK_AND; }
"||"           { return TK_OR; }
"!"            { return '!'; }
"+="           { return TK_MAIS_IGUAL; }
"-="           { return TK_MENOS_IGUAL; }
"*="           { return TK_MULT_IGUAL; }
"/="           { return TK_DIV_IGUAL; }
"++"           { return TK_INCREMENTO; }
"--"           { return TK_DECREMENTO; }
{NUM}          { yylval.label = yytext; return TK_NUM; }
{ID}           { yylval.label = yytext; return TK_ID; }
{REAL}         { yylval.label = yytext; return TK_FLOAT_VAL; }
{CHAR}         { yylval.label = yytext; return TK_CHAR_VAL; }

"\""[^"\n]*"\""   { yylval.label = yytext; return TK_STRING_VAL; }

.              { *yytext; }

%%
