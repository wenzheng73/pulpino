//Here the update coefficient term of the field update process is placed
//The specific coefficients are adjusted depending on the medium of the problem space
//Here we consider only the simplest case, the electromagnetic field propagation process in free space
#ifndef    _FDTD_COES_CONSTANT_
#define    _FDTD_COES_CONSTANT_
#define    COES_N    7
int coes[COES_N] = {
	   0x00200000,	
       0x2A5A53B9,
       0xFFF5285D,
       0x00200000,
       0x0000138F,
       0x00000000,
       0xFFFE4E04 
};

#endif


