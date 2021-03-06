/*
int switch clause, constant after "case" can only be constant parsed by lex 
	and regard constant expression as error, 
	but think real number and string constant correct .
varinit can be extend to fit the initialization of array and struct .
do not support explicit type cast like "int i = (int)c;" in the "expr" production .
the error "void a" in "void f(void a)" may not be recognize .
do not support type modifiers such as "const" .
"name" needs to be modified to fit the rule that "int a[][3]" is right and "int a[3][]" is wrong .
*/

%{
    #include <stdio.h>
    #include "yacc.tab.h"

	#define	log(msg)	syntaxAnalasisLog(msg,0)
	
	int yylex(void);
	void yyerror(const char *s);
	void syntaxAnalasisLog( const char *msg, int linenoShift );
	
	extern int lineno;
%}

// -------------------------

%start program

// -------------------------
%token KW_AUTO KW_CONST KW_EXTERN KW_REGISTER KW_STATIC KW_VOLATILE KW_TYPEDEF
%token KW_CHAR KW_DOUBLE KW_FLOAT KW_INT KW_LONG KW_SHORT KW_SIGNED KW_UNSIGNED KW_VOID
%token KW_STRUCT KW_UNION KW_ENUM
%token KW_BREAK KW_CASE KW_CONTINUE KW_DEFAULT KW_DO KW_ELSE KW_FOR KW_GOTO KW_IF KW_RETURN KW_SWITCH KW_WHILE 

%token ID
%token CONSTANT

// -------------------------
%left	','
%right	'=' ADDASS SUBASS MULASS DIVASS MODASS ANDASS XORASS ORASS SHLASS SHRASS
%right	'?' ':'
%left	OR
%left	AND
%left	'|'
%left	'^'
%left	'&'
%left	EQ NEQ 		// "==" "!="
%left	'<' LE '>' GE 	// '<' "<=" '>' ">="
%left	SHL SHR		// "<<" ">>"
%left	'+' '-'
%left	'*' '/' '%'
%right	'!' '~' INC DEC POS NEG DEREF ADDROF SIZEOF		// '!' '~' "++" "--" '+' '-' '*' '&' "sizeof" //
%left	ARROW '.'	'[' ']' '(' ')'	// "->"

%nonassoc IFX
%nonassoc KW_ELSE


%%	// =================================

program:
	  program	typeDefineStmt
	| program varDeclStmt		{	log("global variable definition");	}
	| program	funcDecl
	| program	funcImplement
	|
	| error ';'
	| error '}'
	;

// -------------------------

typeDefineStmt:
	  typeDefine ';'
	;
typeDefine:
	  KW_TYPEDEF varType ID				{	log("user type definition");	}
	| compondTypeDef
	;
compondTypeDef:
	  KW_STRUCT ID {	log("struct definition");	}	'{' varDecls '}'
	| KW_UNION ID {	log("union definition");	}	'{' varDecls '}'
	| KW_ENUM ID {	log("enum definition");	}	 '{' enumList '}'
	;
varDecls:
	  varDecls varDeclStmt
	|
	;
enumList:
	  ID
	| enumList ',' ID
	;
	
// -------------------------

name:		// in variable declarations and function definition ( as '*' is with ID but not simple type )
	  ID
	| '*' name
	| name '[' expr ']'
	| name '[' ']'
	;

varDeclStmt:
	  varDecl ';'
	;
varDecl:
	  varType varInit
	| varDecl ',' varInit
	;
varInit:
	  name
	| name '=' expr
	| name '=' '{' expr '}'
	;
varType:
	  atomType
	| userDefType
	;
userDefType:
	  compondTypeDef
	| KW_STRUCT ID
	| KW_UNION ID
	| KW_ENUM ID
	| ID																					// 2 reduce/reduce conflicts
	;
atomType:
	  KW_CHAR
	| KW_DOUBLE
	| KW_FLOAT
	| KW_INT
	| KW_LONG
	| KW_SHORT
	| KW_SIGNED
	| KW_UNSIGNED
	| KW_VOID
	;

// -------------------------

funcDecl:
	funcDef ';'	{	log("function declaration");	}
	;

funcDef:
	varType name '(' argvList ')'
	;

argvList:		// used in function declarations
	  varType name
	| argvList ',' varType name
	| KW_VOID
	|
	;

// -------------------------

funcImplement:
	  funcDef {	syntaxAnalasisLog("function implementation", -1);	}	 block
	;

block:
	  '{' stmts '}'
	;

stmts:
	  stmts stmt
	|
	;

stmt:
	  block
	| expr ';'			{	log("expression");	}
	| typeDefineStmt
	| varDeclStmt		{	log("local variable definition");	}
	| for
	| while
	| dowhile
	| if
	| switch
	| ';'					{	log("empty statement");	}	
	| KW_RETURN expr ';'		{	log("return statement");	}
	| KW_RETURN ';'				{	log("return statement");	}
	| KW_BREAK ';'					{	log("break statement");	}
	| KW_CONTINUE ';'			{	log("continue statement");	}
	| KW_GOTO ID ';'				{	log("goto statement");	}
	| ID ':'	/* label of "goto" */		{	log("lable of goto");	}
	| error ';'
	| error '}'
	;

expr:
	// either left or right value expression
	  ID
	| expr '[' expr ']'
	| '*' expr %prec DEREF
	| expr ARROW expr
	| expr '.' expr
	| '(' expr ')'
	// left value expression
	| expr '=' expr
	| expr ADDASS expr
	| expr SUBASS expr
	| expr MULASS expr
	| expr DIVASS expr
	| expr MODASS expr
	| expr ANDASS expr
	| expr XORASS expr
	| expr ORASS expr
	| expr SHLASS expr
	| expr SHRASS expr
	| INC expr
	| DEC expr
	// right value expression
	| CONSTANT
	| SIZEOF expr
	| SIZEOF '(' varType ')'
	| funcCall
	| '&' expr %prec ADDROF
	| expr '?' expr ':' expr
	| expr ',' expr
	| expr OR expr
	| expr AND expr
	| expr '|' expr
	| expr '^' expr
	| expr '&' expr
	| expr EQ expr
	| expr NEQ expr
	| expr '<' expr
	| expr LE expr
	| expr '>' expr
	| expr GE expr
	| expr SHL expr
	| expr SHR expr
	| expr '+' expr
	| expr '-' expr
	| expr '*' expr
	| expr '/' expr
	| expr '%' expr
	| '!' expr
	| '~' expr
	| expr INC
	| expr DEC
	| '+' expr %prec POS
	| '-' expr %prec NEG
	;



funcCall:
	  ID '(' expr ')' {	log("function call");	}	
	;

if:
	  KW_IF '(' expr ')' stmt KW_ELSE stmt	{	log("if-else clause");	} 
	| KW_IF '(' expr ')' stmt %prec IFX	{	log("if clause");	} 
	;

while:
	  KW_WHILE '(' expr ')' {	log("while clause");	}	 stmt
	;

dowhile:
	KW_DO stmt KW_WHILE '(' expr ')' ';' {	log("do-while clause");	}	 
	;

for:
	  KW_FOR '(' forExpr ';' forExpr ';' forExpr ')' {	log("for clause");	}	 stmt
	;
forExpr:
	  expr
	| 
	;
	
switch:
	  KW_SWITCH '(' expr ')' {	log("switch clause");	}	'{' cases defaultCase '}'
	;
cases:
	  case
	| case cases
	;
case:
	  KW_CASE CONSTANT ':' {	log("case in switch");	}	  stmts
	;
defaultCase:
	  KW_DEFAULT ':' {	log("default case in switch");	}	  stmts
	|
	;

/*
argv:			// used in function calls
	  expr
	| argv ',' expr		// replaced by expr with comma
	;
*/

%%	// =================================

void yyerror(const char *msg) {
	printf("Error: %s (line %d)\n", msg, lineno);
}

void syntaxAnalasisLog( const char *msg, int linenoShift ) {
	printf( "line %5d : %s\n", (lineno + linenoShift), msg );
}

int main() {
	freopen( "in.txt", "r", stdin );
	freopen( "out.txt", "w", stdout );
	
	yyparse();
	return 0;
}
