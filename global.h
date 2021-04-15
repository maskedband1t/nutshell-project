#include "stdbool.h"
#include <limits.h>


int varTableLength;
int startCommand;

struct Node {
    char* data ;
    struct Node* next ;
};

struct nonbuiltin {
    char args[128][100] ;
    char command[100];
 };
 struct commandpipeline{
     struct nonbuiltin commands;
     struct nonbuiltin head;
 };

// for each command in commandpipeline.commands {
//     execve(command.command , command.args);
// }

struct evTable {
   char var[128][100];
   char word[128][100];
};

struct aTable {
	char name[128][100];
	char word[128][100];
};

char cwd[PATH_MAX];

struct evTable varTable;

struct aTable aliasTable;

struct nonbuiltin current;

bool balls;


int aliasIndex, varIndex , commandIndex, argIndex;

char* subAliases(char* name);