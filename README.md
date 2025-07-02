/*Compilador CCP*/

exemplos:

1# if else
inteiro principal() {
    inteiro a;
    a = 10;

    se (a > 5) {
        a = a + 1;
    } senao {
        a = a - 1;
    }
}

2# while
inteiro principal() {
    inteiro i;
    i = 0;

    enquanto (i < 5) {
        i = i + 1;
    }
}

3# do while
inteiro principal() {
    inteiro i;
    i = 0;

    fazer {
        i = i + 1;
    } enquanto (i < 5);
}

4# for
inteiro principal() {
    inteiro i;
    inteiro soma;

    soma = 0;

    para (i = 1; i <= 5; i = i + 1) {
        soma = soma + i;
    }
}

5# switch
inteiro principal() {
    inteiro x = 2;
    inteiro y = 0;

    escolha (x) {
        caso 1:
            y = 10;
            encerrar;
        caso 2:
            y = 20;
            encerrar;
        padrao:
            y = -1;
    }
}

6# continue
inteiro principal() {
    inteiro i;

    para (i = 1; i <= 5; i = i + 1) {
        se (i == 3) {
            pular; 
        }
    }
}


7# string
inteiro principal() {
    palavra nome = "Cristyan";
    palavra nome2 = "Pedro";
    palavra nome3 = nome + nome2;
}

8# entrada e saída
inteiro principal() {
    inteiro a;
    escrever("Digite um número:");
    ler(a);
    escrever("Você digitou:");
    escrever(a);
}

9# exemplo geral
inteiro principal() {
    inteiro idade;
    palavra nome;
    inteiro i;

    escrever("Digite seu nome: ");
    ler(nome);

    escrever("Digite sua idade: ");
    ler(idade);

    se (idade >= 18) {
        escrever("Bem-vindo, ");
        escrever(nome);
        escrever("! Voce e maior de idade.\n");
    } senao {
        escrever("Desculpe, ");
        escrever(nome);
        escrever(", voce e menor de idade.\n");
    }

    escrever("Contando de 1 ate sua idade:\n");
    para (i = 1; i <= idade; i = i + 1) {
        escrever(i);
        escrever(" ");
    }

    escrever("\nFim do programa.\n");
}

10# Exemplo função soma
inteiro soma(inteiro a, inteiro b) {
    retornar a + b;
}

inteiro principal() {

    inteiro resultado;

    resultado = soma(10, 5);

    escrever(resultado); 
    escrever(soma(100, -20)); 

    retornar 0;
}

11# Função fibonacci
inteiro fibonacci(inteiro n) {
    se (n == 0) {
        retornar 0;
    }
    
    se (n == 1) {
        retornar 1;
    }
    retornar fibonacci(n - 1) + fibonacci(n - 2);
}

inteiro principal() {
    inteiro termo;
    inteiro resultado;
    termo = 10; 
    resultado = fibonacci(termo);
    escrever(resultado);
    retornar 0;
}

12# Operadores compostos
inteiro principal() {
    inteiro x;
    x = 10;
    x -= 5;   
    escrever(x);

    flutuante y;
    y = 4.0;
    y /= 2.0; 
    escrever(y);

    inteiro w;
    w = 10;
    w += 5;   
    escrever(w);

    flutuante z;
    z = 2.5;
    z *= 2.0; 
    escrever(z);

    retornar 0;
}

13# Operador unário
inteiro principal() {
    inteiro x;
    inteiro a;
    inteiro b;
    x = 5;

    a = x++; 
    escrever(a); 
    escrever(x); 

    x = 10;
    b = ++x; 
    escrever(b); 
    escrever(x); 

    retornar 0;
}

14# Matriz
inteiro principal() {
    inteiro matriz[2][2];
    matriz[1][1] = 99;
    escrever(matriz[1][1]);
}

15# Vetor
inteiro principal() {
    inteiro notas[4];
    notas[1] = 10;
    escrever(notas[1]);
    retornar 0;
}
