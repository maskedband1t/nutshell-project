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
int listAlias(struct file_struct* file);


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

%union {
	char *string; 
	struct list *list;
	struct file_struct* f;
	int symbol;
}

%start cmd_line
%token <string> BYE CD STRING WORD ALIAS UNALIAS TILDE LS PWD PENV SENV UENV TEST META END 
%token <symbol>  LANGLE, RANGLE DUBR_ANGLE PIPE
%type <list> foobar   
%type<f> file_out
%%
cmd_line    :
	BYE END 		                {balls = false; exit(1); return 1; }
	| CD STRING END        			{balls = false; runCD($2); return 1;}
	| CD END                       {balls = false;runCDHome("~"); return 1;}
	| CD TILDE END                 {balls = false; runCDHome($2); return 1;}
	| ALIAS STRING STRING END		{printf("HUHHH");balls = false; runSetAlias($2,$3); return 1;}
	| ALIAS file_out END                    {balls = false; listAlias($2); return 1;}
	| UNALIAS STRING END           {balls = false; runUnAlias($2); return 1;}
	| PENV END                     	{balls = false; printENV(); return 1;}
	| SENV STRING STRING END     	{balls = false; runSetENV($2,$3); return 1;}
	| UENV STRING END            	{runUnSetENV($2); return 1;}
	| LS END 						{runLs(); return 1;}
	| PWD END                       {runPWD(); return 1;}
	| TEST END						{printf("Hi"); return 1;}
	| foobar END 					{$1-> head = $1 -> head -> next; startCommand,commandIndex = 0;return 1;};

foobar :

	| STRING 					{balls = true;push_back($$ = new_list() , $1); assignToStruct($1);}
	| foobar STRING				{push_back($1 , $2); $$ = $1; assignToStruct($2); startCommand++;} 

file_out :                          { $$ = NULL; }
        | DUBR_ANGLE STRING         { $$ = create_file_struct($2, 0); }
        | RANGLE STRING            	{ $$ = create_file_struct($2, 1); }

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int assignToStruct(char *nodeValue){
	struct nonbuiltin foo;
	// char constants
	char pipe[1] = "|";
	char testlAngle[1] = "<";
	char testdubLAngle[1] = "<<";
	char testrAngle[1] = ">";
	char testdubRAngle[1] = ">>";
	char amp[1] = "&";
	char test[100];


	
	if(startCommand == 0){
		strcpy(foo.command, nodeValue);
		commandIndex++;
	}
	if(strcmp(nodeValue, pipe) == 0){
		startCommand = -1; // one  away from reading cmd
	}
	else if(strcmp(nodeValue, amp) == 0){
		strcpy(foo.command, nodeValue);
	}
	else{
		strcpy(foo.args[argIndex] , nodeValue);
		argIndex++;
	}

	
	struct cmdNode* cur = malloc(sizeof(struct cmdNode));
	cur -> command = foo;

	// adding node to command lsit

	if(cmd_list.head == NULL){
		printf("hi its me\n");
		cmd_list.head = cur;
		cmd_list.head -> next = NULL;

	}
	else{
		// printf("mem address of tail: %d\n" , (int)cmd_list.tail);

		// struct cmdNode* temp = malloc(sizeof(struct cmdNode));
		// temp = cmd_list.head;

		// while(temp -> next != NULL){
		// 	printf("passing node: %s\n" , temp->command.command);
		// 	temp = temp -> next;
		// }
		// printf("prolly here\n");
		// temp->next = cur;
		



		// if((int)cmd_list.tail == 0){
		// 	printf("do i get called?\n");
		// 	cmd_list.tail = cur;
		// 	cmd_list.tail -> next = NULL;

		// }

	}

	printf("head is: %s\n" , cmd_list.head->command.command);


	struct cmdNode* temp = malloc(sizeof(struct cmdNode));
	temp = cmd_list.head;


	while(temp != NULL ){

		printf("One node is: %s\n" , temp->command.command);
		temp = temp->next;
	}

	current = foo;

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

int listAlias(struct file_struct* file){
	if (file != NULL) {
		
        char *mode = "w";
        if(file->type == 0) {
            mode = "a";
        }
        FILE *new_file = fopen(file->name, mode); // opens file
        if (new_file != NULL) {
            for (int i = 0; i < aliasIndex; i++) {
				fputs(aliasTable.name[i], new_file);
				fputs("=", new_file);
				fputs(aliasTable.word[i], new_file);
				fputs("\n", new_file);
        	}        
        	fclose(new_file);
        }
        return 1;
    }

	for(int i = 1; i < aliasIndex;i++){
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