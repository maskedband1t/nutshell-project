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



    struct cmd_group* group = malloc(sizeof(struct cmd_group));
    group->grouping =  grouping;
    group->next = NULL;
    return group;

}

struct cmd_pipeline* create_pipeline_LL(struct cmd_group* group){
    struct cmd_pipeline* head = malloc(sizeof(struct cmd_pipeline));
    head->group = group;
    head->next = NULL;
    return head;
}
// ! need a function that takes in all args in commandpipeline and executes execve for all of them 

int sendToExec(struct cmd_pipeline* pipeline, int nodeCount, char* file_in, struct file_struct* file_out, int background){
    struct cmd_pipeline* test = malloc(sizeof(struct cmd_pipeline));
    test = pipeline;
    int count = 0;
    int ret = 0;

    char* fknwork[nodeCount] ;

    struct cmd_group* allGroups[nodeCount];
    allGroups[0] = NULL;


    
   
    while(test != NULL){
        count++;
        allGroups[count] = test -> group;
        test = test->next;
    }



    // !! this is how we need to parse our PATH variable 

    char pathDelimited[100] = "";
    char* pathJ = strdup(varTable.word[3]);
    char* ogPath = strdup(varTable.word[3]);
    char* holder = strdup(varTable.word[3]);

    int num_paths = 1;

    while(*pathJ != '\0'){
        if(*pathJ == ':'){
            num_paths++;
        }
        pathJ++;
    }


    char* pathsArr [num_paths];



    char* currentPath = strtok(holder , ":");
    
    pathsArr[0] = currentPath;


    
    for (int i = 1 ; i < num_paths ; i++){
        currentPath = strtok(NULL , ":");
        pathsArr[i] = currentPath;
    }


    // go in each command
     // i.e running echo command 
    // 1. go thru each path and append the command and call access on that path. if its ok then i use that path 

    int pipefd[2] , status , done = 0;
    pid_t cpid;
    struct cmd_pipeline* temp = malloc(sizeof(struct cmd_pipeline));
    temp = pipeline;
    pipe(pipefd);
    char** curGroup = temp -> group -> grouping;
    char* correctPath = "";

    bool pain = false;


    for (int i = 0 ; i < nodeCount ; i++){
        cpid = fork();
        if(cpid == 0){
            if (i == 0){

                if (file_in != NULL) {
                    FILE *new_file = fopen(file_in, "r");
                    if (new_file != NULL) {
                        int file_no = fileno(new_file);
                        dup2(file_no, STDIN_FILENO);
                        close(file_no);
                    }
                }
                // get no stdin from pipe
                curGroup = temp -> group -> grouping;
                close(pipefd[0]);
                if(nodeCount != 1){
                    
                    dup2(pipefd[1] , STDOUT_FILENO);
                }
                else{
                    // if this is the only command, check if theres a file_out where the output should go to. will go to stdout otherwise
                    if (file_out != NULL) {
                        char *mode = "w";
                        if (file_out->type == 0) {
                            mode = "a";
                        }

                        FILE *new_file = fopen(file_out->name, mode);
                        if (new_file != NULL) {
                            int file_no = fileno(new_file);
                            dup2(file_no, STDOUT_FILENO);
                            close(file_no);
                        }
                }
                }

                
                

               
                correctPath = "";
                // printf("ooooooooooooo\n");

                for(int v = 0 ; v < num_paths; v++){
                    char* tempPath = strdup(pathsArr[v]);
                    if(strcmp(tempPath, ".") ==   0){
                        tempPath = strdup(varTable.word[0]); // should be current working directory
                    }
                    strcat(tempPath , (char*) "/");
                    strcat(tempPath , curGroup[0]);
                    // printf("temp path is%s\n",tempPath);

                    if(access(tempPath , F_OK) == 0){
                        correctPath = strdup(tempPath);
                        // printf("!! %s\n" , correctPath);
                        break;
                    }

                }
 
            execv(correctPath , curGroup);
            }
            else if (i == nodeCount - 1){
                // dont send output to pipe , rather to stdout or file if file_out

                if (file_in != NULL) {
                    FILE *new_file = fopen(file_in, "r");
                    if (new_file != NULL) {
                        int file_no = fileno(new_file);
                        dup2(file_no, STDIN_FILENO);
                        close(file_no);
                    }
                }
                
                close(pipefd[1]);
                dup2(pipefd[0] , STDIN_FILENO);
                if (file_out != NULL) {
                printf("trying to send output to file \n" );
                char *mode = "w";
                if (file_out->type == 0) {
                    mode = "a";
                }

                // will send to an output file if one is specified
                FILE *new_file = fopen(file_out->name, mode);
                if (new_file != NULL) {
                    int file_no = fileno(new_file);
                    dup2(file_no, STDOUT_FILENO);
                    close(file_no);
                }
                }

                curGroup = allGroups[i + 1] -> grouping;
                printf("command should be wc: %s\n" , curGroup[0]);
                correctPath = "";
      
                
                for(int v = 0 ; v < num_paths; v++){
                    printf("wtf %s\n" , curGroup[0]);
                    char* tempPath = strdup(pathsArr[v]);
                    strcat(tempPath , (char*) "/");
                    printf("???\n");
                    strcat(tempPath , curGroup[0]);
                    printf("temp path is%s\n",tempPath);
                    // .:./testdir => cwd && cwd/testdir

                    if(access(tempPath , F_OK) == 0){
                        correctPath = strdup(tempPath);
                        break;
                    }

                }
           
            printf("never gonna log\n");
            printf("?? %s\n" , correctPath);
            execv(correctPath , curGroup);

            }
            else{
                // anything in between , gets in from pipe and sends out to pipe
                dup2(pipefd[1] , STDOUT_FILENO);
                dup2(pipefd[0] , STDIN_FILENO);
               
                curGroup = allGroups[i+1] -> grouping;
                printf("command should be grep : %s\n" , curGroup[0]);
                correctPath = "";

                for(int v = 0 ; v < num_paths; v++){
                    char* tempPath = strdup(pathsArr[v]);
                    strcat(tempPath , (char*) "/");
                    strcat(tempPath , curGroup[0]);
                    printf("temp path is%s\n",tempPath);

                    if(access(tempPath , F_OK) == 0){
                        correctPath = strdup(tempPath);
                        printf("correct path is%s\n",correctPath);
                        break;
                    }

                }
      
            execv(correctPath , curGroup);

            }


        }
    }
    close(pipefd[0]);
    close(pipefd[1]);
    
    waitpid(-1 , &status , 0);
    waitpid(-1 , &status , 0);

    

    // cpid = fork();

    // if(cpid == 0){
    //     // left side of pipe
    //     close(pipefd[0]);
    //     dup2(pipefd[1] , STDOUT_FILENO);

    //     char** curGroup = temp -> group -> grouping;
    //     char* correctPath = "";

    //     for(int v = 0 ; v < num_paths; v++){
    //         char* tempPath = strdup(pathsArr[v]);
    //         strcat(tempPath , (char*) "/");
    //         strcat(tempPath , curGroup[0]);
    //         printf("temp path is%s\n",tempPath);

    //         if(access(tempPath , F_OK) == 0){
    //             correctPath = strdup(tempPath);
    //             break;
    //         }

    //     }

    //     execv(correctPath , curGroup);

    // }
    // cpid = fork();
    // if(cpid == 0){
    //     //right side of pipe
    //     close(pipefd[1]);
    //     dup2(pipefd[0] , STDIN_FILENO);
    //     temp = temp -> next;

    //     char** curGroup = temp -> group -> grouping;
    //     char* correctPath = "";

    //     for(int v = 0 ; v < num_paths; v++){
    //         char* tempPath = strdup(pathsArr[v]);
    //         strcat(tempPath , (char*) "/");
    //         strcat(tempPath , curGroup[0]);
    //         printf("temp path is%s\n",tempPath);

    //         if(access(tempPath , F_OK) == 0){
    //             correctPath = strdup(tempPath);
    //             break;
    //         }

    //     }

    //     execv(correctPath , curGroup);
    // }

    // close(pipefd[0]);
    // close(pipefd[1]);

 
}

int runNonBuilt(struct nonbuiltin command){
    printf("its ya boy");

    int ret;

    // !! this is how we need to parse our PATH variable 

    char pathDelimited[100] = "";
    char* path = strdup(varTable.word[3]);
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


        // child process
    ret = execv(correctPath , arr);
    wait(2);

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
        // if(balls == true){
        //     printf("yoyoyo\n");
        //     runNonBuilt(current);
        // }
        printf("[%s]>> ", varTable.word[2]);
        yyparse();
    }

   return 0;
}