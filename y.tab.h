/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    TK_NUM = 258,                  /* TK_NUM  */
    TK_MAIN = 259,                 /* TK_MAIN  */
    TK_ID = 260,                   /* TK_ID  */
    TK_FIM = 261,                  /* TK_FIM  */
    TK_ERROR = 262,                /* TK_ERROR  */
    TK_TIPO_CHAR = 263,            /* TK_TIPO_CHAR  */
    TK_TIPO_BOOLEAN = 264,         /* TK_TIPO_BOOLEAN  */
    TK_TIPO_INT = 265,             /* TK_TIPO_INT  */
    TK_TIPO_FLOAT = 266,           /* TK_TIPO_FLOAT  */
    TK_CHAR_VAL = 267,             /* TK_CHAR_VAL  */
    TK_INT_VAL = 268,              /* TK_INT_VAL  */
    TK_FLOAT_VAL = 269,            /* TK_FLOAT_VAL  */
    TK_TRUE = 270,                 /* TK_TRUE  */
    TK_FALSE = 271,                /* TK_FALSE  */
    TK_MENOR_IGUAL = 272,          /* TK_MENOR_IGUAL  */
    TK_MAIOR_IGUAL = 273,          /* TK_MAIOR_IGUAL  */
    TK_IGUAL_IGUAL = 274,          /* TK_IGUAL_IGUAL  */
    TK_DIFERENTE = 275,            /* TK_DIFERENTE  */
    TK_AND = 276,                  /* TK_AND  */
    TK_OR = 277                    /* TK_OR  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
#define TK_NUM 258
#define TK_MAIN 259
#define TK_ID 260
#define TK_FIM 261
#define TK_ERROR 262
#define TK_TIPO_CHAR 263
#define TK_TIPO_BOOLEAN 264
#define TK_TIPO_INT 265
#define TK_TIPO_FLOAT 266
#define TK_CHAR_VAL 267
#define TK_INT_VAL 268
#define TK_FLOAT_VAL 269
#define TK_TRUE 270
#define TK_FALSE 271
#define TK_MENOR_IGUAL 272
#define TK_MAIOR_IGUAL 273
#define TK_IGUAL_IGUAL 274
#define TK_DIFERENTE 275
#define TK_AND 276
#define TK_OR 277

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);


#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
