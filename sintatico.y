%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <map>

#define YYSTYPE atributos
using namespace std;

struct atributos {
    string label;
    string traducao;
    string tipoExp;
};

struct tab {
    string tipo;
    string elemento;
};

int var_qnt = 0; 
int var_temp_qnt = 0;
set<string> variaveisNome;
set<string> variaveisTempNome;
map<string, tab> tabelaSimbolos;



int yylex(void);
void yyerror(string);
void adicionarVariavel(string nome, string tipo);
string gentempcode(string tipo);
string gentempcode2(string tipo);
string tipoResult(string tipo1, string tipo2);
string conversao(string var, string tipoOrigem, string tipoDest, string &codigo);
%}

%token TK_NUM
%token TK_MAIN TK_ID
%token TK_FIM TK_ERROR
%token TK_TIPO_CHAR TK_TIPO_BOOLEAN TK_TIPO_INT TK_TIPO_FLOAT
%token TK_CHAR_VAL TK_INT_VAL TK_FLOAT_VAL
%token TK_TRUE TK_FALSE
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_IGUAL_IGUAL TK_DIFERENTE
%token TK_AND TK_OR 
%token TK_IF TK_ELSE TK_DO TK_WHILE TK_FOR TK_SWITCH TK_BREAK TK_CONTINUE TK_STRING TK_CASE


%start S
%left '+' '-'
%left '*' '/'
%right '(' ')'

%%

    S : TK_TIPO_INT TK_MAIN '(' ')' BLOCO {
        string codigo = "/*Compilador CCP*/\n"
                        "#include <iostream>\n"
                        "#include <string.h>\n"
                        "#define true 1\n"
                        "#define false 0\n"
                        "#include <stdio.h>\n"
                        "int main(void) \n{\n";

        for (auto& par : tabelaSimbolos) {
            if (variaveisNome.count(par.second.elemento)) {
                codigo += "\t" + par.second.tipo + " " + par.second.elemento + ";   --> " + par.first + "\n";
            } else {
                codigo += "\t" + par.second.tipo + " " + par.second.elemento + ";\n";
            }
        }

        codigo += "\n";
        codigo += $5.traducao;
        codigo += "\treturn 0;\n}";
        cout << codigo << endl;
    };
    
    BLOCO : '{' COMANDOS '}' {
        $$.traducao = $2.traducao;
    };
    
    COMANDOS
        : COMANDO COMANDOS {
            $$.traducao = $1.traducao + $2.traducao;
        }
        | {
            $$.traducao = "";
        };
    
    COMANDO
        : E ';' {
            $$ = $1;
        }
        | TIPO TK_ID ';' {
       		 if (tabelaSimbolos.count($2.label)) {
            	cout << "Erro: Variável '" << $2.label << "' já foi declarada." << endl;
            	exit(1);
        }
        	adicionarVariavel($2.label, $1.label);
        	$$.traducao = ""; 
    };
    
    TIPO
        : TK_TIPO_INT     { $$.label = "int"; $$.tipoExp = "int";}
        | TK_TIPO_FLOAT   { $$.label = "float"; $$.tipoExp = "float"; }
        | TK_TIPO_CHAR    { $$.label = "char"; $$.tipoExp = "char"; }
        | TK_TIPO_BOOLEAN { $$.label = "bool"; $$.tipoExp = "bool"; };
    
    E
        : E '+' E {
            string tipoEsq = tabelaSimbolos[$1.label].tipo;
            string tipoDir = tabelaSimbolos[$3.label].tipo;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " + " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | E '-' E {
            string tipoEsq = tabelaSimbolos[$1.label].tipo;
            string tipoDir = tabelaSimbolos[$3.label].tipo;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " - " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | E '*' E {
            string tipoEsq = tabelaSimbolos[$1.label].tipo;
            string tipoDir = tabelaSimbolos[$3.label].tipo;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " * " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | E '/' E {
            string tipoEsq = tabelaSimbolos[$1.label].tipo;
            string tipoDir = tabelaSimbolos[$3.label].tipo;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " / " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | '(' E ')' {
            $$ = $2;
        }
		| E '<' E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " < " + $3.label + ";\n";
            if(tabelaSimbolos[$1.label].tipo != tabelaSimbolos[$3.label].tipo) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_MENOR_IGUAL E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " <= " + $3.label + ";\n";
            if(tabelaSimbolos[$1.label].tipo != tabelaSimbolos[$3.label].tipo) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E '>' E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " > " + $3.label + ";\n";
            if(tabelaSimbolos[$1.label].tipo != tabelaSimbolos[$3.label].tipo) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_MAIOR_IGUAL E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " >= " + $3.label + ";\n";
            if(tabelaSimbolos[$1.label].tipo != tabelaSimbolos[$3.label].tipo) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_IGUAL_IGUAL E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " == " + $3.label + ";\n";
            if(tabelaSimbolos[$1.label].tipo != tabelaSimbolos[$3.label].tipo) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_DIFERENTE E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " != " + $3.label + ";\n";
            if(tabelaSimbolos[$1.label].tipo != tabelaSimbolos[$3.label].tipo) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_AND E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " && " + $3.label + ";\n";
            $$.tipoExp = "bool";
		}
		| E TK_OR E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " || " + $3.label + ";\n";
            $$.tipoExp = "bool";
		}
		| '!' E {
            $$.label = gentempcode2("bool");
            $$.traducao = $2.traducao + "\t" + $$.label + " = !" + $2.label + ";\n";
            $$.tipoExp = "bool";
		}
    	|TK_FLOAT_VAL{
    		$$.label = gentempcode("float");
       		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
            $$.tipoExp = "float";
    	}
    
        |TK_CHAR_VAL{
    		$$.label = gentempcode("char");
       		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
            $$.tipoExp = "char";
        }

        |TK_TRUE{
    		$$.label = gentempcode2("bool");
       		$$.traducao = "\t" + $$.label + " = 1;\n";
            $$.tipoExp = "bool";
        }
        |TK_FALSE{
    		$$.label = gentempcode2("bool");
       		$$.traducao = "\t" + $$.label + " = 0;\n";
            $$.tipoExp = "bool";
        }

        | TK_ID '=' E {
            string nomeVar = $1.label;
            
            if (!tabelaSimbolos.count(nomeVar)) {
                adicionarVariavel(nomeVar, $3.tipoExp);
            }
            string nomeMem = tabelaSimbolos[nomeVar].elemento;
            string tipoVar = tabelaSimbolos[nomeVar].tipo;
            string tipoExpr = $3.tipoExp;

            if(tipoVar == "bool") tipoVar = "int";
            if(tipoExpr == "bool") tipoExpr = "int";

            if (tipoVar != tipoExpr) {
               cout << "Erro: Tipos incompatíveis na atribuição!" << endl;
            }
            $$.traducao = $1.traducao + $3.traducao + "\t" + nomeMem + " = " + $3.label + ";\n";
        }
        | TK_NUM {
            $$.label = gentempcode("int");
            $$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
            $$.tipoExp = "int";
        }
        | TK_ID {
            
            if (!tabelaSimbolos.count($1.label)) {
                adicionarVariavel($1.label, "int");
            }
            string nomeMem = tabelaSimbolos[$1.label].elemento;
            string tipo = tabelaSimbolos[$1.label].tipo;
            $$.label = gentempcode(tipo);
            $$.traducao = "\t" + $$.label + " = " + nomeMem + ";\n";
            $$.tipoExp = tipo;
        }
        | '(' TIPO ')' E {
            string tipoOrigem = tabelaSimbolos[$4.label].tipo;
            string tipoDest = $2.tipoExp;

            string codConv = "";
            string convertido = conversao($4.label, tipoOrigem, tipoDest, codConv);

            $$.label = convertido;
            $$.traducao = $4.traducao + codConv;

            tabelaSimbolos[$$.label].tipo = tipoDest;
        }

%%

#include "lex.yy.c"

int yyparse();

void adicionarVariavel(string nome, string tipo) {
    string nomeMem = "v" + to_string(var_qnt++);
    tabelaSimbolos[nome] = { tipo, nomeMem };
    variaveisNome.insert(nomeMem);
    
}

string gentempcode(string tipo) {
    while (true) {
        string nomeTemp = "t" + to_string(var_temp_qnt++);
        if (!tabelaSimbolos.count(nomeTemp)) { 
            variaveisTempNome.insert(nomeTemp);
            tabelaSimbolos[nomeTemp] = { tipo, nomeTemp };
            return nomeTemp;
        }
    }
}

string gentempcode2(string tipo) {
    if(tipo == "bool") tipo = "int";
    while (true) {
        string nomeTemp = "t" + to_string(var_temp_qnt++);
        if (!tabelaSimbolos.count(nomeTemp)) {
            variaveisTempNome.insert(nomeTemp);
            tabelaSimbolos[nomeTemp] = { tipo, nomeTemp };
            return nomeTemp;
        }
    }
}

string tipoResult(string tipo1, string tipo2){
    if(tipo1 == "bool" || tipo2 == "bool"){
        yyerror("Erro de sintaxe: Não podemos fazer operação com boolean");
        return "";
    }
    else if(tipo1 == "float" || tipo2 == "float") return "float";
    else if(tipo1 == "int" || tipo2 == "int") return "int";
    else if(tipo1 == "char" || tipo2 == "char") return "char";
    else return "int";
}

string conversao(string var, string tipoOrigem, string tipoDest, string &codigo){
    if(tipoOrigem == tipoDest) return var;

    string temp = gentempcode(tipoDest);
    codigo += "\t" + temp + " = (" + tipoDest + ") " + var + ";\n";
    return temp;
}

int main(int argc, char* argv[]) {
    var_temp_qnt = 0;
    yyparse();
    return 0;
}

void yyerror(string MSG) {
    cout << MSG << endl;
    exit(0);
}
