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
    vector<atributos> listaArgs;
    vector<int> listaDimensoes;
    vector<string> listaNomes;
};

struct tab {
    string tipo;
    string elemento;
    string categoria;  
    vector<string> paramTipos;
    vector<int> dimensoes;
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
set<string> stringsAlocados;

map<string, string> funcoesGeradas; 
string funcaoAtual = "";
map<string, tab> func_vars;


int yylex(void);
void yyerror(string);
void adicionarVariavel(string nome, string tipo, const vector<int>& dimensoes);
void adicionarParametro(string nome, string tipo);
void adicionarFuncao(string nome, string tipoRetorno, vector<string> tiposParams);
tab buscarSimbolo(string nome);
string gentempcode(string tipo);
string gentempcode2(string tipo);
string tipoResult(string tipo1, string tipo2);
string conversao(string var, string tipoOrigem, string tipoDest, string &codigo);
string gerarotulo();


%}

%token TK_NUM
%token TK_ENUM
%token TK_MAIN TK_ID
%token TK_FIM TK_ERROR
%token TK_TIPO_CHAR TK_TIPO_BOOLEAN TK_TIPO_INT TK_TIPO_FLOAT
%token TK_CHAR_VAL TK_INT_VAL TK_FLOAT_VAL
%token TK_TRUE TK_FALSE
%token TK_MENOR_IGUAL TK_MAIOR_IGUAL TK_IGUAL_IGUAL TK_DIFERENTE
%token TK_AND TK_OR 
%token TK_IF TK_ELSE TK_DO TK_WHILE TK_FOR TK_SWITCH TK_BREAK TK_CONTINUE TK_STRING TK_STRING_VAL TK_CASE TK_DEFAULT
%token TK_SCAN TK_PRINT
%token TK_RETURN
%token TK_TIPO_VOID
%token TK_MAIS_IGUAL TK_MENOS_IGUAL TK_MULT_IGUAL TK_DIV_IGUAL
%token TK_INCREMENTO TK_DECREMENTO


%start S
%right UMINUS TK_INCREMENTO TK_DECREMENTO
%left '+' '-'
%left '*' '/'
%right '(' ')'

%%

    S : DECLARACOES_GLOBAIS {
        
        if (funcoesGeradas.find("principal") == funcoesGeradas.end()) {
            yyerror("Erro Semantico: Funcao 'principal' nao definida.");
        }

        string codigo = "/*Compilador CCP*/\n"
                        "#include <iostream>\n"
                        "#include <string.h>\n"
                        "#include <stdio.h>\n"
                        "#include <stdlib.h>\n\n";

        string tamanhoString3end = "int tamanhoString(char* v0) {\n"
            "\tint v1;\n"
            "\tint t1;\n\tint t2;\n\tint t3;\n\tint t4;\n\tint t5;\n\tint t7;\n\tint t8;\n\tint t9;\n\tint t10;\n\tint t11;\n"
            "\tchar t6;\n\n"
            "\tt1 = (v0 == NULL);\n"
            "\tt2 = !t1;\n"
            "\tif (t2) goto R0;\n\n"
            "\tt3 = 0;\n"
            "\treturn t3;\n\n"
            "R0:\n"
            "\tt4 = 0;\n"
            "\tv1 = t4;\n\n"
            "R1:\n"
            "\tt5 = v1;\n"
            "\tt6 = v0[t5];\n"
            "\tt7 = (t6 != '\\0');\n"
            "\tt8 = !t7;\n"
            "\tif (t8) goto R2;\n\n"
            "\tt9 = v1;\n"
            "\tt10 = t9 + 1;\n"
            "\tv1 = t10;\n"
            "\tgoto R1;\n\n"
            "R2:\n"
            "\tt11 = v1;\n"
            "\treturn t11;\n"
            "}\n\n";

        codigo += tamanhoString3end;

        for (auto const& [nome, codigo_func] : funcoesGeradas) {
            if (nome != "principal") {
                codigo += codigo_func;
            }
        }

        if (funcoesGeradas.count("principal")) {
            codigo += funcoesGeradas.at("principal");
        }

        cout << codigo << endl;
    };

    DECLARACOES_GLOBAIS
    : DEFINICAO_FUNCAO DECLARACOES_GLOBAIS
    | DEFINICAO_ENUM DECLARACOES_GLOBAIS // <-- ADICIONE ESTA LINHA
    |
    ;

    /*LISTA_FUNCOES
        : DEFINICAO_FUNCAO LISTA_FUNCOES
        | 
        ;*/
    DEFINICAO_ENUM
    : TK_ENUM TK_ID '{' LISTA_MEMBROS_ENUM '}' ';' {
        // Esta é a ação semântica principal!
        // Vamos popular a tabela de símbolos aqui.
        int contador = 0;
        for (const string& nome_membro : $4.listaNomes) {
            // Adiciona cada membro como uma constante inteira global
            if (pilhaDeSimbolos.top().count(nome_membro)) {
                yyerror("Erro Semantico: Simbolo '" + nome_membro + "' ja foi declarado neste escopo.");
            }
            // Adicionamos na tabela do topo (global)
            pilhaDeSimbolos.top()[nome_membro] = { "int", to_string(contador), "constante" };
            contador++;
        }
        $$.traducao = ""; // A definição de um enum não gera código C diretamente
    }
    ;
    LISTA_MEMBROS_ENUM
        : TK_ID {
            $$.listaNomes.push_back($1.label);
        }
        | LISTA_MEMBROS_ENUM ',' TK_ID {
            $$.listaNomes = $1.listaNomes;
            $$.listaNomes.push_back($3.label);
        }
        ;

    DEFINICAO_FUNCAO
        : TIPO TK_ID '(' PARAMS ')' {
            funcaoAtual = $2.label;
            vector<string> tiposParams;
            for(const auto& p_attr : $4.listaArgs) {
                tiposParams.push_back(p_attr.tipoExp);
            }
            adicionarFuncao(funcaoAtual, $1.tipoExp, tiposParams);

            map<string, tab> novoEscopo;
            pilhaDeSimbolos.push(novoEscopo);

            func_vars.clear();

            string params_c;
            for(const auto& p_attr : $4.listaArgs) {
                adicionarParametro(p_attr.label, p_attr.tipoExp);
                if (!params_c.empty()) params_c += ", ";
                params_c += p_attr.tipoExp + " " + buscarSimbolo(p_attr.label).elemento;
            }

            if ($1.tipoExp == "int" && funcaoAtual == "principal") {
                $$.label = "int main(void)"; 
            } else {
                $$.label = $1.tipoExp + " " + funcaoAtual + "(" + params_c + ")";
            }
        }
        BLOCO {
            string nomeFuncao = funcaoAtual;

            string vars_locais = "";
            for (auto const& [nome, info] : func_vars) {
                 if (!info.dimensoes.empty()) { 
                    int tamanho_total = 1;
                    for (int d : info.dimensoes) {
                        tamanho_total *= d;
                    }
                    vars_locais += "\t" + info.tipo + " " + info.elemento + "[" + to_string(tamanho_total) + "];";
                } else if (info.tipo == "string") {
                    vars_locais += "\tchar* " + info.elemento + " = NULL;";
                } else if (info.tipo != "void") {
                    vars_locais += "\t" + info.tipo + " " + info.elemento + ";";
                }

                if (info.categoria == "var") {
                    vars_locais += " // var " + nome;
                }
                vars_locais += "\n";
            }

            string codigo_funcao = $6.label + "\n{\n" + vars_locais + "\n" + $7.traducao;

            if (nomeFuncao == "principal" && codigo_funcao.find("return") == string::npos) {
                codigo_funcao += "\n\treturn 0;\n";
            }
            codigo_funcao += "}\n\n";

            funcoesGeradas[nomeFuncao] = codigo_funcao;

            pilhaDeSimbolos.pop();
            funcaoAtual = ""; 
        };

    PARAMS
        : LISTA_PARAMS { $$ = $1; }
        | { $$.listaArgs.clear(); }
        ;

    LISTA_PARAMS
        : PARAM { $$.listaArgs.push_back($1); }
        | LISTA_PARAMS ',' PARAM {
            $$.listaArgs = $1.listaArgs;
            $$.listaArgs.push_back($3);
        }
        ;

    PARAM
        : TIPO TK_ID {
            $$.label = $2.label;
            $$.tipoExp = $1.tipoExp;
        }
        ;

    
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
            adicionarVariavel($2.label, $1.tipoExp, {});
            $$.traducao = ""; 
        }
        | TIPO TK_ID LISTA_DIMENSOES ';' {
            for(int d : $3.listaDimensoes) {
                if (d <= 0) yyerror("Erro Semantico: Dimensao da matriz deve ser positiva.");
            }
            adicionarVariavel($2.label, $1.tipoExp, $3.listaDimensoes);
            $$.traducao = "";
        }
        | TIPO TK_ID '[' TK_NUM ']' '=' '{' LISTA_VALORES '}' ';' {
            string nomeVar = $2.label;
            string tipoVar = $1.tipoExp;
            int tamanho = stoi($4.label);

            if (tamanho != $8.listaArgs.size()) {
                yyerror("Erro Semantico: O numero de inicializadores nao corresponde ao tamanho da matriz '" + nomeVar + "'.");
            }

            adicionarVariavel(nomeVar, tipoVar, {tamanho});
            tab infoVar = buscarSimbolo(nomeVar);
            string nomeMem = infoVar.elemento;

            string codigo_inicializacao = $8.traducao; 
            for (int i = 0; i < tamanho; ++i) {
                atributos arg = $8.listaArgs[i];
                if (arg.tipoExp != tipoVar) {
                    cout << "Warning: Tipo do inicializador " << i << " incompátivel com o tipo da matriz " << nomeVar << endl;
                }
                codigo_inicializacao += "\t" + nomeMem + "[" + to_string(i) + "] = " + arg.label + ";\n";
            }
            $$.traducao = codigo_inicializacao;
        }

        | TIPO TK_ID '=' E ';' {
            adicionarVariavel($2.label, $1.tipoExp, {});
        
            tab infoVar = buscarSimbolo($2.label);
            string nomeMem = infoVar.elemento;
            string tipoVar = infoVar.tipo;
       
            string tipoExpr = $4.tipoExp;
        
            if (tipoVar == "string" && tipoExpr == "string") {
                string temp_len = gentempcode("int");
                string temp_size = gentempcode("int");

                $$.traducao = $4.traducao;
                $$.traducao += "\t" + temp_len + " = tamanhoString(" + $4.label + ");\n";
                $$.traducao += "\t" + temp_size + " = " + temp_len + " + 1;\n";
                $$.traducao += "\t" + nomeMem + " = (char*) malloc(" + temp_size + ");\n";
                $$.traducao += "\tstrcpy(" + nomeMem + ", " + $4.label + ");\n";
                stringsAlocados.insert(nomeMem);
            } else {
                string codConv = "";
                string valorFinalExpr = conversao($4.label, tipoExpr, tipoVar, codConv);
                $$.traducao = $4.traducao + codConv + "\t" + nomeMem + " = " + valorFinalExpr + ";\n";
            }

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
        | TK_PRINT '(' E ')' ';' { 
            if ($3.tipoExp.empty() || $3.tipoExp == "void") {
                yyerror("Erro Semantico: Nao e possivel imprimir um valor vazio ou void.");
            }
            string formato;
        
            if ($3.tipoExp == "int")         formato = "\"%d\\n\"";
            else if ($3.tipoExp == "float")  formato = "\"%f\\n\"";
            else if ($3.tipoExp == "char")   formato = "\"%c\\n\"";
            else if ($3.tipoExp == "string") formato = "\"%s\\n\"";
            else if ($3.tipoExp == "bool")   formato = "\"%d\\n\""; 

            $$.traducao = $3.traducao + "\tprintf(" + formato + ", " + $3.label + ");\n";
        }
        | TK_SCAN '(' TK_ID ')' ';' {  
            tab infoVar = buscarSimbolo($3.label);
            string formato;
            string endereco = "&" + infoVar.elemento;
        
            if (infoVar.tipo == "int")        formato = "\"%d\"";
            else if (infoVar.tipo == "float") formato = "\"%f\"";
            else if (infoVar.tipo == "char")  formato = "\" %c\""; 
        
            if (infoVar.tipo == "string") {
                string bufferSize = "256"; 
                $$.traducao  = "\t" + infoVar.elemento + " = (char*) malloc(" + bufferSize + ");\n";
                $$.traducao += "\tscanf(\"%255s\", " + infoVar.elemento + ");\n"; 
                stringsAlocados.insert(infoVar.elemento); 
            } else {
                $$.traducao = "\tscanf(" + formato + ", " + endereco + ");\n";
            }
        }
        | TK_RETURN E ';' {
            if (funcaoAtual.empty()) {
                yyerror("Erro Semantico: 'return' fora de uma funcao.");
            }
            tab infoFuncao = buscarSimbolo(funcaoAtual);
            if (infoFuncao.tipo != $2.tipoExp && !(infoFuncao.tipo == "float" && $2.tipoExp == "int")) {
                yyerror("Erro Semantico: Tipo de retorno (" + $2.tipoExp + ") incompativel com o tipo da funcao (" + infoFuncao.tipo + ") '" + funcaoAtual + "'.");
            }
            $$.traducao = $2.traducao + "\treturn " + $2.label + ";\n";
        }
        | TK_RETURN ';' { 
            if (funcaoAtual.empty()) {
                yyerror("Erro Semantico: 'return' fora de uma funcao.");
            }
            tab infoFuncao = buscarSimbolo(funcaoAtual);
            if (infoFuncao.tipo != "void") {
                yyerror("Erro Semantico: 'return' sem valor em funcao que nao e void.");
            }
            $$.traducao = "\treturn;\n";
        }
        ;

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
        | TK_TIPO_BOOLEAN { $$.label = "bool"; $$.tipoExp = "bool"; }
        | TK_STRING       { $$.label = "string"; $$.tipoExp = "string"; };
        | TK_TIPO_VOID    { $$.label = "void";   $$.tipoExp = "void";   }

    
    E_OPC
        : E { $$ = $1; }
        |   { $$.traducao = ""; $$.label = ""; $$.tipoExp = ""; }
        ;

    E
        : E '+' E {
            string tipoEsq = $1.tipoExp;
            string tipoDir = $3.tipoExp;
            
            if (tipoEsq == "string" || tipoDir == "string") {
                if (tipoEsq != "string" || tipoDir != "string") {
                    yyerror("Erro Semantico: Concatenacao de string com outro tipo nao e permitida.");
                }
                $$.tipoExp = "string";
                $$.label = gentempcode("string"); 
                string temp_len1 = gentempcode("int");
                string temp_len2 = gentempcode("int");
                string temp_total_len = gentempcode("int");
                string temp_size = gentempcode("int");

                $$.traducao = $1.traducao + $3.traducao;
                $$.traducao += "\t" + temp_len1 + " = tamanhoString(" + $1.label + ");\n";
                $$.traducao += "\t" + temp_len2 + " = tamanhoString(" + $3.label + ");\n";
                $$.traducao += "\t" + temp_total_len + " = " + temp_len1 + " + " + temp_len2 + ";\n";
                $$.traducao += "\t" + temp_size + " = " + temp_total_len + " + 1;\n";
                $$.traducao += "\t" + $$.label + " = (char*) malloc(" + temp_size + ");\n";
                $$.traducao += "\tstrcpy(" + $$.label + ", " + $1.label + ");\n";
                $$.traducao += "\tstrcat(" + $$.label + ", " + $3.label + ");\n";
                stringsAlocados.insert($$.label);
            } else { 
                string tipoTemp = tipoResult(tipoEsq, tipoDir);
                string codConv = "";
                string esqConv = conversao($1.label, tipoEsq, tipoTemp, codConv);
                string dirConv = conversao($3.label, tipoDir, tipoTemp, codConv);
                $$.label = gentempcode(tipoTemp);
                $$.traducao = $1.traducao + $3.traducao + codConv + "\t" + $$.label + " = " + esqConv + " + " + dirConv + ";\n";
                $$.tipoExp = tipoTemp;
            }
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
        | TK_STRING_VAL {
            $$.tipoExp = "string";
            string temp_str_heap = gentempcode("string");  
            string temp_len = gentempcode("int");
            string temp_size = gentempcode("int");

            $$.traducao += "\t" + temp_len + " = tamanhoString(" + $1.label + ");\n";

            $$.traducao += "\t" + temp_size + " = " + temp_len + " + 1;\n";
            $$.traducao += "\t" + temp_str_heap + " = (char*) malloc(" + temp_size + ");\n";
            $$.traducao += "\tstrcpy(" + temp_str_heap + ", " + $1.label + ");\n";
            stringsAlocados.insert(temp_str_heap);

            $$.label = temp_str_heap;
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
            tab infoVar = buscarSimbolo(nomeVar);
            string nomeMem = infoVar.elemento;    
            string tipoVar = infoVar.tipo;
            string tipoExpr = $3.tipoExp;

            if (tipoVar == "string" && tipoExpr == "string") {
                string temp_len = gentempcode("int");
                string temp_size = gentempcode("int");

                $$.traducao = $3.traducao;
                $$.traducao += "\t" + temp_len + " = tamanhoString(" + $3.label + ");\n";
                $$.traducao += "\t" + temp_size + " = " + temp_len + " + 1;\n";
                $$.traducao += "\t" + nomeMem + " = (char*) malloc(" + temp_size + ");\n";
                $$.traducao += "\tstrcpy(" + nomeMem + ", " + $3.label + ");\n";
                stringsAlocados.insert(nomeMem);
                $$.tipoExp = "";
                $$.label = "";
            } else { 
                if(tipoVar == "bool") tipoVar = "int";
                if(tipoExpr == "bool") tipoExpr = "int";
                if (tipoVar != tipoExpr) {
                    cout << "Warning: Tipos incompatíveis na atribuição!" << endl;
                }
                $$.traducao = $3.traducao + "\t" + nomeMem + " = " + $3.label + ";\n";
                $$.tipoExp = ""; 
                $$.label = "";
            }
        }
        | ACESSO_MATRIZ '=' E {
            if ($1.tipoExp != $3.tipoExp) {
                cout << "Warning: Tipos incompativeis na atribuicao de matriz!" << endl;
            }

            $$.traducao = $1.traducao + $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";
            $$.tipoExp = ""; 
            $$.label = "";   
        }

        | TK_ID TK_MAIS_IGUAL E {
            tab infoVar = buscarSimbolo($1.label);
            string nomeMem = infoVar.elemento;
            string tipoVar = infoVar.tipo;
            string tipoExpr = $3.tipoExp;

            if (tipoVar == "string" || tipoVar == "bool") {
                yyerror("Erro Semantico: Operador '+=' invalido para o tipo " + tipoVar);
            }

            string tipoTemp = tipoResult(tipoVar, tipoExpr);
            string codConv = "";
            string exprConvertida = conversao($3.label, tipoExpr, tipoTemp, codConv);
        
            string temp_result = gentempcode(tipoTemp); 

            $$.traducao = $3.traducao + codConv; 
            $$.traducao += "\t" + temp_result + " = " + nomeMem + " + " + exprConvertida + ";\n"; 
            $$.traducao += "\t" + nomeMem + " = " + temp_result + ";\n"; 
        
            $$.label = nomeMem;
            $$.tipoExp = tipoVar;
        }
        | TK_ID TK_MENOS_IGUAL E {
            tab infoVar = buscarSimbolo($1.label);
            string nomeMem = infoVar.elemento;
            string tipoVar = infoVar.tipo;
            string tipoExpr = $3.tipoExp;

            if (tipoVar == "string" || tipoVar == "bool") {
                yyerror("Erro Semantico: Operador '-=' invalido para o tipo " + tipoVar);
            }

            string tipoTemp = tipoResult(tipoVar, tipoExpr);
            string codConv = "";
            string exprConvertida = conversao($3.label, tipoExpr, tipoTemp, codConv);

            string temp_result = gentempcode(tipoTemp); 

            $$.traducao = $3.traducao + codConv;
            $$.traducao += "\t" + temp_result + " = " + nomeMem + " - " + exprConvertida + ";\n";
            $$.traducao += "\t" + nomeMem + " = " + temp_result + ";\n";
        
            $$.label = nomeMem;
            $$.tipoExp = tipoVar;
        }
        | TK_ID TK_MULT_IGUAL E {
            tab infoVar = buscarSimbolo($1.label);
            string nomeMem = infoVar.elemento;
            string tipoVar = infoVar.tipo;
            string tipoExpr = $3.tipoExp;

            if (tipoVar == "string" || tipoVar == "bool") {
                yyerror("Erro Semantico: Operador '*=' invalido para o tipo " + tipoVar);
            }

            string tipoTemp = tipoResult(tipoVar, tipoExpr);
            string codConv = "";
            string exprConvertida = conversao($3.label, tipoExpr, tipoTemp, codConv);

            string temp_result = gentempcode(tipoTemp); 

            $$.traducao = $3.traducao + codConv;
            $$.traducao += "\t" + temp_result + " = " + nomeMem + " * " + exprConvertida + ";\n";
            $$.traducao += "\t" + nomeMem + " = " + temp_result + ";\n";
        
            $$.label = nomeMem;
            $$.tipoExp = tipoVar;
        }
        | TK_ID TK_DIV_IGUAL E {
            tab infoVar = buscarSimbolo($1.label);
            string nomeMem = infoVar.elemento;
            string tipoVar = infoVar.tipo;
            string tipoExpr = $3.tipoExp;

            if (tipoVar == "string" || tipoVar == "bool") {
                yyerror("Erro Semantico: Operador '/=' invalido para o tipo " + tipoVar);
            }

            string tipoTemp = tipoResult(tipoVar, tipoExpr);
            string codConv = "";
            string exprConvertida = conversao($3.label, tipoExpr, tipoTemp, codConv);

            string temp_result = gentempcode(tipoTemp); 

            $$.traducao = $3.traducao + codConv;
            $$.traducao += "\t" + temp_result + " = " + nomeMem + " / " + exprConvertida + ";\n";
            $$.traducao += "\t" + nomeMem + " = " + temp_result + ";\n";
        
            $$.label = nomeMem;
            $$.tipoExp = tipoVar;
        }
        | TK_ID TK_INCREMENTO {
            tab infoVar = buscarSimbolo($1.label);
            if (infoVar.tipo != "int" && infoVar.tipo != "float") {
                yyerror("Erro Semantico: Operador '++' so pode ser aplicado a tipos numericos.");
            }
            string nomeMem = infoVar.elemento;

            string temp_antigo = gentempcode(infoVar.tipo);
            $$.traducao = "\t" + temp_antigo + " = " + nomeMem + ";\n";

            string temp_um = gentempcode(infoVar.tipo);
            $$.traducao += "\t" + temp_um + " = 1;\n";
            $$.traducao += "\t" + nomeMem + " = " + temp_antigo + " + " + temp_um + ";\n";
        
            $$.label = temp_antigo;
            $$.tipoExp = infoVar.tipo;
        }
        | TK_ID TK_DECREMENTO {
            tab infoVar = buscarSimbolo($1.label);
            if (infoVar.tipo != "int" && infoVar.tipo != "float") {
                yyerror("Erro Semantico: Operador '--' so pode ser aplicado a tipos numericos.");
            }
            string nomeMem = infoVar.elemento;

            string temp_antigo = gentempcode(infoVar.tipo);
            $$.traducao = "\t" + temp_antigo + " = " + nomeMem + ";\n";

            string temp_um = gentempcode(infoVar.tipo);
            $$.traducao += "\t" + temp_um + " = 1;\n";
            $$.traducao += "\t" + nomeMem + " = " + temp_antigo + " - " + temp_um + ";\n";
        
            $$.label = temp_antigo;
            $$.tipoExp = infoVar.tipo;
        }
        | TK_INCREMENTO TK_ID {
            tab infoVar = buscarSimbolo($2.label);
            if (infoVar.tipo != "int" && infoVar.tipo != "float") {
                yyerror("Erro Semantico: Operador '++' so pode ser aplicado a tipos numericos.");
            }
            string nomeMem = infoVar.elemento;
        
            string temp_um = gentempcode(infoVar.tipo);
            $$.traducao = "\t" + temp_um + " = 1;\n";
            $$.traducao += "\t" + nomeMem + " = " + nomeMem + " + " + temp_um + ";\n";

            $$.label = nomeMem;
            $$.tipoExp = infoVar.tipo;
        }
        | TK_DECREMENTO TK_ID {
            tab infoVar = buscarSimbolo($2.label);
            if (infoVar.tipo != "int" && infoVar.tipo != "float") {
                yyerror("Erro Semantico: Operador '--' so pode ser aplicado a tipos numericos.");
            }
            string nomeMem = infoVar.elemento;

            string temp_um = gentempcode(infoVar.tipo);
            $$.traducao = "\t" + temp_um + " = 1;\n";
            $$.traducao += "\t" + nomeMem + " = " + nomeMem + " - " + temp_um + ";\n";
        
            $$.label = nomeMem;
            $$.tipoExp = infoVar.tipo;
        }
        | ACESSO_MATRIZ { $$ = $1; }
        | TK_NUM {
            $$.label = gentempcode("int");
            $$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
            $$.tipoExp = "int";
        }
        | TK_ID {
            tab infoVar = buscarSimbolo($1.label);
    
            if (infoVar.categoria == "constante") {
            
                $$.label = infoVar.elemento; 
                $$.traducao = ""; 
                $$.tipoExp = infoVar.tipo; 
            } else {
               
                if (infoVar.tipo == "string") {
                    $$.label = infoVar.elemento;
                    $$.traducao = "";
                    $$.tipoExp = "string";
                } else {
                    string nomeMem = infoVar.elemento;
                    $$.label = gentempcode(infoVar.tipo);
                    $$.traducao = "\t" + $$.label + " = " + nomeMem + ";\n";
                    $$.tipoExp = infoVar.tipo;
                }
            }
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
        | TK_ID '(' ARGS ')' {
            string nomeFunc = $1.label;
            tab infoFunc = buscarSimbolo(nomeFunc);

            if(infoFunc.categoria != "funcao") {
                yyerror("Erro Semantico: '" + nomeFunc + "' nao e uma funcao.");
            }
            if(infoFunc.paramTipos.size() != $3.listaArgs.size()) {
                yyerror("Erro Semantico: Numero incorreto de argumentos para a funcao '" + nomeFunc + "'.");
            }

            string codigo_args = "";
            string args_c = "";
            for(size_t i = 0; i < $3.listaArgs.size(); ++i) {
                if ($3.listaArgs[i].tipoExp != infoFunc.paramTipos[i]) {
                    cout << "Warning: Incompatibilidade de tipo no argumento " << i+1 << " da funcao '" << nomeFunc << "'." << endl;
                }
                if (i > 0) args_c += ", ";
                codigo_args += $3.listaArgs[i].traducao;
                args_c += $3.listaArgs[i].label;
            }

            $$.traducao = codigo_args;
            $$.tipoExp = infoFunc.tipo;
            if ($$.tipoExp != "void") {
                $$.label = gentempcode($$.tipoExp);
                $$.traducao += "\t" + $$.label + " = " + nomeFunc + "(" + args_c + ");\n";
            } else {
                $$.label = ""; 
                $$.traducao += "\t" + nomeFunc + "(" + args_c + ");\n";
            }
        }
        ;
    ACESSO_MATRIZ
        : TK_ID LISTA_INDICES {
            tab infoVar = buscarSimbolo($1.label);
            if (infoVar.dimensoes.empty()) {
                yyerror("Erro Semantico: Variavel '" + $1.label + "' nao e uma matriz.");
            }
            if (infoVar.dimensoes.size() != $2.listaArgs.size()) {
                yyerror("Erro Semantico: Numero incorreto de indices para a matriz '" + $1.label + "'.");
            }

            string nomeMem = infoVar.elemento;
            $$.traducao = $2.traducao; 
            $$.tipoExp = infoVar.tipo;

            if ($2.listaArgs.size() == 1) { 
                $$.label = nomeMem + "[" + $2.listaArgs[0].label + "]";
            } else { 
                if ($2.listaArgs.size() == 2) {
                    string i = $2.listaArgs[0].label; 
                    string j = $2.listaArgs[1].label; 
                    int num_colunas = infoVar.dimensoes[1];

                    string temp_num_cols = gentempcode("int");
                    $$.traducao += "\t" + temp_num_cols + " = " + to_string(num_colunas) + ";\n";

                    string temp_mult = gentempcode("int");
                    $$.traducao += "\t" + temp_mult + " = " + i + " * " + temp_num_cols + ";\n";
                
                    string temp_final_index = gentempcode("int");
                    $$.traducao += "\t" + temp_final_index + " = " + temp_mult + " + " + j + ";\n";
                
                    $$.label = nomeMem + "[" + temp_final_index + "]";
                } else {
                    yyerror("Erro: Compilador so suporta matrizes 1D e 2D no momento.");
                }
            }
        }
    ;

    ARGS
        : LISTA_ARGS { $$ = $1; }
        | { $$.listaArgs.clear(); $$.traducao = "";}
        ;

    LISTA_ARGS
        : E {
            $$.listaArgs.push_back($1);
            $$.traducao = $1.traducao;
        }
        | LISTA_ARGS ',' E {
            $$.listaArgs = $1.listaArgs;
            $$.listaArgs.push_back($3);
            $$.traducao = $1.traducao + $3.traducao;
        }
    ;
    LISTA_VALORES
        : E {
            $$.listaArgs.push_back($1);
            $$.traducao = $1.traducao;
        }
        |  LISTA_VALORES ',' E {
            $$.listaArgs = $1.listaArgs;
            $$.listaArgs.push_back($3);
            $$.traducao = $1.traducao + $3.traducao;
        }
    ;
    LISTA_DIMENSOES
        : '[' TK_NUM ']' {
            $$.listaDimensoes.push_back(stoi($2.label));
        }
        | LISTA_DIMENSOES '[' TK_NUM ']' {
            $$.listaDimensoes = $1.listaDimensoes;
            $$.listaDimensoes.push_back(stoi($3.label));
        }
    ;
    LISTA_INDICES
        : '[' E ']' {
            $$.listaArgs.push_back($2); 
            $$.traducao = $2.traducao; 
        }
        | LISTA_INDICES '[' E ']' {
            $$.listaArgs = $1.listaArgs;
            $$.listaArgs.push_back($3);
            $$.traducao = $1.traducao + $3.traducao;
        }
    ;

%%

#include "lex.yy.c"

int yyparse();

void adicionarVariavel(string nome, string tipo, const vector<int>& dimensoes) {
    
    if (pilhaDeSimbolos.top().count(nome)) {
        yyerror("Erro: A variavel '" + nome + "' ja foi declarada.");
        return;
    }
    
    string nomeMem = "v" + to_string(var_qnt++);
    pilhaDeSimbolos.top()[nome] = { tipo, nomeMem, "var", {}, dimensoes };
    tabelaGeracao[nome] = { tipo, nomeMem, "var", {}, dimensoes };
    variaveisNome.insert(nomeMem);
    
    if (!funcaoAtual.empty()) func_vars[nome] = { tipo, nomeMem, "var", {}, dimensoes };
}

void adicionarFuncao(string nome, string tipoRetorno, vector<string> tiposParams) {
    if (pilhaDeSimbolos.top().count(nome)) {
        yyerror("Erro Semantico: Simbolo '" + nome + "' ja foi declarado neste escopo.");
        return;
    }
    pilhaDeSimbolos.top()[nome] = { tipoRetorno, nome, "funcao", tiposParams };
}

void adicionarParametro(string nome, string tipo) {
    if (pilhaDeSimbolos.top().count(nome)) {
        yyerror("Erro: Parametro '" + nome + "' ja foi declarado.");
        return;
    }
    
    string nomeMem = "v" + to_string(var_qnt++);
    pilhaDeSimbolos.top()[nome] = { tipo, nomeMem, "var", {}, {} }; 
    tabelaGeracao[nome] = { tipo, nomeMem, "var", {}, {} };     
    variaveisNome.insert(nomeMem);
}

tab buscarSimbolo(string nome) {
   
    stack<map<string, tab>> tempStack = pilhaDeSimbolos;
    
    while (!tempStack.empty()) {
        map<string, tab> escopoAtual = tempStack.top();
        if (escopoAtual.count(nome)) {
          
            return escopoAtual.at(nome);
        }
        tempStack.pop(); 
    }
    
    yyerror("Erro Semantico: Variavel '" + nome + "' nao foi declarada.");
    return {"error", "error", "error"}; 
}

string gentempcode(string tipo) {
    while (true) {
        string nomeTemp = "t" + to_string(var_temp_qnt++);
        if (!tabelaGeracao.count(nomeTemp)) { 
            variaveisTempNome.insert(nomeTemp);
            tabelaGeracao[nomeTemp] = { tipo, nomeTemp };
            if (!funcaoAtual.empty()) func_vars[nomeTemp] = { tipo, nomeTemp, "temp" };
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
            if (!funcaoAtual.empty()) func_vars[nomeTemp] = { tipo, nomeTemp, "temp" };
            return nomeTemp;
        }
    }
}

string tipoResult(string tipo1, string tipo2){
    if(tipo1 == "bool" || tipo2 == "bool" || tipo1 == "string" || tipo2 == "string"){ 
        yyerror("Erro de sintaxe: Operacao invalida com o tipo booleano ou palavra.");
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
