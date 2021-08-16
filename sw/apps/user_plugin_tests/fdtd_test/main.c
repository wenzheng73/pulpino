#include <stdio.h>
#include "int.h"
#include "event.h"
#include "user_plugin/fdtd/fdtd.h"

#define IRQ_IDX 		22

//FDTD PARAMETER
#define NUMBER_OF_TIME_STEPS 	60
#define GRID_SIZE	        100
#define SOURCE_POSITION	        50
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

//----------------------user logic--------------------------//
void fdtd_solve(int grid_size, int number_of_time_steps ){
	//define problem space size and initialize field space
	initialize_field_space(grid_size);
	//read field update equation's coefficients
	read_coefficient();
	//set status
	printf("set status!!!\n");
	//set_wo_irq();
	//source position
	//.......
	//
	//having iteration
	run_fdtd_loop( number_of_time_steps );
	//software's calculation result compare with hardware's
	compare_observation_point_error();
}

//define problem space size
//fixme: redefine 
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
	    
	printf("read relation coefficient!!!\n");
    //
	FDTD_CEZE    =  0x00200000;	
        FDTD_CEZHY   =  0x2A5A53B9;
        FDTD_CEZJ    =  0xFFF5285D;
        FDTD_CHYH    =  0x00200000;
        FDTD_CHYEZ   =  0x0000138F;
        FDTD_CHYM    =  0x00000000;
        FDTD_COE0    =  0xFFFE4E04;     
}

void run_fdtd_loop(int number_of_time_steps){
	int i,j;
	FDTD_START_CALC_SIGNAL = FDTD_CALC_CLR_BIT;
	printf("Having fdtd loop!!!\n");
	for (i=0;i<number_of_time_steps;i++){
		//
		printf("---------The current timestep is %d .---------\n",i+1);

                //load field source
		//The coefficients here are related to the actual project
		//The simplest way to join the field_source (point source) is implemented here
	        load_field_source(i);

	        //trigger calculation of updating field_value
	 	FDTD_START_CALC_SIGNAL = FDTD_CALC_TRIGGER_BIT;

		//updating electromagnetic field
		//load field_source, such as sin function
		update_field_process();
		//
		FDTD_START_CALC_SIGNAL = FDTD_CALC_CLR_BIT;
		printf("Complete a timestep's updating...<_>\n");
                
	}
	printf("The whole timestep is %d .\n",number_of_time_steps);
	printf("Finishing entire electromagnetic value update. <_><_><_>\n");
}

void load_field_source(int current_timestep){
	//
	printf("load field source data!!!\n");
	//
	switch (current_timestep){
		case 0: 
			FDTD_SOURCE  =  0x00020261;
			break;
                case 1:
			FDTD_SOURCE  =  0x000402BB;
			break;
                case 2: 
			FDTD_SOURCE  =  0x0005FF07;
			break;
                case 3: 
			FDTD_SOURCE  =  0x0007F544;
			break;
                case 4: 
			FDTD_SOURCE  =  0x0009E378;
			break;
                case 5: 
			FDTD_SOURCE  =  0x000BC7AD;
			break;
                case 6: 
			FDTD_SOURCE  =  0x000D9FFC;
			break;
                case 7: 
			FDTD_SOURCE  =  0x000F6A87;
			break;
                case 8: 
			FDTD_SOURCE  =  0x0011257E;
			break;
                case 9: 
			FDTD_SOURCE  =  0x0012CF23;
			break;
                case 10: 
			FDTD_SOURCE  =  0x001465C7;
			break;
                case 11: 
			FDTD_SOURCE  =  0x0015E7CF;
			break;
                case 12: 
			FDTD_SOURCE  =  0x001753B6;
			break;
                case 13: 
			FDTD_SOURCE  =  0x0018A80B;
			break;
                case 14: 
			FDTD_SOURCE  =  0x0019E378;
			break;
                case 15: 
			FDTD_SOURCE  =  0x001B04BC;
			break;
                case 16: 
			FDTD_SOURCE  =  0x001C0AB4;
			break;
                case 17: 
			FDTD_SOURCE  =  0x001CF458;
			break;
                case 18: 
			FDTD_SOURCE  =  0x001DC0BB;
			break;
                case 19: 
			FDTD_SOURCE  =  0x001E6F0E;
			break;
                case 20: 
			FDTD_SOURCE  =  0x001EFEA2;
			break;
                case 21: 
			FDTD_SOURCE  =  0x001F6EE6;
			break;
                case 22: 
			FDTD_SOURCE  =  0x001FBF67;
			break;
                case 23: 
			FDTD_SOURCE  =  0x001FEFD6;
			break;
                case 24: 
			FDTD_SOURCE  =  0x00200000;
			break;
                case 25: 
			FDTD_SOURCE  =  0x001FEFD6;
			break;
                case 26: 
			FDTD_SOURCE  =  0x001FBF67;
			break;
                case 27: 
			FDTD_SOURCE  =  0x001F6EE6;
			break;
                case 28: 
			FDTD_SOURCE  =  0x001EFEA2;
			break;
                case 29: 
			FDTD_SOURCE  =  0x001E6F0E;
			break;
                case 30: 
			FDTD_SOURCE  =  0x001DC0BB;
			break;
                case 31: 
			FDTD_SOURCE  =  0x001CF458;
			break;
                case 32: 
			FDTD_SOURCE  =  0x001C0AB4;
			break;
                case 33: 
			FDTD_SOURCE  =  0x001B04BC;
			break;
                case 34: 
			FDTD_SOURCE  =  0x0019E378;
			break;
                case 35: 
			FDTD_SOURCE  =  0x0018A80B;
			break;
                case 36: 
			FDTD_SOURCE  =  0x001753B6;
			break;
                case 37: 
			FDTD_SOURCE  =  0x0015E7CF;
			break;
                case 38: 
			FDTD_SOURCE  =  0x001465C7;
			break;
                case 39: 
			FDTD_SOURCE  =  0x0012CF23;
			break;
                case 40: 
			FDTD_SOURCE  =  0x0011257E;
			break;
                case 41: 
			FDTD_SOURCE  =  0x000F6A87;
			break;
                case 42: 
			FDTD_SOURCE  =  0x000D9FFC;
			break;
                case 43: 
			FDTD_SOURCE  =  0x000BC7AD;
			break;
                case 44: 
			FDTD_SOURCE  =  0x0009E378;
			break;
                case 45: 
			FDTD_SOURCE  =  0x0007F544;
			break;
                case 46: 
			FDTD_SOURCE  =  0x0005FF07;
			break;
                case 47: 
			FDTD_SOURCE  =  0x000402BB;
			break;
	        case 48: 
			FDTD_SOURCE  =  0x00020261;
			break;
                case 49: 
			FDTD_SOURCE  =  0x00000000;
			break;
                case 50: 
			FDTD_SOURCE  =  0xFFFDFD9F;
			break;
                case 51: 
			FDTD_SOURCE  =  0xFFFBFD45;
			break;
                case 52: 
			FDTD_SOURCE  =  0xFFFA00F9;
			break;
                case 53: 
			FDTD_SOURCE  =  0xFFF80ABC;
			break;
                case 54: 
			FDTD_SOURCE  =  0xFFF61C88;
			break;
                case 55: 
			FDTD_SOURCE  =  0xFFF43853;
			break;
                case 56: 
			FDTD_SOURCE  =  0xFFF26004;
			break;
                case 57: 
			FDTD_SOURCE  =  0xFFF09579;
			break;
	        case 58: 
			FDTD_SOURCE  =  0xFFEEDA82;
			break;
                case 59: 
			FDTD_SOURCE  =  0xFFED30DD;
			break;
	}	
}

void update_field_process(){
	CALC_HY_SGL  = FDTD_CALC_CLR_BIT;
	CALC_EZ_SGL  = FDTD_CALC_CLR_BIT;   
	CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
	update_Hy_process(SOURCE_POSITION-1);
	update_Ez_process(SOURCE_POSITION-1);
	update_src_process(SOURCE_POSITION-1);
}

void update_Hy_process(int src_position){
        //
	CALC_HY_SGL = FDTD_CALC_TRIGGER_BIT;
	while(1){
	        //int calc_Hy_status = FDTD_CALC_STATUS;
	        int calc_Hy_status = CALC_HY_SGL;
		printf("calc_Hy_status:%d. <_>\n",calc_Hy_status);
		if(calc_Hy_status){
		printf("update_status:having Hy calculation process. >_<!!!\n");
		}else {
			break;
		}
	}
	printf("this position's Hy field_value is: Hy[%d] = %d , Hy[%d] = %d, Hy[%d] = %d, Hy[%d] = %d .\n",
		        0,Hy[0],src_position-1, Hy[src_position-1],src_position, Hy[src_position],GRID_SIZE-1,Hy[GRID_SIZE-1]);
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
	printf("this position's Ez field_value is: Ez[%d] = %d , Ez[%d] = %d , Ez[%d] = %d .\n",
			0,Ez[0],src_position, Ez[src_position],GRID_SIZE-1,Ez[GRID_SIZE-1]);
	CALC_EZ_SGL = FDTD_CALC_CLR_BIT;
}

void update_src_process(int src_position){
	EZ_ADDR =  (int)(Ez + src_position);
	printf("current Ez address :%x .<_>\n", EZ_ADDR);
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
//
void compare_observation_point_error(){
         printf("Test is doing!!!!\n");
}

int main() {
    int errors = 0; 
    fdtd_solve(GRID_SIZE,NUMBER_OF_TIME_STEPS);
    //check_wo_irq(&errors);
    //check_w_irq(&errors);

    printf("ERRORS: %d\n", errors);

    return !(errors == 0);
}
