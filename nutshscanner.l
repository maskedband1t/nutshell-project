%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

bool isUnalias = false;
static char* globalEV;
static char  arguments[100] = "";
static struct Node* previous = NULL;
static struct Node* head = NULL;
static struct Node* tail = NULL;

char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
    if(isUnalias == true){
        isUnalias = false;
        return false;
    }
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}

char* substituteEV(char* name){
    for(int i =0; i < varIndex; i++){
        if(strcmp(varTable.var[i], name) == 0){
            return varTable.word[i];
        }
    }
}

struct Node* appendToLL(struct Node* tail ,struct Node* node){
    printf("trying to append\n");
    if(tail->next == NULL){
        tail->next = node;
    }
    else{
        printf("you didnt give me a tail!\n");
        printf("next is: %s\n" , tail->next);
    }

    return tail;
}

char* parseForEnv(char* input){
    char returnString[200] = "";
    char envString [200] = ""; 
    bool findingEnv = false;
    globalEV = input;

    
    

    for (int i = 0 ; i < strlen(input) ; i++){

        if(findingEnv == false)
        { 
            if(input[i] == '$' ){
                findingEnv = true;
            }
            else{
                strncat(returnString , &input[i] , 1);
            }
            if(i + 1 == strlen(input)){
                strcpy(globalEV , returnString);
                return &returnString;
            }
            else{
                continue;
            }
            
        }
        else{
            if(input[i] != '{' && input[i] != '}'){
                strncat(envString , &input[i] , 1);
            }

            if(input[i] == '}'){
                
                strcat(returnString , substituteEV(envString));
                findingEnv = false;
            }
            
            
        }

        if(i + 1 == strlen(input)){
    
            return &returnString;
        }
        else{
            continue;
        }

 
    }

   
}

%}
%array
%option noyywrap
%x string_condition
%x envVar_condition

CHAR            [&><|.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR            [$}{)(*&%#@!`;,\.a-zA-Z0-9'/*_=~ -][ $)(}{*&%#@!`;,\.a-zA-Z0-9'/*_=~ -]*
META [><|\&]
QUOTE ["]
NOTQUOTE [^"]
TILDE [~]
PERIOD [.]
ENV [$]
LCURLY [{]
RCURLY [}]


%%



<string_condition>{ANYCHAR}+     {parseForEnv(yytext); yylval.string = strdup(globalEV); return STRING;}
<string_condition>[\"]          {BEGIN(0);}




$\{                 { BEGIN(envVar_condition); }
[\"]                 { BEGIN(string_condition); }

<envVar_condition>{CHAR}+ {
        yylval.string = strdup(substituteEV(yytext));
        printf("%s\n",yylval.string);
        return STRING;
    }
<envVar_condition>{RCURLY}        {BEGIN(INITIAL);}


[ ]		            { }
bye                 { return BYE; }
cd		            { return CD;}
alias		        { return ALIAS; }
unalias             {isUnalias = true; return UNALIAS;}
ls                  {return LS;}
pwd                 {return PWD;}
printenv            {return PENV;}
setenv              {return SENV;}
unsetenv            {return UENV;}
mkdir             {yylval.string = strdup(yytext) ; return STRING;}
"\n"		        { return END; }

{TILDE}+                { return TILDE;}
{CHAR}+              {if(ifAlias(yytext)) {
                        printf("yytext: %s\n", yytext);
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                    } else {
                        printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                    };
                     }
{META}*        {return META;}
%%