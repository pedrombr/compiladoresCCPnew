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
