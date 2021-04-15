%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

bool isUnalias = false;
static char* globalEV;
int start = 0;

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
    return "";
}

char* parseForEnv(char* input){
    char returnString[200] = "";
    char envString [200] = ""; 
    bool findingEnv = false;
    printf("input length %d\n" , strlen(input));
    globalEV = input;

    
    

    for (int i = 0 ; i < strlen(input) ; i++){
        printf("current i: %d\n" , i);
        printf("current char %c\n" , input[i]);
        if(findingEnv == false)
        { 
            if(input[i] == '$' ){
                printf("found $\n");
                findingEnv = true;
                printf("wtf %d \n" , findingEnv);
            }
            else{
                printf("no dollar sign, just appending\n");
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
                printf("expanding...\n");
                strncat(envString , &input[i] , 1);
            }

            if(input[i] == '}'){
                
                strcat(returnString , substituteEV(envString));
                findingEnv = false;
                printf("finished expansion\n");
            }
            
            
        }

        if(i + 1 == strlen(input)){
            printf("do i return?\n");
            printf("Was all our hard work worth it: %s\n" , envString);
            printf("Was all our hard work worth it: %s\n" , returnString);
            strcpy(globalEV , returnString);
            printf("fknwork is: %s\n" , globalEV);  
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
%option stack
%x string_condition
%x envVar_condition
%x testing_condition

CHAR            [*?.A-Za-z0-9!~\/_-][*?:.A-Za-z0-9!\/_-]*
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
    start++;


<string_condition>{ANYCHAR}+     {parseForEnv(yytext); yylval.string = strdup(globalEV); return STRING;}
<string_condition>[\"]          {BEGIN(0);}




$\{                 { BEGIN(envVar_condition); }
[\"]                 { BEGIN(string_condition); }



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
"\n"		        { return END; }

"${"{CHAR}+"}"  {
                    parseForEnv(yytext);
                    char *yycopy = strdup( globalEV );
                        for ( int i = strlen(yycopy) - 1; i >= 0; --i ) {
                            unput( yycopy[i] );
                        }
                    free(yycopy);
    
                }

{TILDE}+                { return TILDE;}
{CHAR}+              {if(start == 1 && ifAlias(yytext)) {
                        printf("yytext: %s\n", yytext);
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                    } else {
                        BEGIN(INITIAL);
                        printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                    };
                     }
%%