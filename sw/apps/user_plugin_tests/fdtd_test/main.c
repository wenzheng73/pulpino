#include <stdio.h>
#include <math.h>
#include "int.h"
#include "event.h"
#include "user_plugin/fdtd/fdtd.h"
#include "user_plugin/fdtd/field_source.h"
#include "user_plugin/fdtd/coefficients.h"
#include "user_plugin/fdtd/mtlb_data.h"

#define IRQ_IDX 		22

//FDTD PARAMETER
#define NUMBER_OF_TIME_STEPS    20
#define GRID_SIZE	        100
#define OBSERVATION_POINT       20
#define UNUSED_SIZE             50 

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

//----------------------fdtd logic--------------------------//
//Here is the software control part of a one-dimensional FDTD 
//method for SOC hardware implementation, no absorption boundary 
//is added, and the boundary location is set to PEC medium.
//----------------------------------------------------------//
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
	printf("initialize problem space!!!\n");
	for (size_t i=0;i<=sizeof(Hy)/sizeof(Hy[0]);i=i+1){
		Hy[i] = 0;
	}
	for (size_t j=0;j<=sizeof(Ez)/sizeof(Ez[0]);j=j+1){
		Ez[j] = 0;
	}
	HY_ADDR = (int)Hy;
	EZ_ADDR = (int)Ez;
	FDTD_SIZE = word_n;
}

void read_coefficient(){
	//    
	printf("read relation coefficient!!!\n");
        //Assign values to the coefficient terms in the update process
	FDTD_CEZE    =  coes[0];	
        FDTD_CEZHY   =  coes[1];
        FDTD_CEZJ    =  coes[2];
        FDTD_CHYH    =  coes[3];
        FDTD_CHYEZ   =  coes[4];
        FDTD_CHYM    =  coes[5];
        FDTD_COE0    =  coes[6];     
}

void update_Hy_process(int src_position){
        //
	CALC_HY_SGL = FDTD_CALC_TRIGGER_BIT;
	while(1){
	        //
	        int calc_Hy_status = CALC_HY_SGL;
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
	CALC_HY_SGL = FDTD_CALC_CLR_BIT;
}

void update_Ez_process(int src_position){
	CALC_EZ_SGL = FDTD_CALC_TRIGGER_BIT;
	while(1){
		int calc_Ez_status = CALC_EZ_SGL;
		printf("calc_Ez_status:%d. <_>\n",calc_Ez_status);
		if(calc_Ez_status){
		    printf("update_status:having Ez calculation process. >_<!!!\n");
		}else {
		    break;
		}	
	}
	printf("this position's Ez field_value is: Ez[%d] = %d, Ez[%d] = %d, Ez[%d] = %d, Ez[%d] = %d, Ez[%d] = %d .\n",
			1,Ez[1],
        		src_position, Ez[src_position],
			OBSERVATION_POINT-1,Ez[OBSERVATION_POINT-1],	
			GRID_SIZE-1,Ez[GRID_SIZE-1],
			GRID_SIZE,Ez[GRID_SIZE]
			);
	CALC_EZ_SGL = FDTD_CALC_CLR_BIT;
}

void update_src_process(int src_position){
	EZ_ADDR =  (int)(Ez + src_position);
	CALC_SRC_SGL = FDTD_CALC_TRIGGER_BIT;
        while(1){
	        int calc_src_status = CALC_SRC_SGL;
	        printf("calc_src_status:%d. <_>\n",calc_src_status);
	        if(calc_src_status){
    	           printf("update_status:having src calculation process. >_<!!!\n");
	        }else {
		    break;
	        }
	}
	printf("this position's Ez field_value is: Ez[%d] = %d .\n",src_position,Ez[src_position]);
	EZ_ADDR =  (int)Ez;
	CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
}

void update_field_process(int src_position){
	CALC_HY_SGL  = FDTD_CALC_CLR_BIT;
	CALC_EZ_SGL  = FDTD_CALC_CLR_BIT;   
	CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
	update_Hy_process (src_position-1);
	update_Ez_process (src_position-1);
	update_src_process(src_position-1);
}

//Set up observation points to collect data
int observation_data[NUMBER_OF_TIME_STEPS]; 
void sample_data(int i){ 
    //
        observation_data[i] = Ez[OBSERVATION_POINT-1];
}

//Performing data error comparisons
#define FIXED_POINT_1E_NEG_3 0x00000831
void compare_observation_point_error(unsigned int number_of_time_steps, unsigned int number_of_tests, int* errors){
	 int abs_error;
	 int temp_data[NUMBER_OF_TIME_STEPS];
         printf("Perform comparison of calculated data errors!!!!\n");
	 switch (number_of_tests){
          case 0:for(size_t i;i<number_of_time_steps;i++){
			 temp_data[i] = check_data_v0[i];
	         }
		 break;
          case 1:for(size_t i;i<number_of_time_steps;i++){
			 temp_data[i] = check_data_v1[i];
	         }
		 break;
          case 2:for(size_t i;i<number_of_time_steps;i++){
			 temp_data[i] = check_data_v2[i];
	         }
		 break;
         }
         for (size_t i=0; i<number_of_time_steps; i++){
             abs_error = abs(temp_data[i]-observation_data[i]);
	     if (abs_error > FIXED_POINT_1E_NEG_3){
		 ++(*errors);
		 printf("This position's Ez field_value is: Ez[%d] = %d .\n",i,observation_data[i]);
		 printf("There is a problem with the calculation process,please debug:abs_error[%d] = %d .!!!\n",i,abs_error);
	     }else {
	         printf("Congratulations, pass[%d]!!!\n",i);
	     }
	 }
}

//Iterative update process
void run_fdtd_loop(unsigned int number_of_time_steps, int src_position){
	FDTD_START_CALC_SGL = FDTD_CALC_CLR_BIT;
	printf("Having fdtd loop!!!\n");
	for (size_t i=0;i<number_of_time_steps;i++){
		//Start the entire iterative process
		printf("---------The current timestep is %d .---------\n",i+1);

                //load field source
		//The coefficients here are related to the actual project
		//The simplest way to join the field_source (point source) is implemented here
	        load_field_source(i);

	        //trigger hardware's calculation of updating field_value
	 	FDTD_START_CALC_SGL = FDTD_CALC_TRIGGER_BIT;

		//updating electromagnetic field
		//Set to PEC at the truncation boundary
		//load field_source, such as sin function
		update_field_process( src_position );
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
void fdtd_solve(int grid_size, unsigned int number_of_time_steps, 
		int src_position, unsigned int number_of_tests, int* errors){
	//number of tests performed
	printf("----------------------------------------------------------\n");
	printf("-----------Having %dst test in progress!!! >_<------------\n",number_of_tests+1);
	printf("----------------------------------------------------------\n");
	//define problem space size and initialize field space
	initialize_field_space(grid_size);
	//read field update equation's coefficients
	read_coefficient();
	//set status
	printf("set status!!!\n");
	//set_wo_irq();
	//
	//having iteration
	run_fdtd_loop( number_of_time_steps, src_position);
	//software's calculation result compare with hardware's
	compare_observation_point_error(number_of_time_steps,number_of_tests, errors);
	printf("----------------------------------------------------------\n");
	printf("-----------Finishing %dst test in progress!!! <_>---------\n",number_of_tests+1);
	printf("----------------------------------------------------------\n");
}
//
#define NUMBER_OF_TESTS 3
int main() {
    int errors = 0;  
    int src_position;
    for (size_t i=0;i<NUMBER_OF_TESTS;i++){
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
