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

    printf("num paths is: %d\n" , num_paths);

    char* pathsArr [num_paths];



    char* currentPath = strtok(varTable.word[3] , ":");
    
    pathsArr[0] = currentPath;

    
    for (int i = 1 ; i < num_paths ; i++){
        currentPath = strtok(NULL , ":");
        pathsArr[i] = currentPath;
    }

    for(int i = 0 ; i < num_paths; i++){
        printf("One path: %s\n" , pathsArr[i]);
    }

    printf("Please don't be . : %s\n" , ogPath);

    strcpy(varTable.word[3] , ogPath);


    // ? from here , we need to check each path and see if there exists an executable in that path. If so, then use execv with that given path. 
    // ! might need to make path_vars struct, hopefully not tho
    

 
    printf("calling execv...\n");

    char* arr[argIndex + 1];

    for(int i = 0 ; i < argIndex ; i++){
        arr[i] = command.args[i];
    }

    arr[argIndex] = NULL;

    


    int pid = fork();

    if(pid == 0){
        // child process
            ret = execv("/usr/bin/echo" , arr);
    }
    wait(2);

    printf("hopefully didnt close\n");
    argIndex = 0;
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