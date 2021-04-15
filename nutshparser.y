%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>

int yylex(void);
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runUnAlias(char* name);
int runCDHome(char* arg);
int runLs();
int runPWD();
int printENV();
int runSetENV(char* var, char* word);
int runUnSetENV(char* var);
int listAlias();


struct list_node {
    struct list_node  *next;
    char*           value;
};
struct list {
    struct list_node  *head, **tail;
};

struct list *new_list() {
    struct list *rv = malloc(sizeof(struct list));
    rv->head = 0;
    rv->tail = &rv->head;
    return rv; }
void push_back(struct list *list, char* value) {
    struct list_node *node = malloc(sizeof(struct list_node));
    node->next = 0;
    node->value = value;
    *list->tail = node;
    list->tail = &node->next; }

%}

%union {char *string; struct list *list;}

%start cmd_line
%token <string> BYE CD STRING WORD ALIAS UNALIAS TILDE LS PWD PENV SENV UENV TEST META END 
%type <list> foobar   
%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| CD END                       {printf("it me");runCDHome("~"); return 1;}
	| CD TILDE END                 {runCDHome($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2,$3); return 1;}
	| ALIAS                        {listAlias(); return 1;}
	| UNALIAS STRING END           {runUnAlias($2); return 1;}
	| PENV END                     	{printENV(); return 1;}
	| SENV STRING STRING END     	{runSetENV($2,$3); return 1;}
	| UENV STRING END            	{runUnSetENV($2); return 1;}
	| LS END 						{runLs(); return 1;}
	| PWD END                       {runPWD(); return 1;}
	| TEST END						{printf("Hi"); return 1;}
	| foobar END 					{$1-> head = $1 -> head -> next; printf("in foobar end\n"); startCommand,commandIndex,argIndex = 0;return 1;};

foobar :

	| STRING 					{push_back($$ = new_list() , $1); assignToStruct($1);}
	| foobar STRING				{push_back($1 , $2); $$ = $1; assignToStruct($2); startCommand++;} 

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int assignToStruct(char *nodeValue){
	printf("in here%d\n",startCommand);
	struct nonbuiltin foo;
	// char constants
	char pipe[1] = "|";
	char lAngle[1] = "<";
	char dubLAngle[1] = "<<";
	char rAngle[1] = ">";
	char dubRAngle[1] = ">>";
	char amp[1] = "&";
	char test[100];

	printf("this is node value : %s\n", nodeValue);

	
	if(startCommand == 0){
		strcpy(foo.command, nodeValue);
		printf("this is da ting : %s\n" , foo.command);
		commandIndex++;
		printf("hi\n");
	}
	if(strcmp(nodeValue, pipe) == 0){
		printf("FOUND A PIPE\n");
		startCommand = -1; // one  away from reading cmd
	}
	else if(strcmp(nodeValue, lAngle) == 0){
		printf("FOUND A LANGLE\n");
		strcpy(foo.command, nodeValue);
		printf("this is da ting : %s\n" , foo.command);
	}
	else if(strcmp(nodeValue, dubLAngle) == 0){
		strcpy(foo.command, nodeValue);
		printf("this is da ting : %s\n" , foo.command);
	}
	else if(strcmp(nodeValue, rAngle) == 0){
		strcpy(foo.command, nodeValue);
		printf("this is da ting : %s\n" , foo.command);
	}
	else if(strcmp(nodeValue, dubRAngle) == 0){
		strcpy(foo.command, nodeValue);
		printf("this is da ting : %s\n" , foo.command);
	}
	else if(strcmp(nodeValue, amp) == 0){
		strcpy(foo.command, nodeValue);
		printf("this is da ting : %s\n" , foo.command);
	}
	else{
		strcpy(foo.args[argIndex] , nodeValue);
		argIndex++;
	}
	printf("arg index is %d\n", argIndex);
	for(int i = 0; i < argIndex ; i++){
		printf("%s,",foo.args[i]);
	}

}


int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
		if(arg[0] == '.' && arg[1] == '.'){
			char s[100];
			chdir(arg);
			strcpy(varTable.word[0], getcwd(s, 100));
			runPWD();
			return 1;
			
		}
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			return 1;
		}
		else {
			getcwd(cwd, sizeof(cwd));
			strcpy(varTable.word[0], cwd);
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(varTable.word[0], arg);
			return 1;
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
}

int runCDHome(char* arg){
	strcpy(varTable.word[0], getenv("HOME"));
	chdir(getenv("HOME"));
	printf("Current working dir: %s \n" , varTable.word[0]);
	return 1;
}

int runLs() {
	printf("trying to run ls");
	DIR *directory_;
	struct dirent *myfile;
	struct stat mystat;  // idk if we need to include -al support 

	directory_ = opendir(getcwd(cwd,sizeof(cwd)));

	while((myfile = readdir(directory_)) != NULL){
		printf("%s\n" , myfile->d_name);
	}

	closedir(directory_);
	return 1;
}

int runPWD(){
	printf("Current working dir: %s\n", varTable.word[0]);
	return 1;
}

int printENV(){
	for(int i =0; i < varTableLength;i++){
		if(varTable.var[i]!=NULL && varTable.word[i] != NULL){
			printf("%s=%s\n", varTable.var[i],varTable.word[i]);
		}
	}
	return 1;
}

int listAlias(){
	for(int i = 0; i < aliasIndex;i++){
		if(aliasTable.name[i]!=NULL && aliasTable.word[i] != NULL){
			printf("%s=%s\n", aliasTable.name[i],aliasTable.word[i]);
		}
	}
	return 1;
}

int runSetENV(char* var, char* word){

	for (int i = 0; i < varIndex; i++) {

		if((strcmp(varTable.var[i], var) == 0) && (strcmp(varTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", var);
			return 1;
		}  
		else if(strcmp(varTable.var[i], var) == 0) {
			strcpy(varTable.word[i], word);
			return 1;
		}
	}
	strcpy(varTable.var[varIndex], var);
	strcpy(varTable.word[varIndex], word);
	varIndex++;
	varTableLength++;
	return 1;
}

int runUnSetENV(char* var){
    for (int i = 0; i < varIndex; i++) {
		if(strcmp(varTable.var[i], var) == 0) {
			strcpy(varTable.var[i], "");
			strcpy(varTable.word[i], "");
			varIndex--;
			varTableLength--;
			return 1;
		}
	}
	return 1;
}

int runUnAlias(char* name){
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.name[i], "");
			strcpy(aliasTable.word[i], "");
			aliasIndex--;
			return 1;
		}
	}
	return 1;	
}

int runSetAlias(char *name, char *word) {
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}
	strcpy(aliasTable.name[aliasIndex], name);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}