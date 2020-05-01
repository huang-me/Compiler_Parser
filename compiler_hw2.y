/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    #include <stdio.h>
    #include <math.h>
    // #define YYDEBUG 1
    // int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* for symbol table */
    int scope = 0;
    int indexArr[50], lineno[50], scopeArr[50];
    char* name[50], *typeArr[50], *elementType[50];
    int symNum[5];
    int varNum = 0;

    /* for println flag */
    int printflag = 0;

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(int, char*, char*, int);
    static int lookup_symbol(char*);
    static void dump_symbol(int);
%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    int si_val;
    float f_val;
    float sf_val;
    char *s_val;
    char *id_val;
    /* ... */
}

/* Token without return */
%token VAR
%token INT FLOAT BOOL STRING
%token INC DEC GEQ LEQ EQL NEQ ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN
%token QUO_ASSIGN REM_ASSIGN LAND LOR NEWLINE PRINT PRINTLN IF ELSE FOR 
%token TRUE FALSE

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <si_val> SIGN_INT_LIT
%token <f_val> FLOAT_LIT
%token <sf_val> SIGN_FLOAT_LIT
%token <s_val> STRING_LIT
%token <id_val> ID

/* Nonterminal with return, which need to sepcify type */
/*
%type <type> Type TypeName ArrayType
*/

/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : stmt stmts    { create_symbol(); }
    |
;

stmts
    : stmt stmts
    |               { dump_symbol(scope); }
;

stmt
    : Def
    | cal
    | print
    | block
;

block
    : '{' NEWLINE {scope++;} stmts '}' NEWLINE     { scope--; }

Def
    : VAR ID INT INT_initial        { insert_symbol( scope, $2, "int32", yylineno); }
    | VAR ID STRING STR_initial     { insert_symbol( scope, $2, "string", yylineno); }
    | VAR ID FLOAT FLOAT_initial    { insert_symbol( scope, $2, "float32", yylineno); }
    | VAR ID BOOL BOOL_initial      { insert_symbol( scope, $2, "bool", yylineno); }
;

BOOL_initial
    : '=' TRUE NEWLINE          {printf("TRUE\n");}
    | '=' FALSE NEWLINE         {printf("FALSE\n");}
    | NEWLINE
;

FLOAT_initial
    : '=' FLOAT_LIT NEWLINE     {printf("FLOAT_LIT %f\n", $2);}
    | NEWLINE
;

INT_initial
    : '=' INT_LIT NEWLINE   {printf("INT_LIT %d\n", $2);}
    | NEWLINE
;

STR_initial
    : '=' '"' STRING_LIT '"' NEWLINE    {printf("STRING_LIT %s\n", $3);}
    | NEWLINE
;

cal
    : ID '+' ID NEWLINE      { 
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3));
                                printf("ADD\n"); 
                             }
    | ID '-' ID NEWLINE      { 
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3));
                                printf("SUB\n"); 
                             }
    | ID '*' ID NEWLINE      { 
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3));
                                printf("MUL\n"); 
                             }
    | ID '/' ID NEWLINE      { 
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3));
                                printf("QUO\n"); 
                             }
    | ID '%' ID NEWLINE      { 
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3));
                                printf("REM\n"); 
                             }
    | ID INC NEWLINE         {
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("INC\n");
                             }
    | ID DEC NEWLINE         {
                                printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1));
                                printf("DEC\n");
                             }
;

print
    : PRINTLN { printflag = 0; } '(' expr ')' NEWLINE {
        if(printflag == 0)
            printf("PRINTLN INT32\n");
        else if(printflag == 1)
            printf("PRINTLN bool\n");
        else if(printflag == 2)
            printf("PRINTLN float32\n");
        else
            printf("PRINTLN string\n");
    }
;

expr
    : expr '+' preexpr  {printf("ADD\n");}
    | expr '-' preexpr  {printf("SUB\n");}
    | expr '%' preexpr  {printf("REM\n");}
    | term
    | expr compare expr     { printflag = 1; }
    | andor expr
    | '(' expr ')'
    | bool                  { printflag = 1; }
    | 
;

preexpr
    : preexpr '*' preexpr  {printf("MUL\n");}
    | preexpr '/' preexpr  {printf("QUO\n");}
    | '(' expr ')'
    | term
;

andor
    : LAND expr     { printf("LAND\n"); }
    | LOR expr      { printf("LOR\n"); }
;

bool
    : '!' bool { printf("NOT\n"); }  expr 
    | TRUE          { printf("TRUE\n"); }
    | FALSE         { printf("FALSE\n"); }
;

compare
    : '>' expr      { printf("GTR\n"); }
    | '<' expr
    | GEQ expr
    | LEQ expr
    | EQL expr
    | NEQ expr
;

term
    : INT_LIT           { printf("INT_LIT %d\n", $1); }
    | FLOAT_LIT         { printf("FLOAT_LIT %f\n", $1); }
    | SIGN_INT_LIT      { printf("INT_LIT %d\n", abs($1)); 
                            if( abs($1) == $1) {
                                printf("POS\n");
                            }
                            else {
                                printf("NEG\n");
                            }
                        }
    | SIGN_FLOAT_LIT    { printf("FLOAT_LIT %f\n", fabs($1)); 
                            if( abs($1) == $1) {
                                printf("POS\n");
                            }
                            else {
                                printf("NEG\n");
                            }
                        }
;

%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }

    yylineno = 0;
    yyparse();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    return 0;
}

static void create_symbol() {
    /* initialize the symbol table */
    for(int i=0; i<50; i++) {
        indexArr[i] = 0;
        lineno[i] = 0;
        scopeArr[i] = -1;
        name[i] = NULL;
        typeArr[i] = NULL;
        elementType[i] = NULL;
    }
    for(int i=0; i<5; i++) {
        symNum[i] = 0;
    }
}

static void insert_symbol(int level, char *id, char *type, int linenum) {
    printf("> Insert {%s} into symbol table (scope level: %d)\n", id, level);
    
    int i = varNum;
    indexArr[i] = symNum[level];
    name[i] = id;
    typeArr[i] = type;
    lineno[i] = linenum;
    elementType[i] = "-";
    scopeArr[i] = level;

    symNum[level]++;
    varNum++;
}

static int lookup_symbol(char *id) {
    for(int i=0; i<varNum; i++) {
        if(*id == *name[i]) {
            return i;
        }
    }
    return -1;
}

static void dump_symbol(int level) {
    printf("> Dump symbol table (scope level: %d)\n", level);
    printf("%-10s%-10s%-10s%-10s%-10s%s\n",
           "Index", "Name", "Type", "Address", "Lineno", "Element type");
    for(int i=0; i<varNum; i++) {
        if(scopeArr[i] == level) {
            printf("%-10d%-10s%-10s%-10d%-10d%s\n",
            indexArr[i], name[i], typeArr[i], i, lineno[i], elementType[i]);

            scopeArr[i] = -1;
        }
    }

    symNum[level] = 0;
}
