#include "stdbool.h"
#include <limits.h>


int varTableLength;
int startCommand;

 struct file_struct {
    char* name;
    int type;
};
struct linked_list {
    struct linked_list  *next;
    char*           value;
};

struct cmd_group {
    char** grouping;
    struct cmd_group* next;
};

struct cmd_pipeline {   // acts as a linked list
    struct cmd_group* group;
    struct cmd_pipeline* next;
};


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

struct file_struct* create_file_struct(char* name, int type);
struct linked_list* create_LL(const char *value);
struct cmd_group* create_cmd_group(char* cmd, struct linked_list* args);
struct cmd_pipeline* create_pipeline_LL(struct cmd_group* group);
int sendToExec(struct cmd_pipeline* pipeline, int nodeCount, char* file_in ,  struct file_struct* file_out, int background);


int aliasIndex, varIndex , commandIndex, argIndex;

char* subAliases(char* name);