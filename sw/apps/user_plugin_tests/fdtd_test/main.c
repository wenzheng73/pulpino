#include <stdio.h>
#include "int.h"
#include "event.h"
#include "user_plugin/fdtd/fdtd.h"

#define IRQ_IDX 		22

//FDTD PARAMETER
#define NUMBER_OF_TIME_STEPS 	2
#define GRID_SIZE	        500
#define SOURCE_POSITION	        250
#define BUFFER_SIZE             GRID_SIZE/10

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
int Hy[GRID_SIZE+BUFFER_SIZE];
int Ez[GRID_SIZE+BUFFER_SIZE];

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
                //load field source
	        load_field_source(i);

	        //trigger calculation
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
    /*FILE *p = fopen("coe.txt", "r");
    while(!feof(p))
    {
                  }
      fclose(p);*/

	printf("load field source data!!!\n");
	if (current_timestep == 0){
		FDTD_SOURCE  =  0x00020261;
	}
	if (current_timestep == 1){
		FDTD_SOURCE  =  0x000402BB;
	}
	
}

void update_field_process(){
	CALC_HY_SGL  = FDTD_CALC_CLR_BIT;
	CALC_EZ_SGL  = FDTD_CALC_CLR_BIT;   
	CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
	update_Hy_process();
	update_Ez_process();
	update_src_process(SOURCE_POSITION);
}

void update_Hy_process(){
	//buffer data	
	//buffer_data();
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
	printf("This position's Hy field_value is: Hy[%d] = %x .\n",SOURCE_POSITION, Hy[SOURCE_POSITION-1]);
	CALC_HY_SGL = FDTD_CALC_CLR_BIT;
}
void update_Ez_process(){
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
	printf("This position's Ez field_value is: Ez[%d] = %x .\n",SOURCE_POSITION, Ez[SOURCE_POSITION-1]);
	CALC_EZ_SGL = FDTD_CALC_CLR_BIT;
}

void update_src_process(int src_position){
	EZ_ADDR =  (int)(Ez + src_position-1);
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
	printf("Ez's value of current source_position is %x .\n",Ez[src_position-1]);
	EZ_ADDR =  (int)Ez;
	CALC_SRC_SGL = FDTD_CALC_CLR_BIT;
}
//
void compare_observation_point_error(){
         printf("Test is doing!!!!\n");
}
//
void set_wo_irq(){

    mb();

    //FDTD_SRC_ADDR = (int)src;
    //FDTD_DST_ADDR = (int)dst;
   /* FDTD_SIZE = REG_SIZE_GET_BYTE_SIZE(word_n * 4);
    do_check_ctrl_src_dst_size(
        errors, 
        0,
        (int)src, (int)dst,
        REG_SIZE_GET_BYTE_SIZE(word_n * 4));*/

    FDTD_CMD = FDTD_CMD_TRIGGER_BIT;

    // Figure out how many FDTD reg accesses can happen during data processing at most.
    int busy_loops = 0;
    while(1) {
        int status = FDTD_STATUS;
        if (status & FDTD_STATUS_BUSY_BIT) {
            ++busy_loops;
            continue;
        }
        break;
    }

    {
        // Make sure status is expected;
        int status = FDTD_STATUS;

        if (!(status & FDTD_STATUS_INT_BIT)) { 
            printf("Error: status int bit should be set, but it is unset\n");
        }

        // Clear int pending
        FDTD_CMD = FDTD_CMD_CLR_INT_BIT;
        status = FDTD_STATUS;
        if (status & FDTD_STATUS_INT_BIT) {
            printf("Error: status int bit should be unset, but it is set\n");
        }
    }
}

//------------------------------------------------------------//
// Must use volatile,
// because it is used to communicate between IRQ and main thread.
volatile int calc_int_triggers = 0;

void ISR_UP() {
    // Clear interrupt within user plugin peripheral
    FDTD_CMD = FDTD_CMD_CLR_INT_BIT;
    ICP = 1 << IRQ_IDX;

    ++calc_int_triggers;
    printf("In User Plugin interrupt\n");
}

void print_array(int* array, size_t word_n) {
    const size_t head_max_n = 3;
    const size_t tail_max_n = 3;

    size_t head_n = min(head_max_n, word_n);

    for (size_t i = 0; i < head_n; ++i) {
        printf(" %d", array[i]);
    }

    if (word_n > head_n) {
        size_t tail_start = max(head_max_n, word_n - tail_max_n);
        if (tail_start != head_max_n) {
            printf(" ...");
        }

        for (size_t i = tail_start; i < word_n; ++i) {
            printf(" %d", array[i]);
        }
    }
}

void do_check_ctrl_src_dst_size(int* errors, int expected_ctrl, int expected_src, int expected_dst, int expected_size) {
    int ctrl_v = FDTD_CTRL;
   //int src_v = FDTD_SRC;
    //int dst_v = FDTD_DST;
    int src_v = FDTD_CEZE;
    int dst_v = FDTD_CEZHY;
    int size_v = FDTD_SIZE;

    if (ctrl_v != expected_ctrl) {
        ++(*errors);
        printf("Error: ctrl: 0x%X, expected ctrl: 0x%X\n", ctrl_v, expected_ctrl);
    }
    if (src_v != expected_src) {
        ++(*errors);
        printf("Error: src: 0x%X, expected src: 0x%X\n", src_v, expected_src);
    }
    if (dst_v != expected_dst) {
        ++(*errors);
        printf("Error: dst: 0x%X, expected dst: 0x%X\n", dst_v, expected_dst);
    }
    if (size_v != expected_size) {
        ++(*errors);
        printf("Error: size: 0x%X, expected size: 0x%X\n", size_v, expected_size);
    }
}

void do_compare(int* errors, int* src, int* dst, size_t word_n) {
    for (size_t i = 0; i < word_n; ++i) {
        int src_v = src[i];
        int dst_v = dst[i];
        int expected_v = src_v * 2;
        if (expected_v != dst_v) {
            ++(*errors);
            printf("Error: src[%d]: %d, dst[%d]: %d, expected dst[%d]: %d\n",
                   i, src_v, i, dst_v, i, expected_v);
        }
    }
}

void do_check_wo_irq(int* errors, int* src, int* dst, size_t word_n, int start) {
    for (size_t i = 0; i < word_n; ++i) {
        src[i] = start + i;
    }
    mb();

    //FDTD_SRC_ADDR = (int)src;
    //FDTD_DST_ADDR = (int)dst;
    FDTD_SIZE = REG_SIZE_GET_BYTE_SIZE(word_n * 4);
    do_check_ctrl_src_dst_size(
        errors, 
        0,
        (int)src, (int)dst,
        REG_SIZE_GET_BYTE_SIZE(word_n * 4));

    FDTD_CMD = FDTD_CMD_TRIGGER_BIT;

    // Figure out how many FDTD reg accesses can happen during data processing at most.
    int busy_loops = 0;
    while(1) {
        int status = FDTD_STATUS;
        if (status & FDTD_STATUS_BUSY_BIT) {
            ++busy_loops;
            continue;
        }
        break;
    }

    {
        // Make sure status is expected;
        int status = FDTD_STATUS;

        if (!(status & FDTD_STATUS_INT_BIT)) {
            ++(*errors);
            printf("Error: status int bit should be set, but it is unset\n");
        }

        // Clear int pending
        FDTD_CMD = FDTD_CMD_CLR_INT_BIT;
        status = FDTD_STATUS;
        if (status & FDTD_STATUS_INT_BIT) {
            ++(*errors);
            printf("Error: status int bit should be unset, but it is set\n");
        }
    }

    printf("src:");
    print_array(src, word_n);
    printf("\n");

    printf("dst:");
    print_array(dst, word_n);
    printf("\n");

    printf("busy loops: %d\n", busy_loops);

    do_compare(errors, src, dst, word_n);
}

void do_check_w_irq(int* errors, int* src, int* dst, size_t word_n, int start) {
    for (size_t i = 0; i < word_n; ++i) {
        src[i] = start + i;
    }
    mb();

    calc_int_triggers = 0;
    mb();

    // Enable interrupt
    FDTD_CTRL = FDTD_CTRL_INT_EN_BIT;
    //FDTD_SRC_ADDR = (int)src;
    //FDTD_DST_ADDR = (int)dst;
    FDTD_SIZE = REG_SIZE_GET_BYTE_SIZE(word_n * 4);
    do_check_ctrl_src_dst_size(
        errors, 
        FDTD_CTRL_INT_EN_BIT,
        (int)src, (int)dst,
        REG_SIZE_GET_BYTE_SIZE(word_n * 4));

    FDTD_CMD = FDTD_CMD_TRIGGER_BIT;

    while (1) {
        if (calc_int_triggers != 0) {
            break;
        }
    }

    // Make sure status is expected
    int status = FDTD_STATUS;
    if (status & FDTD_STATUS_INT_BIT) {
        ++(*errors);
        printf("Error: status int bit should be unset, but it is set\n");
    }
    if (status & FDTD_STATUS_BUSY_BIT) {
        ++(*errors);
        printf("Error: status busy bit should be unset, but it is set\n");
    }

    printf("src:");
    print_array(src, word_n);
    printf("\n");

    printf("dst:");
    print_array(dst, word_n);
    printf("\n");

    do_compare(errors, src, dst, word_n);
}

// Byte: 8K
#define WORD_NUM (2 * 1024)

int g_src[WORD_NUM];
int g_dst[WORD_NUM];

void check_wo_irq(int* errors) {
    for (size_t i = 0; i < sizeof(g_src) / sizeof(g_src[0]) && i < 4; ++i) {
        do_check_wo_irq(errors, g_src, g_dst, (i + 1), (i + 1) * 10);
    }
    do_check_wo_irq(errors, g_src, g_dst, sizeof(g_src) / sizeof(g_src[0]), 100);
}

void check_w_irq(int* errors) {
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
    IER = IER | (1 << IRQ_IDX); // Enable User plugin interrupt

    int src[4];
    int dst[4];

    for (size_t i = 0; i < sizeof(src) / sizeof(src[0]) && i < 4; ++i) {
        do_check_w_irq(errors, src, dst, i + 1, (i + 1) * 10);
    }
    do_check_w_irq(errors, g_src, g_dst, sizeof(g_src) / sizeof(g_src[0]), 100);
} 

int main() {
    int errors = 0; 
    fdtd_solve(GRID_SIZE,NUMBER_OF_TIME_STEPS);
    //check_wo_irq(&errors);
    //check_w_irq(&errors);

    printf("ERRORS: %d\n", errors);

    return !(errors == 0);
}
