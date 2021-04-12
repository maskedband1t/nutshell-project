%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"

char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}
bool ifAlias(char* name){
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
%}
%array
%option noyywrap
%x string_condition
%x envVar_condition

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR            [)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][ )(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
META [><|\&]
QUOTE ["]
NOTQUOTE [^"]
TILDE [~]
PERIOD [.]
ENV [$]
LCURLY [{]
RCURLY [}]


%%

<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

$\{                 { BEGIN(envVar_condition); }
[\"]                 { BEGIN(string_condition); }

<envVar_condition>{CHAR}+ {
        yylval.string = strdup(substituteEV(yytext));
        printf("%s\n",yylval.string);
    }
<envVar_condition>{RCURLY}        {BEGIN(INITIAL);}

[ ]		            { }
bye                 { return BYE; }
cd		            { return CD;}
alias		        { return ALIAS; }
unalias             {return UNALIAS;}
ls                  {return LS;}
pwd                 {return PWD;}
printenv            {return PENV;}
setenv              {return SENV;}
unsetenv            {return UENV;}
"\n"		        { return END; }

{TILDE}+                { return TILDE;}
{CHAR}+              {if(ifAlias(yytext)) {
                        printf("yytext: %s\n", yytext);
                        //source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
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
%%