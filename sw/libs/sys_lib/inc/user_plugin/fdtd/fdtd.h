#ifndef _USER_PLUGIN_FDTD_H_
#define _USER_PLUGIN_FDTD_H_

#include <pulpino.h>
//one_dim_fdtd define update coefficients addr
#define FDTD_REG_CEZE_ADDR          ( USER_PLUGIN_AXI_BASE_ADDR + 0x00 )
#define FDTD_REG_CEZHY_ADDR         ( USER_PLUGIN_AXI_BASE_ADDR + 0x04 )
#define FDTD_REG_CEZJ_ADDR          ( USER_PLUGIN_AXI_BASE_ADDR + 0x08 )
#define FDTD_REG_CHYH_ADDR          ( USER_PLUGIN_AXI_BASE_ADDR + 0x0C )
#define FDTD_REG_CHYEZ_ADDR         ( USER_PLUGIN_AXI_BASE_ADDR + 0x10 )
#define FDTD_REG_CHYM_ADDR          ( USER_PLUGIN_AXI_BASE_ADDR + 0x14 )
#define FDTD_REG_COE0_ADDR          ( USER_PLUGIN_AXI_BASE_ADDR + 0x18 )
#define FDTD_REG_SOURCE_ADDR        ( USER_PLUGIN_AXI_BASE_ADDR + 0x1C )
//
#define FDTD_REG_SIZE               ( USER_PLUGIN_AXI_BASE_ADDR + 0x20 )
#define FDTD_REG_CTRL               ( USER_PLUGIN_AXI_BASE_ADDR + 0x24 )
#define FDTD_REG_CMD                ( USER_PLUGIN_AXI_BASE_ADDR + 0x28 )
#define FDTD_REG_STATUS             ( USER_PLUGIN_AXI_BASE_ADDR + 0x2C )
#define FDTD_REG_START_CALC_SGL     ( USER_PLUGIN_AXI_BASE_ADDR + 0x30 )

#define FDTD_REG_HY_ADDR            ( USER_PLUGIN_AXI_BASE_ADDR + 0x34 )
#define FDTD_REG_EZ_ADDR            ( USER_PLUGIN_AXI_BASE_ADDR + 0x38 )
#define FDTD_REG_CALC_HY_SGL	    ( USER_PLUGIN_AXI_BASE_ADDR + 0x3C )
#define FDTD_REG_CALC_EZ_SGL	    ( USER_PLUGIN_AXI_BASE_ADDR + 0x40 )
#define FDTD_REG_CALC_SRC_SGL	    ( USER_PLUGIN_AXI_BASE_ADDR + 0x44 )

#define FDTD_CEZE         	 REG( FDTD_REG_CEZE_ADDR     )
#define FDTD_CEZHY        	 REG( FDTD_REG_CEZHY_ADDR    )
#define FDTD_CEZJ         	 REG( FDTD_REG_CEZJ_ADDR     )
#define FDTD_CHYH         	 REG( FDTD_REG_CHYH_ADDR     )
#define FDTD_CHYEZ        	 REG( FDTD_REG_CHYEZ_ADDR    )
#define FDTD_CHYM         	 REG( FDTD_REG_CHYM_ADDR     )
#define FDTD_COE0         	 REG( FDTD_REG_COE0_ADDR     )
#define FDTD_SOURCE       	 REG( FDTD_REG_SOURCE_ADDR   )
#define FDTD_START_CALC_SGL      REG( FDTD_REG_START_CALC_SGL)
#define HY_ADDR		         REG( FDTD_REG_HY_ADDR       )
#define EZ_ADDR		         REG( FDTD_REG_EZ_ADDR       )
#define CALC_HY_SGL		 REG( FDTD_REG_CALC_HY_SGL   )
#define CALC_EZ_SGL		 REG( FDTD_REG_CALC_EZ_SGL   )
#define CALC_SRC_SGL		 REG( FDTD_REG_CALC_SRC_SGL  )

//
#define FDTD_SIZE                REG( FDTD_REG_SIZE          )
#define FDTD_CTRL                REG( FDTD_REG_CTRL          )
#define FDTD_CMD                 REG( FDTD_REG_CMD           )
#define FDTD_STATUS              REG( FDTD_REG_STATUS        )

// Word size = (REG_SIZE / 4) + 1
// s: the actual byte size in an array
#define REG_SIZE_GET_BYTE_SIZE(s)     (((s) & ~0x3) - 4)

#define FDTD_CTRL_INT_EN_BIT   (1 << 0)

#define FDTD_CMD_CLR_INT_BIT   (1 << 0)
#define FDTD_CMD_TRIGGER_BIT   (1 << 1)


#define FDTD_CALC_TRIGGER_BIT  (1 << 1)

#define FDTD_CALC_CLR_BIT      (1 << 0)

#define FDTD_STATUS_BUSY_BIT   (1 << 0)
#define FDTD_STATUS_INT_BIT    (1 << 1)

#endif
