%{
#include <iostream>
#include <string>
#include <sstream>
#include <set>
#include <map>
#include <stack>
#include <utility>
#include <vector>

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
int rotulos_qnt = 0;

set<string> variaveisNome;
set<string> variaveisTempNome;
stack<map<string, tab>> pilhaDeSimbolos;
map<string, tab> tabelaGeracao;
stack<pair<string, string>> pilhaDeRotulosLoop;
stack<string> switchVar;
stack<vector<pair<string, string>>> caseRotulos;
stack<string> defaultRotulos;

int yylex(void);
void yyerror(string);
void adicionarVariavel(string nome, string tipo);
tab buscarVariavel(string nome);
string gentempcode(string tipo);
string gentempcode2(string tipo);
string tipoResult(string tipo1, string tipo2);
string conversao(string var, string tipoOrigem, string tipoDest, string &codigo);
string gerarotulo();

%}

%token TK_NUM
%token TK_MAIN TK_ID
%token TK_FIM TK_ERROR
%token TK_TIPO_CHAR TK_TIPO_BOOLEAN TK_TIPO_INT TK_TIPO_FLOAT
%token TK_CHAR_VAL TK_INT_VAL TK_FLOAT_VAL
%token TK_TRUE TK_FALSE
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_IGUAL_IGUAL TK_DIFERENTE
%token TK_AND TK_OR 
%token TK_IF TK_ELSE TK_DO TK_WHILE TK_FOR TK_SWITCH TK_BREAK TK_CONTINUE TK_STRING TK_CASE TK_DEFAULT


%start S
%right UMINUS
%left '+' '-'
%left '*' '/'
%right '(' ')'

%%

    S : TK_TIPO_INT TK_MAIN '(' ')' BLOCO {
        string codigo = "/*Compilador CCP*/\n"
                        "#include <iostream>\n"
                        "#include <string.h>\n"
                        "#include <stdio.h>\n"
                        "int main(void) \n{\n";

        for (auto& par : tabelaGeracao) {
            if (variaveisNome.count(par.second.elemento)) {
                codigo += "\t" + par.second.tipo + " " + par.second.elemento + "; \t// var " + par.first + "\n";
            }
        } 

        for (auto& par : tabelaGeracao) {
            if (variaveisTempNome.count(par.second.elemento)) {
                codigo += "\t" + par.second.tipo + " " + par.second.elemento + ";\n";
            }
        }

        codigo += "\n";
        codigo += $5.traducao;
        codigo += "\treturn 0;\n}";
        cout << codigo << endl;
    };
    
    BLOCO : '{' 
    
            {
                map<string, tab> novoEscopo;
                pilhaDeSimbolos.push(novoEscopo);

            }
            COMANDOS '}' 
            {
            
                pilhaDeSimbolos.pop();
                $$.traducao = $3.traducao;
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
            adicionarVariavel($2.label, $1.label);
            $$.traducao = ""; 
        }
        | TIPO TK_ID '=' E ';' {
            adicionarVariavel($2.label, $1.label);
        
            tab infoVar = buscarVariavel($2.label);
            string nomeMem = infoVar.elemento;
            string tipoVar = infoVar.tipo;
       
            string tipoExpr = $4.tipoExp;
        
            string codConv = "";
            string valorFinalExpr = conversao($4.label, tipoExpr, tipoVar, codConv);

            $$.traducao = $4.traducao + codConv + "\t" + nomeMem + " = " + valorFinalExpr + ";\n";

            $$.tipoExp = ""; 
            $$.label = "";
        }
        | BLOCO {         
            $$ = $1;   
        }
        | TK_IF '(' E ')' COMANDO {
            if($3.tipoExp != "bool"){
                yyerror("Erro Semantico: A expressao do IF deve ser booleana.");
            }
            string rotulo_fim = gerarotulo();
            $$.traducao = $3.traducao;

            string tempNeg = gentempcode2("bool");
            $$.traducao += "\t" + tempNeg + " = !" + $3.label + ";\n";
            $$.traducao += "\tif (" + tempNeg + ") goto " + rotulo_fim + ";\n"; 
            $$.traducao += $5.traducao;
            $$.traducao += rotulo_fim + ":\n"; 
        }
        | TK_IF '(' E ')' COMANDO TK_ELSE COMANDO {
            if($3.tipoExp != "bool") {
                yyerror("Erro Semantico: A expressao do IF deve ser booleana.");
            }
            string rotulo_else = gerarotulo();
            string rotulo_fim = gerarotulo();
            $$.traducao = $3.traducao;

            string tempNeg = gentempcode2("bool");
            $$.traducao += "\t" + tempNeg + " = !" + $3.label + ";\n";
            $$.traducao += "\tif (" + tempNeg + ") goto " + rotulo_else + ";\n";
            $$.traducao += $5.traducao;
            $$.traducao += "\tgoto " + rotulo_fim + ";\n";
            $$.traducao += rotulo_else + ":\n";
            $$.traducao += $7.traducao;
            $$.traducao += rotulo_fim + ":\n";
        }
        | TK_WHILE '(' E ')' {
                string rotulo_inicio = gerarotulo();
                string rotulo_fim = gerarotulo();
                pilhaDeRotulosLoop.push({rotulo_inicio, rotulo_fim});

                $$.label = rotulo_inicio;
                $$.traducao = rotulo_fim;

            }
            COMANDO {
                if($3.tipoExp != "bool"){
                    yyerror("Erro Semantico: A expressao do WHILE deve ser booleana.");
                }
                string rotulo_inicio = $5.label;
                string rotulo_fim = $5.traducao;

                $$.traducao = rotulo_inicio + ":\n";
                $$.traducao += $3.traducao;

                string tempNeg = gentempcode2("bool");
                $$.traducao += "\t" + tempNeg + " = !" + $3.label + ";\n";
                $$.traducao += "\tif (" + tempNeg + ") goto " + rotulo_fim + ";\n";
                $$.traducao += $6.traducao;
                $$.traducao += "\tgoto " + rotulo_inicio + ";\n";
                $$.traducao += rotulo_fim + ":\n";

                pilhaDeRotulosLoop.pop();
            }
        | TK_DO {
                string rotulo_inicio = gerarotulo();
                string rotulo_continue = gerarotulo();
                string rotulo_fim = gerarotulo();
            
                pilhaDeRotulosLoop.push({rotulo_continue, rotulo_fim});

                $$.label = rotulo_inicio;
                $$.traducao = rotulo_continue;
                $$.tipoExp = rotulo_fim;
            
            }
            COMANDO TK_WHILE '(' E ')' ';'{
                if($6.tipoExp != "bool"){
                    yyerror("Erro Semantico: A expressao do DO/WHILE deve ser booleana.");
                }
                string rotulo_inicio = $2.label;
                string rotulo_continue = $2.traducao;
                string rotulo_fim = $2.tipoExp;
            
                $$.traducao = rotulo_inicio + ":\n";
                $$.traducao += $3.traducao;
                $$.traducao += rotulo_continue + ":\n";
                $$.traducao += $6.traducao;

                string tempNeg = gentempcode2("bool");
                $$.traducao += "\t" + tempNeg + " = !" + $6.label + ";\n";
                $$.traducao += "\tif (" + tempNeg + ") goto " + rotulo_fim + ";\n";
                $$.traducao += "\tgoto " + rotulo_inicio + ";\n";
                $$.traducao += rotulo_fim + ":\n";

                pilhaDeRotulosLoop.pop();
            }
        | TK_FOR '(' E_OPC ';' {
                string rotulo_cond = gerarotulo();
                string rotulo_inc = gerarotulo();
                string rotulo_fim = gerarotulo();

                pilhaDeRotulosLoop.push({rotulo_inc, rotulo_fim}); 
                
                $$.label = rotulo_cond;
                $$.traducao = rotulo_inc;
                $$.tipoExp = rotulo_fim;
            }

            E_OPC ';' E_OPC ')' COMANDO {
                if($6.tipoExp != "bool" && $6.label != ""){
                    yyerror("Erro Semantico: A expressao de condicao do FOR deve ser booleana.");
                }
                string rotulo_cond = $5.label;
                string rotulo_inc = $5.traducao;
                string rotulo_fim = $5.tipoExp;

                $$.traducao = $3.traducao;
                $$.traducao += rotulo_cond + ":\n";
                $$.traducao += $6.traducao;

                if ($6.label != "") {
                    string tempNeg = gentempcode2("bool");
                    $$.traducao += "\t" + tempNeg + " = !" + $6.label + ";\n";
                    $$.traducao += "\tif (" + tempNeg + ") goto " + rotulo_fim + ";\n";
                }

                $$.traducao += $10.traducao;
                $$.traducao += rotulo_inc + ":\n";
                $$.traducao += $8.traducao;
                $$.traducao += "\tgoto " + rotulo_cond + ";\n";
                $$.traducao += rotulo_fim + ":\n";

                pilhaDeRotulosLoop.pop();
            }
        | TK_BREAK ';' {
            if (pilhaDeRotulosLoop.empty()) {
                yyerror("Erro Semantico: 'encerrar' (break) fora de um loop.");
            }
            string rotulo_fim = pilhaDeRotulosLoop.top().second;
            $$.traducao = "\tgoto " + rotulo_fim + ";\n";
        }
        | TK_CONTINUE ';' {
            if (pilhaDeRotulosLoop.empty()) {
                yyerror("Erro Semantico: 'pular' (continue) fora de um loop.");
            }
            string rotulo_inicio = pilhaDeRotulosLoop.top().first;
            $$.traducao = "\tgoto " + rotulo_inicio + ";\n";
        }
        | INICIO_SWITCH BLOCO_CASES {
           
            string codigo_saltos = "";
        
            string var = switchVar.top(); switchVar.pop();
            vector<pair<string, string>> cases = caseRotulos.top(); caseRotulos.pop();
            string rotulo_default = defaultRotulos.top(); defaultRotulos.pop();
            
            string rotulo_fim_switch = $1.label;
            pilhaDeRotulosLoop.pop();
            
            for (const auto& caso : cases) {
                codigo_saltos += "\tif (" + var + " == " + caso.first + ") goto " + caso.second + ";\n";
            }
            
            if (!rotulo_default.empty()) {
                codigo_saltos += "\tgoto " + rotulo_default + ";\n";
            } else {
                codigo_saltos += "\tgoto " + rotulo_fim_switch + ";\n";
            }
            
            $$.traducao = $1.traducao + codigo_saltos + $2.traducao + rotulo_fim_switch + ":\n";
        }
        ;

    INICIO_SWITCH
        : TK_SWITCH '(' E ')' {
       
            if ($3.tipoExp == "float") {
            yyerror("Erro Semantico: Expressao do switch nao pode ser do tipo flutuante.");
            }
    
            string rotulo_fim = gerarotulo();
        
            pilhaDeRotulosLoop.push({"", rotulo_fim});
        
            switchVar.push($3.label);
            caseRotulos.push({});
            defaultRotulos.push("");
        
            $$.traducao = $3.traducao;
            $$.label = rotulo_fim;
        }
    ;
    BLOCO_CASES
        : '{' LISTA_CASOS '}' {
       
            $$.traducao = $2.traducao;
        }
    ;

    LISTA_CASOS
        : LISTA_CASOS ITEM_CASE {
            $$.traducao = $1.traducao + $2.traducao;
    }
    | {
        $$.traducao = "";
        }
    ;

    ITEM_CASE
        : TK_CASE CONSTANTE ':' COMANDOS {
        
            string rotulo_case = gerarotulo();
        
            caseRotulos.top().push_back(make_pair($2.label, rotulo_case));
        
            $$.traducao = rotulo_case + ":\n" + $4.traducao;
        }
        | TK_DEFAULT ':' COMANDOS {
        
            if (!defaultRotulos.top().empty()) {
                yyerror("Erro Semantico: Multiplos 'default' no mesmo switch.");
        }
            string rotulo_default = gerarotulo();
            defaultRotulos.top() = rotulo_default;
        
            $$.traducao = rotulo_default + ":\n" + $3.traducao;
        }
    ;   
    CONSTANTE
        : TK_NUM { $$ = $1; }
        | TK_CHAR_VAL { $$ = $1; }
;
        
    TIPO
        : TK_TIPO_INT     { $$.label = "int"; $$.tipoExp = "int";}
        | TK_TIPO_FLOAT   { $$.label = "float"; $$.tipoExp = "float"; }
        | TK_TIPO_CHAR    { $$.label = "char"; $$.tipoExp = "char"; }
        | TK_TIPO_BOOLEAN { $$.label = "bool"; $$.tipoExp = "bool"; };
    
    E_OPC
        : E { $$ = $1; }
        |   { $$.traducao = ""; $$.label = ""; $$.tipoExp = ""; }
        ;

    E
        : E '+' E {
            string tipoEsq = $1.tipoExp;
            string tipoDir = $3.tipoExp;
            
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " + " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | E '-' E {
            string tipoEsq = $1.tipoExp;
            string tipoDir = $3.tipoExp;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " - " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | E '*' E {
            string tipoEsq = $1.tipoExp;
            string tipoDir = $3.tipoExp;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " * " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | E '/' E {
            string tipoEsq = $1.tipoExp;
            string tipoDir = $3.tipoExp;
            string tipoTemp = tipoResult(tipoEsq, tipoDir);
           
            string codConv = "";

            string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
            string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);

            $$.label = gentempcode(tipoTemp);
            $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " / " + dirConv + ";\n";
            $$.tipoExp = tipoTemp;
        }
        | '-' E %prec UMINUS {
            if ($2.tipoExp != "int" && $2.tipoExp != "float") {
                yyerror("Erro Semantico: Operador unario '-' so pode ser aplicado a tipos numericos (int, float).");
            }
            $$.tipoExp = $2.tipoExp;
            $$.label = gentempcode($$.tipoExp);
            $$.traducao = $2.traducao + "\t" + $$.label + " = -" + $2.label + ";\n";
        }
        | '(' E ')' {
            $$ = $2;
        }
		| E '<' E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " < " + $3.label + ";\n";
            
            if($1.tipoExp != $3.tipoExp) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            
            $$.tipoExp = "bool";
        }
		| E TK_MENOR_IGUAL E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " <= " + $3.label + ";\n";
            if($1.tipoExp != $3.tipoExp) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E '>' E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " > " + $3.label + ";\n";
            if($1.tipoExp != $3.tipoExp) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_MAIOR_IGUAL E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " >= " + $3.label + ";\n";
            if($1.tipoExp != $3.tipoExp) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_IGUAL_IGUAL E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " == " + $3.label + ";\n";
            if($1.tipoExp != $3.tipoExp) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
            $$.tipoExp = "bool";
        }
		| E TK_DIFERENTE E {
            $$.label = gentempcode2("bool");
            $$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " != " + $3.label + ";\n";
            if($1.tipoExp != $3.tipoExp) yyerror("Erro de sintaxe: Nao podemos utilizar operadores relacionais com tipos diferentes");
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
            tab infoVar = buscarVariavel(nomeVar);
            string nomeMem = infoVar.elemento;    
            string tipoVar = infoVar.tipo;
            string tipoExpr = $3.tipoExp;

            if(tipoVar == "bool") tipoVar = "int";
            if(tipoExpr == "bool") tipoExpr = "int";

            if (tipoVar != tipoExpr) {
               cout << "Warning: Tipos incompatíveis na atribuição!" << endl;
            }
            $$.traducao = $3.traducao + "\t" + nomeMem + " = " + $3.label + ";\n";

            $$.tipoExp = ""; 
            $$.label = "";

        }
        | TK_NUM {
            $$.label = gentempcode("int");
            $$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
            $$.tipoExp = "int";
        }
        | TK_ID {
            
            tab infoVar = buscarVariavel($1.label);
        
            string nomeMem = infoVar.elemento;
        
            $$.label = gentempcode(infoVar.tipo);
            $$.traducao = "\t" + $$.label + " = " + nomeMem + ";\n";
            $$.tipoExp = infoVar.tipo;
        }
        | '(' TIPO ')' E {
            string tipoOrigem = $4.tipoExp;
            string tipoDest = $2.tipoExp;

            string codConv = "";
            string convertido = conversao($4.label, tipoOrigem, tipoDest, codConv);

            $$.label = convertido;
            $$.traducao = $4.traducao + codConv;
            $$.tipoExp = tipoDest;

            
        }

%%

#include "lex.yy.c"

int yyparse();

void adicionarVariavel(string nome, string tipo) {
    
    if (pilhaDeSimbolos.top().count(nome)) {
        yyerror("Erro: A variavel '" + nome + "' ja foi declarada.");
        return;
    }
    
    string nomeMem = "v" + to_string(var_qnt++);
    pilhaDeSimbolos.top()[nome] = { tipo, nomeMem };
    tabelaGeracao[nome] = { tipo, nomeMem };
    variaveisNome.insert(nomeMem);
    
}

tab buscarVariavel(string nome) {
   
    stack<map<string, tab>> tempStack = pilhaDeSimbolos;
    
    while (!tempStack.empty()) {
        map<string, tab> escopoAtual = tempStack.top();
        if (escopoAtual.count(nome)) {
          
            return escopoAtual.at(nome);
        }
        tempStack.pop(); 
    }
    
  
    yyerror("Erro Semantico: Variavel '" + nome + "' nao foi declarada.");
    return {"error", "error"}; 
}

string gentempcode(string tipo) {
    while (true) {
        string nomeTemp = "t" + to_string(var_temp_qnt++);
        if (!tabelaGeracao.count(nomeTemp)) { 
            variaveisTempNome.insert(nomeTemp);
            tabelaGeracao[nomeTemp] = { tipo, nomeTemp };
            return nomeTemp;
        }
    }
}

string gentempcode2(string tipo) {
    if(tipo == "bool") tipo = "int";
    while (true) {
        string nomeTemp = "t" + to_string(var_temp_qnt++);
        if (!tabelaGeracao.count(nomeTemp)) {
            variaveisTempNome.insert(nomeTemp);
            tabelaGeracao[nomeTemp] = { tipo, nomeTemp };
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

string gerarotulo(){
    return "R" + to_string(rotulos_qnt++);
}

int main(int argc, char* argv[]) {
    var_temp_qnt = 0;
    
    map<string, tab> escopoGlobal;
    pilhaDeSimbolos.push(escopoGlobal);

    yyparse();
    return 0;
}

void yyerror(string MSG) {
    cout << MSG << endl;
    exit(0);
}
