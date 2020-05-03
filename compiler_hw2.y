/*	Definition section */
%{
    #include "common.h" //Extern variables that communicate with lex
    #include <stdio.h>
    #include <math.h>
    #include <string.h>
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

    /* for type */
    char *tmp_type;

    /* for check scope */
    int tmp_scope, i;

    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno, s);
    }

    /* Symbol table function - you can add new function if needed. */
    static void create_symbol();
    static void insert_symbol(int, char*, char*, int, char*);
    static int lookup_symbol(char*, int);
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
    | NEWLINE
    | cal
    | print
    | block
    | setVal
    | error_assign
    | ifelse
    | forloop
;

forloop
    : FOR expr '{' {scope++;} stmts '}'     {scope--;}
    | FOR forexpr '{' {scope++;} stmts '}'     {scope--;}
;

forexpr
    : ident assignVal ';' ident compare ';' cal
;

ifelse
    : IF expr '{' {scope++;} stmts '}'      {scope--;}
    | ELSE IF expr '{' {scope++;} stmts '}' {scope--;}
    | ELSE '{' {scope++;} stmts '}'         {scope--;}
;

error_assign
    : INT_LIT {printf("INT_LIT %d\n", $1); } assign
    | FLOAT_LIT {printf("FLOAT_LIT %f\n", $1);} assign
;

assign
    : '=' expr           { printf("ASSIGN\n"); }
    | ADD_ASSIGN expr    { printf("error:%d: cannot assign to int32\nADD_ASSIGN\n", yylineno); }
    | SUB_ASSIGN     { printf("SUB_ASSIGN\n"); }
    | MUL_ASSIGN     { printf("MUL_ASSIGN\n"); }
    | QUO_ASSIGN     { printf("QUO_ASSIGN\n"); }
    | REM_ASSIGN     { printf("REM_ASSIGN\n"); }
;

setVal
    : ID '[' INT_LIT    { printf("IDENT (name=%s, address=%d)\nINT_LIT %d\n", $1,lookup_symbol($1, scope), $3);} ']' value_initial  { printf("ASSIGN\n"); }
    | ident assignVal NEWLINE
;

var
    : INT_LIT               {printf("INT_LIT %d\n", $1);}
    | FLOAT_LIT             {printf("FLOAT_LIT %f\n", $1);}
    | '"' STRING_LIT '"'    {printf("STRING_LIT %s\n", $2);}
    | TRUE                  {printf("TRUE\n");}
    | FALSE                 {printf("FALSE\n");}
    | expr
;

assignVal
    : '=' var           { printf("ASSIGN\n"); }
    | ADD_ASSIGN var    { printf("ADD_ASSIGN\n"); }
    | SUB_ASSIGN var    { printf("SUB_ASSIGN\n"); }
    | MUL_ASSIGN var    { printf("MUL_ASSIGN\n"); }
    | QUO_ASSIGN var    { printf("QUO_ASSIGN\n"); }
    | REM_ASSIGN var    { printf("REM_ASSIGN\n"); }
;

ident
    : ID    { tmp_scope = -1;
        for(i=0; i<=scope; i++) {
            if(lookup_symbol($1, i) != -1) tmp_scope = lookup_symbol($1, i);
        }

        if( tmp_scope == -1 ) {
            printf("error:%d: undefined: %s\n", yylineno+1, $1);
        }
        else {
            printf("IDENT (name=%s, address=%d)\n", $1, tmp_scope); 
            if( strcmp(typeArr[tmp_scope],"bool") == 0 )
                printflag = 1;
            else if( strcmp(typeArr[tmp_scope],"float32") == 0 )
                printflag = 2;
            else if( strcmp(typeArr[tmp_scope],"string") == 0 )
                printflag = 3;
        }
    }
;

value_initial
    : '=' expr NEWLINE
    |
;

block
    : '{' NEWLINE {scope++;} stmts '}' NEWLINE     { scope--; }
;

Def
    : VAR ID INT INT_initial        { insert_symbol( scope, $2, "int32", yylineno, "-"); }
    | VAR ID STRING STR_initial     { insert_symbol( scope, $2, "string", yylineno, "-"); }
    | VAR ID FLOAT FLOAT_initial    { insert_symbol( scope, $2, "float32", yylineno, "-"); }
    | VAR ID BOOL BOOL_initial      { insert_symbol( scope, $2, "bool", yylineno, "-"); }
    | VAR ID '[' INT_LIT { printf("INT_LIT %d\n", $4); } ']' typee NEWLINE   { insert_symbol( scope, $2, "array", yylineno, tmp_type); }
;

typee
    : INT           { tmp_type = "int32"; }
    | FLOAT         { tmp_type = "float32"; }
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
    : ident INC       {
                        printf("INC\n");
                      }
    | ident DEC       {
                        printf("DEC\n");
                      }
    | ID '+' ID       { 
                        printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1, scope));
                        printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3, scope));
                        printf("ADD\n"); 
                      }
    | ID '-' ID       { 
                        printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1, scope));
                        printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3, scope));
                        printf("SUB\n"); 
                      }
    | ID '*' ID       { 
                        printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1, scope));
                        printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3, scope));
                        printf("MUL\n"); 
                      }
    | ID '/' ID       { 
                        printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1, scope));
                        printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3, scope));
                        printf("QUO\n"); 
                      }
    | ID '%' ID       { 
                        printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1, scope));
                        printf("IDENT (name=%s, address=%d)\n", $3, lookup_symbol($3, scope));
                        printf("REM\n"); 
                      }
;

print
    : PRINTLN { printflag = 0; } '(' expr ')' {
        if(printflag == 0)
            printf("PRINTLN int32\n");
        else if(printflag == 1)
            printf("PRINTLN bool\n");
        else if(printflag == 2)
            printf("PRINTLN float32\n");
        else
            printf("PRINTLN string\n");
    }
    | PRINT { printflag = 0; } '(' expr ')' {
        if(printflag == 0)
            printf("PRINT int32\n");
        else if(printflag == 1)
            printf("PRINT bool\n");
        else if(printflag == 2)
            printf("PRINT float32\n");
        else
            printf("PRINT string\n");
    }
;

expr
    : expr '+' preexpr  {printf("ADD\n");}
    | expr '-' preexpr  {printf("SUB\n");}
    | expr '%' preexpr  {printf("REM\n");}
    | preexpr
    | term
    | expr compare expr     { printflag = 1; }
    | andor expr
    | '(' expr ')'
    | bool                  { printflag = 1; }
    | '"' STRING_LIT '"'    { printf("STRING_LIT %s\n", $2); printflag = 3; }
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
    | '<' expr      { printf("LSS\n"); }
    | GEQ expr      { printf("GEQ\n"); }
    | LEQ expr      { printf("LEQ\n"); }
    | EQL expr      { printf("EQL\n"); }
    | NEQ expr      { printf("NEQ\n"); }
;

term
    : INT_LIT               { printf("INT_LIT %d\n", $1); }
    | FLOAT_LIT             { printf("FLOAT_LIT %f\n", $1); }
    | SIGN_INT_LIT          { printf("INT_LIT %d\n", abs($1)); 
                                if( abs($1) == $1) {
                                    printf("POS\n");
                                }
                                else {
                                    printf("NEG\n");
                                }
                            }
    | SIGN_FLOAT_LIT        { printf("FLOAT_LIT %f\n", fabs($1)); 
                                if( abs($1) == $1) {
                                    printf("POS\n");
                                }
                                else {
                                    printf("NEG\n");
                                }
                            }
    | ID { printf("IDENT (name=%s, address=%d)\n", $1, lookup_symbol($1, scope)); } '[' expr ']' 
            {   if( strcmp(elementType[lookup_symbol($1, scope)],"float32") == 0 )
                    printflag = 2;
                else if( strcmp(elementType[lookup_symbol($1, scope)],"string") == 0 )
                    printflag = 3; }
    | ID    {   tmp_scope = -1;
                for(i=0; i<=scope; i++) {
                    if( lookup_symbol($1, i) != -1) tmp_scope = lookup_symbol($1, i);
                }

                if( tmp_scope == -1 ) {
                    printf("error:%d: undefined: %s\n", yylineno+1, $1);
                }
                else {
                    printf("IDENT (name=%s, address=%d)\n", $1, tmp_scope); 
                    if( strcmp(typeArr[tmp_scope],"float32") == 0 )
                        printflag = 2;
                    else if( strcmp(typeArr[tmp_scope],"string") == 0 )
                        printflag = 3;
                    else if( strcmp(typeArr[tmp_scope],"bool") == 0 )
                        printflag = 1;
                }
            }
    | INT '(' ident ')'         { printf("F to I\n"); }
    | INT '(' FLOAT_LIT ')'     { printf("FLOAT_LIT %f\nF to I\n",$3); }
    | FLOAT '(' ident ')'       { printf("I to F\n"); }
    | FLOAT '(' INT_LIT ')'     { printf("INT_LIT %d\nI to F\n",$3); }
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

static void insert_symbol(int level, char *id, char *type, int linenum, char *element) {
    for(int i=0; i<varNum; i++) {
        if(strcmp(name[i],id) == 0 && scopeArr[i] == level) {
            printf("error:%d: %s redeclared in this block. previous declaration at line %d\n", linenum, id, lineno[i]);
            return;
        }
    }
    
    printf("> Insert {%s} into symbol table (scope level: %d)\n", id, level);
    
    int i = varNum;
    indexArr[i] = symNum[level];
    name[i] = id;
    typeArr[i] = type;
    lineno[i] = linenum;
    elementType[i] = element;
    scopeArr[i] = level;

    symNum[level]++;
    varNum++;
}

static int lookup_symbol(char *id, int level) {
    for(int i=0; i<varNum; i++) {
        if( strcmp(id,name[i]) == 0 && level == scopeArr[i] ) {
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
            strcpy(name[i], "");
        }
    }

    symNum[level] = 0;
}
