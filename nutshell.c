// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "global.h"
#include <unistd.h>

char *getcwd(char *buf, size_t size);
int yyparse();

struct file_struct* create_file_struct(char* name, int type) {
    struct file_struct* output = malloc(sizeof(struct file_struct));
    output->name = malloc(1024 * sizeof(char)); // mem safe
    output->type = type;
    strcpy(output->name, name);
    printf("name: %s\n", strdup(output->name));
    printf("type: %d\n", output->type);
    return output;
}

struct linked_list* create_LL(const char *value){
    struct linked_list* ll = malloc(sizeof(struct linked_list));
        ll->value = malloc(1024 * sizeof(char));
        ll->next = NULL;
        strcpy(ll->value, value);
        return ll;
}

struct cmd_group* create_cmd_group(char* cmd, struct linked_list* args){
    //first find how many arguments in args
    int count = 0;
    struct linked_list* temp = args;
    while(temp != NULL){
        count++;
        temp = temp->next;
    }
    return count;

    char **grouping = malloc((2 + count) * sizeof(struct linked_list*));

    grouping[0] = malloc(sizeof(char) * 1024);
    strcpy(grouping[0], cmd);         // first cmd, last null , everything in middle is args for execv
    //populate the middle

    struct linked_list* temp2 = args;
    for(int i = 1; temp2 != NULL && i < count + 1; i++){
        grouping[i] = malloc(sizeof(char) * 1024);
        strcpy(grouping[i] , temp2->value);
        temp2 = temp2->next;
    }

    grouping[count + 1] = (char *) NULL; // last as null

    struct cmd_group* group = grouping;
    return group;

}

struct cmd_pipeline* create_pipeline_LL(struct cmd_group* grouping){
    struct cmd_pipeline* head = malloc(sizeof(struct cmd_pipeline));

    head->group = grouping;
    head->next = NULL;
    return head;
}
// ! need a function that takes in all args in commandpipeline and executes execve for all of them 

int runNonBuilt(struct nonbuiltin command){
    

    int ret;

    // !! this is how we need to parse our PATH variable 

    char pathDelimited[100] = "";
    char* path = varTable.word[3];
    char* ogPath = strdup(varTable.word[3]);


    int num_paths = 1;

    while(*path != '\0'){
        if(*path == ':'){
            num_paths++;
        }
        path++;
    }


    char* pathsArr [num_paths];



    char* currentPath = strtok(varTable.word[3] , ":");
    
    pathsArr[0] = currentPath;


    
    for (int i = 1 ; i < num_paths ; i++){
        currentPath = strtok(NULL , ":");
        pathsArr[i] = currentPath;
    }








    // ? from here , we need to check each path and see if there exists an executable in that path. If so, then use execv with that given path. 
    // ! might need to make path_vars struct, hopefully not tho


    // i.e running echo command 
    // 1. go thru each path and append the command and call access on that path. if its ok then i use that path 

    char* correctPath = "";

    for(int i = 0 ; i < num_paths; i++){
        char* tempPath = strdup(pathsArr[i]);
        strcat(tempPath , (char*) "/");
        strcat(tempPath , command.args[0]);

        if(access(tempPath , F_OK) == 0){
            correctPath = strdup(tempPath);
            break;
        }
        
    }

    if(strcmp(correctPath , (char*)"") == 0){
        // means we didnt find an exe in any of the paths in PATH
        printf("nah son try another command \n");

    }









 
    printf("calling execv...\n");

    char* arr[argIndex + 1];

    for(int i = 0 ; i < argIndex ; i++){
        arr[i] = command.args[i];
    }

    arr[argIndex] = NULL;

    strcpy(varTable.word[3] , ogPath);



    int pid = fork();

    if(pid == 0){
        // child process
            ret = execv(correctPath , arr);
    }
    wait(2);

    argIndex = 0;

    balls = false;
    return 0;
}

int main()
{
    aliasIndex = 0;
    varIndex = 0;
    commandIndex = -1;
    argIndex = 0;
    varTableLength = 0;
    startCommand = 0;

    getcwd(cwd, sizeof(cwd));

    strcpy(varTable.var[varIndex], "PWD");
    strcpy(varTable.word[varIndex], cwd);
    varIndex++;
    varTableLength++;
    strcpy(varTable.var[varIndex], "HOME");
    strcpy(varTable.word[varIndex], cwd);
    varIndex++;
    varTableLength++;
    strcpy(varTable.var[varIndex], "PROMPT");
    strcpy(varTable.word[varIndex], "nutshell");
    varIndex++;
    varTableLength++;
    strcpy(varTable.var[varIndex], "PATH");
    strcpy(varTable.word[varIndex], ".:/bin:/usr/bin");
    varIndex++;
    varTableLength++;

    strcpy(aliasTable.name[aliasIndex], ".");
    strcpy(aliasTable.word[aliasIndex], cwd);
    aliasIndex++;

    system("clear");
    while(1)
    {
        if(balls == true){
            printf("yoyoyo\n");
            runNonBuilt(current);
        }
        printf("[%s]>> ", varTable.word[2]);
        yyparse();
    }

   return 0;
}