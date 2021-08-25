#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#include "int.h"
#include "event.h"
#include "user_plugin/fdtd/fdtd.h"

#include "parameter.h"
#include "field_source.h"
#include "coefficients.h"
#include "golden_data.h"

#define IRQ_UP_IDX 		22

#define mb() __asm__ __volatile__ ("" : : : "memory")

// Reference: https://stackoverflow.com/a/3437484/2419510
#define max(a,b) \
    ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
       _a > _b ? _a : _b; })

#define min(a,b) \
    ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
       _a < _b ? _a : _b; })

/*----------------------fdtd logic-----------------------------------//
//This program demonstrates a one-dimensional FDTD simulation.
//The problem geometry is composed of two PEC plates extending to
//infinity in y, and z dimensions, parallel to each other with 1 meter
//separation. The space between the PEC plates is filled with air.
//A sheet of current source paralle to the PEC plates is placed at the 
//center of the problem space. The current source excites fields 
//in the problem space due to a z-directed current density Jz, which has
//a Gaussian waveform in time. 
//Here is the software control part of a one-dimensional FDTD 
//method for SOC hardware implementation, no absorption boundary 
//is added, and the boundary location is set to PEC medium.
//-------------------------------------------------------------------*/
// Must use volatile,
// because it is used to communicate between IRQ and main thread.
volatile int g_up_int_triggers = 0;

void ISR_UP() {
    // Clear interrupt within user plugin peripheral
    FDTD_CMD = FDTD_CMD_CLR_INT_BIT;
    ICP = 1 << IRQ_UP_IDX;

    ++g_up_int_triggers;
    printf("In User Plugin interrupt\n");
}

//loading field_source(point source)
void load_field_source(int current_timestep){
    //
    printf("load field source data!!!\n");
    //
    FDTD_SOURCE = source[current_timestep];
}

//define problem space size
//Allocate some more space here to solve the transmission boundary problem
int Hy[GRID_SIZE+UNUSED_SIZE];
int Ez[GRID_SIZE+UNUSED_SIZE];

void initialize_field_space(int word_n){
    printf("Initialize problem space!!!\n");
    for (size_t i = 0; i < sizeof(Hy)/sizeof(Hy[0]); ++i){
        Hy[i] = 0;
    }
	mb();
    for (size_t j = 0; j < sizeof(Ez)/sizeof(Ez[0]); ++j){
        Ez[j] = 0;
    }
	mb();

    FDTD_HY_ADDR = (int)Hy;
    FDTD_EZ_ADDR = (int)Ez;
    FDTD_SIZE = word_n;
}

void read_coefficient(){
    //    
    printf("Read the correlation coefficients!!!\n");
    //Assign values to the coefficient terms in the update process
    FDTD_CEZE  = coes[0];
    FDTD_CEZHY = coes[1];
    FDTD_CEZJ  = coes[2];
    FDTD_CHYH  = coes[3];
    FDTD_CHYEZ = coes[4];
    FDTD_CHYM  = coes[5];
    FDTD_COE0  = coes[6];
}

void update_Hy_process(int src_position){
    //
    FDTD_CALC_HY_SGL = FDTD_CALC_TRIGGER_BIT;
    while(1){
        int calc_Hy_status = FDTD_CALC_HY_SGL;
        printf("calc_Hy_status:%d. <_>\n",calc_Hy_status);
        if(calc_Hy_status){
    	    printf("update_status:having Hy calculation process. >_<!!!\n");
        }else {
            break;
        }
    }
    printf("this position's Hy field_value is: Hy[%d] = %d, Hy[%d] = %d, Hy[%d] = %d, Hy[%d] = %d .\n",
            0,Hy[0],
            src_position-1, Hy[src_position-1],
            src_position, Hy[src_position],
            GRID_SIZE-1,Ez[GRID_SIZE-1]
			);
    FDTD_CALC_HY_SGL = FDTD_CALC_CLR_BIT;
}

void update_Ez_process(int src_position){
    FDTD_CALC_EZ_SGL = FDTD_CALC_TRIGGER_BIT;
    while(1){
        int calc_Ez_status = FDTD_CALC_EZ_SGL;
	    printf("calc_Ez_status:%d. <_>\n",calc_Ez_status);
	    if(calc_Ez_status){
		    printf("update_status:having Ez calculation process. >_<!!!\n");
        }else {
            break;
        }	
    }
    printf("this position's Ez field_value is: Ez[%d] = %d, Ez[%d] = %d, Ez[%d] = %d, Ez[%d] = %d .\n",
            1,Ez[1],
            src_position, Ez[src_position],
            OBSERVATION_POINT-1,Ez[OBSERVATION_POINT-1],	
            GRID_SIZE,Ez[GRID_SIZE]
            );
    FDTD_CALC_EZ_SGL = FDTD_CALC_CLR_BIT;
}

void update_src_process(int src_position){
    FDTD_EZ_ADDR =  (int)(Ez + src_position);
    FDTD_CALC_SRC_SGL = FDTD_CALC_TRIGGER_BIT;
    while(1){
	    int calc_src_status = FDTD_CALC_SRC_SGL;
	    printf("calc_src_status:%d. <_>\n",calc_src_status);
	    if(calc_src_status){
    	    printf("update_status:having src calculation process. >_<!!!\n");
        }else {
            break;
        }
    }
    printf("this position's Ez field_value is: Ez[%d] = %d .\n",src_position,Ez[src_position]);
    FDTD_EZ_ADDR =  (int)Ez;
    FDTD_CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
}

void update_field_process(int src_position, int* errors ){
    //	
    FDTD_CALC_HY_SGL  = FDTD_CALC_CLR_BIT;
    FDTD_CALC_EZ_SGL  = FDTD_CALC_CLR_BIT;   
    FDTD_CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
    //
    update_Hy_process (src_position-1);
	//
    update_Ez_process (src_position-1);
	//
    update_src_process(src_position-1);
	//
    while (1) {
        if (g_up_int_triggers != 0) {
            break;
        }
    }   
}

//Set up observation points to collect data
int observation_data[NUMBER_OF_TIME_STEPS]; 

void sample_data(int i){ 
    //
    observation_data[i] = Ez[OBSERVATION_POINT-1];
}

//Performing data error comparisons
#define FIXED_POINT_5E_NEG_3 0x000028F6
void compare_observation_point_error(unsigned int number_of_time_steps, unsigned int number_of_cases, int* errors){
    int abs_error;
    int temp_data[number_of_time_steps];
    printf("Perform comparison of calculated data errors. !!!\n");
    switch (number_of_cases){
    case 0:
        for(size_t i = 0; i < number_of_time_steps; ++i){
            temp_data[i] = check_data_v0[i];
        }
        break;
    case 1:
        for(size_t i = 0; i < number_of_time_steps; ++i){
            temp_data[i] = check_data_v1[i];
        }
        break;
    case 2:
        for(size_t i = 0; i < number_of_time_steps; ++i){
            temp_data[i] = check_data_v2[i];
        }
        break;
    }
    for (size_t i = 0; i < number_of_time_steps; ++i){
        abs_error = abs(temp_data[i]-observation_data[i]);
        if (abs_error > FIXED_POINT_5E_NEG_3){
            ++(*errors);
            printf("This position's Ez field_value is: Ez[%d] = %d .\n",i,observation_data[i]);
            printf("There is a problem with the calculation process,please debug:abs_error[%d] = %d. !!!\n",i,abs_error);
        }else {
            printf("Congratulations, pass[%d]!!!\n",i);
        }
    }
}

//Iterative update process
void run_fdtd_loop(unsigned int number_of_time_steps, int src_position, int* errors){
    FDTD_START_CALC_SGL = FDTD_CALC_CLR_BIT;
    printf("Having fdtd loop!!!\n");
    for (size_t i = 0; i < number_of_time_steps; ++i){
        //Start the entire iterative process
        printf("---------The current timestep is %d .---------\n",i+1);
        //	
        g_up_int_triggers = 0;
        mb();
        // Enable interrupt
        FDTD_CMD = FDTD_CMD_TRIGGER_BIT;
        FDTD_CTRL = FDTD_CTRL_INT_EN_BIT; 
        //load field source
        //The coefficients here are related to the actual project
        //The simplest way to join the field_source (point source) is implemented here
        load_field_source(i);
        //
        //trigger hardware's calculation of updating field_value
        FDTD_START_CALC_SGL = FDTD_CALC_TRIGGER_BIT;
        //
        //updating electromagnetic field
        //Set to PEC at the truncation boundary
        //load field_source, such as sinc function
        update_field_process( src_position, errors);
        //
        FDTD_START_CALC_SGL = FDTD_CALC_CLR_BIT;
        //Perform data collection of observation points
        sample_data(i);
        //
        printf("Complete a timestep's updating...<_>\n");    	  
    }
    printf("The whole timestep is %d .\n",number_of_time_steps);
    printf("Complete update of EMF values for the entire timestep. <_><_><_>\n");
}
//
void fdtd_solve(int grid_size, unsigned int number_of_time_steps, int src_position, unsigned int number_of_cases, int* errors){
    //number of cases performed
    printf("----------------------------------------------------------\n");
    printf("-----------Having %dst test in progress!!! >_<------------\n",number_of_cases+1);
    printf("----------------------------------------------------------\n");
    //
    // Make sure no irq pending
    //
    // Disable irq within user plugin peripherals.
    FDTD_CTRL = 0;
    // Clear pending int
    FDTD_CMD = FDTD_CMD_CLR_INT_BIT;
    //
    // Global enable User plugin interrupt
    //
    // Clear all events
    ECP = 0xFFFFFFFF;
    // Clear all interrupts
    ICP = 0xFFFFFFFF;
    int_enable();
    IER = IER | (1 << IRQ_UP_IDX); // Enable User plugin interrupt 

    //define problem space size and initialize field space
    initialize_field_space(grid_size);
    //
    //read field update equation's coefficients
    read_coefficient();
    //
    //having iteration
    run_fdtd_loop( number_of_time_steps, src_position, errors);
    //
    //software's calculation result compare with hardware's
    compare_observation_point_error(number_of_time_steps,number_of_cases, errors);
    //
    printf("----------------------------------------------------------\n");
    printf("-----------Finishing %dst test in progress!!! <_>---------\n",number_of_cases+1);
    printf("----------------------------------------------------------\n");
}
//
#define NUMBER_OF_CASES 3

int main() {
    int errors = 0;  
    int src_position;
    for (size_t i = 0; i < NUMBER_OF_CASES; ++i){
        switch (i){
            case 0:src_position =   5;break;
            case 1:src_position =  40;break;
            case 2:src_position =  95;break;
        }
        fdtd_solve(GRID_SIZE,NUMBER_OF_TIME_STEPS,src_position,i,&errors);
    }
    printf("ERRORS: %d\n", errors);

    return !(errors == 0);
}
