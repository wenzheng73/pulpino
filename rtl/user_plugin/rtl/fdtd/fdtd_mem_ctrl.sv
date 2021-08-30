module fdtd_mem_ctrl
#(
    parameter REG_SIZE_WIDTH   = 16,
    parameter AXI4_LENTH_WIDTH = 8,
    parameter BUFFER_SIZE      = 50
)
(
    input logic     ACLK,
    input logic     ARESETn,

    AXI_BUS.Master  mstr,

    // User signals
    input  logic [REG_SIZE_WIDTH-1:0]       size_i,
    input  logic                            ctrl_int_en_i,
    input  logic                            cmd_clr_int_pulse_i,
    input  logic                            cmd_trigger_pulse_i,
    //
    output logic                            status_busy_o,
    output logic                            status_int_pending_o,
    output logic                            int_o,
    // fdtd logic
    input  logic                            fdtd_start_signal_i,
    //
    input  logic                            calc_Hy_start_en_i,
    input  logic                            calc_Ez_start_en_i,
    input  logic                            calc_src_start_en_i,
    output logic                            calc_Hy_flg_o,
    output logic                            calc_Ez_flg_o,
    output logic                            calc_src_flg_o,
    output logic                            calc_Hy_end_flg_o,
    output logic                            calc_Ez_end_flg_o,
    output logic                            calc_src_end_flg_o,
    // read/write address
    input  logic [mstr.AXI_ADDR_WIDTH-1:0]  Hy_addr_i,
    input  logic [mstr.AXI_ADDR_WIDTH-1:0]  Ez_addr_i,
    // read/write data
    input  logic [mstr.AXI_DATA_WIDTH-1:0]  Hy_n_i, 
    input  logic [mstr.AXI_DATA_WIDTH-1:0]  Ez_n_i, 
    output logic [mstr.AXI_DATA_WIDTH-1:0]  Hy_old_o,
    output logic [mstr.AXI_DATA_WIDTH-1:0]  Ez_old_o,
    // data_mem -> ram_buffer
    output logic                            buffer_Hy_start_o,
    output logic                            buffer_Ez_start_o,
    output logic                            buffer_src_start_o,
    output logic                            buffer_Hy_end_o,
    output logic                            buffer_Ez_end_o,
    output logic                            buffer_src_end_o,
    output logic                            rdvalid_Hy_o_o,
    output logic                            rdvalid_Ez_o_o,
    // ram_buffer -> data_mem
    input  logic                            wrt_Hy_start_i,
    input  logic                            wrt_Ez_start_i,
    input  logic                            wrt_src_start_i,
    output logic                            wrtvalid_sgl_o,
    output logic                            mem_rd_Hy_en_o,
    output logic                            mem_rd_Ez_en_o,
    output logic                            mem_rd_end_o
);
	// function called clogb2 that returns an integer which has the
	//value of the ceiling of the log base 2

    // function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.                      
	/*function integer clogb2 (input integer bit_depth);              
	  begin                                                           
	    for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
	      bit_depth = bit_depth >> 1;                                 
	    end                                                           
	  endfunction*/
    /////////////////////////////////////////
    // Data Reading/Writing Processing //////
    /////////////////////////////////////////
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_r_Hy_word_addr;  // Read Hy address by word
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_r_Ez_word_addr;  // Read Ez address by word
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_r_Ez_word_addr_0;// Read Ez address by word
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_r_word_addr;     // Read address by word
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_w_Hy_word_addr;  // Write Hy address by word
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_w_Ez_word_addr;  // Write Ez address by word
    logic [mstr.AXI_ADDR_WIDTH -1: 0]      r_w_word_addr;     // Write address by word
    logic [REG_SIZE_WIDTH - 2 - 1: 0]      r_word_size;       // Remaining number of words

    logic                                  s_r_req;  // Read memory request
    logic [mstr.AXI_DATA_WIDTH - 1: 0]     s_r_data;
    logic                                  s_r_gnt;  // Read memory grant

    logic                                  s_w_req;  // Write memory request
    logic [mstr.AXI_DATA_WIDTH - 1: 0]     s_w_data;
    logic                                  s_w_data_store;
    logic [mstr.AXI_DATA_WIDTH - 1: 0]     r_w_data;
    logic                                  s_w_gnt;  // Write memory grant
    
    //
    logic                                  calc_Hy_end_flg;
    logic                                  calc_Ez_end_flg;
    logic                                  calc_src_end_flg;

    logic                                  rd_Hy_sgl;
    logic                                  rd_Ez_sgl;
    logic                                  rd_src_sgl;
    //
    logic                                  wt_Hy_sgl;
    logic                                  wt_Ez_sgl;
    logic                                  wt_src_sgl;
    logic                                  buffer_Hy_last_0;
    logic                                  buffer_Hy_last_1;
    logic                                  buffer_Ez_last_0;
    logic                                  buffer_Ez_last_1;
    logic                                  nxt_buffer_en;
    logic [AXI4_LENTH_WIDTH-1:0]           axi4_lenth;
    logic [AXI4_LENTH_WIDTH-1:0]           burst_size_byte;
    //record write field_data number
    logic [REG_SIZE_WIDTH-1:0]             record_num_cnt;      
    //
    enum logic [4:0] {  IDLE,
                        INIT_READ_HY,
                        WAIT_READ_HY,
                        INIT_READ_EZ,
                        WAIT_READ_EZ,
                        INIT_CALC_PROCESS,
                        WAIT_CALC_END,
                        INIT_WRITE_HY,
                        WAIT_WRITE_HY,
                        WAIT_0,
                        INIT_WRITE_EZ,
                        WAIT_WRITE_EZ,
                        WAIT_1,
                        INIT_READ_SRC,
                        WAIT_READ_SRC,
                        INIT_WRITE_SRC,
                        WAIT_WRITE_SRC,
                        WAIT_2
                     } r_CS, s_CS_n; 
    //add some logic
    assign axi4_lenth        = (r_CS == WAIT_WRITE_HY || r_CS == WAIT_WRITE_EZ || (calc_Hy_start_en_i && r_CS == WAIT_READ_HY ) ||
                                (calc_Ez_start_en_i && r_CS == WAIT_READ_EZ)) ? BUFFER_SIZE : (((calc_Hy_start_en_i && r_CS == WAIT_READ_EZ ) ||
                                (calc_Ez_start_en_i && r_CS == WAIT_READ_HY)) ? BUFFER_SIZE+1'b1 : 'd1);
    assign burst_size_byte   = ((calc_Hy_start_en_i && r_CS == WAIT_READ_EZ) || (calc_Ez_start_en_i && r_CS == WAIT_READ_HY))
                                         ? ((BUFFER_SIZE+1'b1) * (mstr.AXI_ADDR_WIDTH/8)) : (BUFFER_SIZE * (mstr.AXI_ADDR_WIDTH/8));
    //data_mem -> ram_buffer
    //write field_value data
    assign s_w_data          = wt_Hy_sgl ? Hy_n_i : ((wt_Ez_sgl||wt_src_sgl) ? Ez_n_i : 'd0);

    //read/write address
    assign r_r_word_addr     = rd_Hy_sgl ? r_r_Hy_word_addr : ((rd_Ez_sgl||rd_src_sgl) 
	                                     ? (calc_Ez_start_en_i ? r_r_Ez_word_addr_0 : r_r_Ez_word_addr): 'd0);

    assign r_w_word_addr     = wt_Hy_sgl ? r_w_Hy_word_addr : ((wt_Ez_sgl||wt_src_sgl) 
	                                     ? r_w_Ez_word_addr : 'd0);

    //signal of writing field_value data to data_mem 
    assign wrtvalid_sgl_o    = ((r_CS == WAIT_WRITE_HY || r_CS == WAIT_WRITE_EZ) && (record_num_cnt <= BUFFER_SIZE-1'b1)) 
                                         ? 1'b1 : (r_CS == WAIT_WRITE_SRC ? 1'b1 : 1'b0);

    //data_mem -> ram_buffer
    //read data valid signal 
    assign rdvalid_Hy_o_o    = (rd_Hy_sgl && mstr.r_valid && mstr.r_ready);  
    assign rdvalid_Ez_o_o    = ((rd_Ez_sgl||rd_src_sgl) && mstr.r_valid && mstr.r_ready); 

    //read field_value data
    assign Hy_old_o          = rd_Hy_sgl ? s_r_data : 'd0;
    assign Ez_old_o          = (rd_Ez_sgl||rd_src_sgl) ? s_r_data : 'd0;
    //
    assign buffer_Hy_last_0  = calc_Hy_start_en_i ? ((record_num_cnt == BUFFER_SIZE-1'b1) && rd_Hy_sgl) : 1'b0;
    assign buffer_Hy_last_1  = calc_Ez_start_en_i ? ((record_num_cnt == BUFFER_SIZE) && rd_Hy_sgl) : 1'b0;

    assign buffer_Ez_last_0  = calc_Hy_start_en_i ? ((record_num_cnt == BUFFER_SIZE) && rd_Ez_sgl) : 1'b0; 
    assign buffer_Ez_last_1  = calc_Ez_start_en_i ? ((record_num_cnt == BUFFER_SIZE-1'b1) && rd_Ez_sgl) : 1'b0;

    assign nxt_buffer_en     = ((record_num_cnt == BUFFER_SIZE) && (r_CS == WAIT_WRITE_HY || r_CS == WAIT_WRITE_EZ))
	                           ? 1'b1:1'b0;   
    assign calc_Hy_end_flg_o = calc_Hy_end_flg;
    assign calc_Ez_end_flg_o = calc_Ez_end_flg;
    assign calc_src_end_flg_o= calc_src_end_flg;
    //
    always_ff @(posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_w_data <= 'b0;
        else 
            r_w_data <= s_w_data;
    end

    always_ff @ (posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_CS <= IDLE;
        else
            r_CS <= s_CS_n;
    end

    always_comb
    begin
        calc_Hy_flg_o  = 1'b0;
        calc_Ez_flg_o  = 1'b0;
        calc_src_flg_o = 1'b0;
        
        buffer_Hy_start_o = 1'b0;
        buffer_Ez_start_o = 1'b0;
        buffer_src_start_o= 1'b0;
        buffer_Hy_end_o   = 1'b0;
        buffer_Ez_end_o   = 1'b0;
        buffer_src_end_o  = 1'b0;
	
        s_w_data_store = 1'b0;
        status_busy_o  = 1'b1;

        mem_rd_Hy_en_o = 1'b0;
        mem_rd_Ez_en_o = 1'b0;
        mem_rd_end_o   = 1'b0;
        
        rd_Hy_sgl      = 1'b0;
        rd_Ez_sgl      = 1'b0;
        rd_src_sgl     = 1'b0;
        wt_Hy_sgl      = 1'b0;
        wt_Ez_sgl      = 1'b0;
        wt_src_sgl     = 1'b0;

        case (r_CS)
            IDLE:
            begin
                //status_busy_o = 1'b0;
                if (~fdtd_start_signal_i)begin
                    s_CS_n = IDLE;
                end
                else
                begin
                    if (calc_Hy_start_en_i || calc_Ez_start_en_i)begin
                        s_CS_n            = INIT_READ_HY;
                        buffer_Hy_start_o = 1'b1;
                    end
                    else 
                        s_CS_n = IDLE;
                end
            end

            INIT_READ_HY:
            begin
                s_CS_n       = WAIT_READ_HY;
                rd_Hy_sgl    = 1'b1;
                mem_rd_end_o = 1'b0;
            end

            WAIT_READ_HY:
            begin 
                buffer_Hy_start_o = 1'b0;
                rd_Hy_sgl         = 1'b1;
                if (buffer_Hy_last_0||buffer_Hy_last_1)begin
                    buffer_Hy_end_o   = 1'b1;
                    s_CS_n            = INIT_READ_EZ;
                    buffer_Ez_start_o = 1'b1;
                end
            end

            INIT_READ_EZ:
            begin
                s_CS_n    = WAIT_READ_EZ;
                rd_Ez_sgl = 1'b1;
			end

            WAIT_READ_EZ:
            begin
                buffer_Hy_end_o   = 1'b0;
                buffer_Ez_start_o = 1'b0;
                rd_Ez_sgl         = 1'b1;
                if (buffer_Ez_last_0||buffer_Ez_last_1)begin
                    buffer_Ez_end_o = 1'b1;
                    s_CS_n        = INIT_CALC_PROCESS;
                end
            end

            INIT_CALC_PROCESS:
            begin
                if(calc_Hy_start_en_i)begin
                    calc_Hy_flg_o = 1'b1;
                    s_CS_n        = WAIT_CALC_END;
                end
                else if (calc_Ez_start_en_i)begin
                    calc_Ez_flg_o = 1'b1;
                    s_CS_n        = WAIT_CALC_END;
                    end
                else if (calc_src_start_en_i)begin
                    calc_src_flg_o = 1'b1;
                    s_CS_n         = WAIT_CALC_END;
                end
                else begin
                    calc_Hy_flg_o = 1'b0;
                    calc_Ez_flg_o = 1'b0;
                    calc_src_flg_o = 1'b0;
                    s_CS_n        = INIT_CALC_PROCESS;
                end
            end

            WAIT_CALC_END:
            begin
                buffer_Ez_end_o= 1'b0;
                buffer_src_end_o= 1'b0;
                rd_Ez_sgl      = 1'b0;
                rd_Hy_sgl      = 1'b0;
                rd_src_sgl     = 1'b0;
                if (wrt_Hy_start_i)begin
                    s_w_data_store = 1'b1;
                    s_CS_n         = INIT_WRITE_HY;
                end
                else if (wrt_Ez_start_i)begin
                    s_w_data_store = 1'b1;
                    s_CS_n         = INIT_WRITE_EZ;
                end
                else if (wrt_src_start_i)begin
                    s_CS_n         = INIT_WRITE_SRC; 
                end
                else begin
                    s_w_data_store = 1'b0;
                    s_CS_n         = WAIT_CALC_END;
                end
            end
	    
            INIT_WRITE_HY:
            begin
                mem_rd_Hy_en_o = 1'b1;
                s_CS_n         = WAIT_WRITE_HY;
                wt_Hy_sgl      = 1'b1;
            end

            WAIT_WRITE_HY:
            begin
                wt_Hy_sgl = 1'b1;
                //if (r_word_size == 'd0&&s_w_gnt)begin
                /*if (r_word_size == 'd0&&s_w_gnt)begin
                    mem_rd_end_o = 1'b1;
                    s_CS_n       = WAIT_0;
                end
                else if (nxt_buffer_en)
                begin
                    wt_Hy_sgl      = 1'b0;
                    buffer_Hy_start_o = 1'b1;
                    mem_rd_Hy_en_o = 1'b0;
                    mem_rd_end_o   = 1'b1;
                    s_CS_n         = INIT_READ_HY;
                end
                else 
                    s_CS_n = WAIT_WRITE_HY;*/
                if (~s_w_gnt)begin
                    s_CS_n = WAIT_WRITE_HY; 
                end
                else begin
					if (r_word_size == 'd0)begin
                        mem_rd_end_o = 1'b1;
                        s_CS_n       = WAIT_0;
                    end
                    else if (nxt_buffer_en)
                        begin
                            wt_Hy_sgl      = 1'b0;
                            buffer_Hy_start_o = 1'b1;
                            mem_rd_Hy_en_o = 1'b0;
                            mem_rd_end_o   = 1'b1;
                            s_CS_n         = INIT_READ_HY;
                        end
                    else 
                        s_CS_n = WAIT_WRITE_HY;
                end
            end

            WAIT_0:
            begin
                if (calc_Ez_start_en_i)
                    s_CS_n = IDLE;
                else 
                    s_CS_n = WAIT_0;
            end

            INIT_WRITE_EZ:
            begin
                mem_rd_Ez_en_o = 1'b1;
                s_CS_n         = WAIT_WRITE_EZ;
                wt_Ez_sgl      = 1'b1;
            end

            WAIT_WRITE_EZ:
            begin
                wt_Ez_sgl = 1'b1;
                /*if (r_word_size == 'd0&&s_w_gnt)begin
                    mem_rd_end_o = 1'b1;
                    s_CS_n       = WAIT_1;
                end
                else if (nxt_buffer_en)
                begin
                    wt_Ez_sgl      = 1'b0;
                    buffer_Hy_start_o = 1'b1;
                    mem_rd_Ez_en_o = 1'b0;
                    mem_rd_end_o   = 1'b1;
                    s_CS_n         = INIT_READ_HY;
                end
                else 
                    s_CS_n = WAIT_WRITE_EZ;*/
                if (~s_w_gnt)begin
                    s_CS_n = WAIT_WRITE_EZ; 
                end
                else begin
					if (r_word_size == 'd0)begin
                        mem_rd_end_o = 1'b1;
                        s_CS_n       = WAIT_1;
                    end
                    else if (nxt_buffer_en)
                        begin
                            wt_Ez_sgl      = 1'b0;
                            buffer_Hy_start_o = 1'b1;
                            mem_rd_Ez_en_o = 1'b0;
                            mem_rd_end_o   = 1'b1;
                            s_CS_n         = INIT_READ_HY;
                        end
                    else 
                        s_CS_n = WAIT_WRITE_EZ;
                end
            end

            WAIT_1:
            begin
                if (calc_src_start_en_i)
                    s_CS_n = INIT_READ_SRC;
                else 
                    s_CS_n = WAIT_1;
            end
    
            INIT_READ_SRC:
            begin
                buffer_src_start_o= 1'b1;
                s_CS_n		      = WAIT_READ_SRC;
                rd_src_sgl        = 1'b1;    
            end
    
            WAIT_READ_SRC:
            begin
                rd_src_sgl = 1'b1;
                if (~s_r_gnt)begin
                    s_CS_n = WAIT_READ_SRC;
                end
                else if (s_r_gnt)
                begin
                    buffer_src_start_o= 1'b0;
                    buffer_src_end_o  = 1'b1;
                    s_CS_n            = INIT_CALC_PROCESS;
                end
            end
    
            INIT_WRITE_SRC:
            begin
                mem_rd_Ez_en_o = 1'b1;
                s_CS_n         = WAIT_WRITE_SRC;
                wt_src_sgl     = 1'b1;
            end
    
            WAIT_WRITE_SRC:
            begin
                wt_src_sgl = 1'b1;
                if (~s_w_gnt)begin
                    mem_rd_end_o   = 1'b1;
                    s_w_data_store = 1'b1;
                    s_CS_n = WAIT_WRITE_SRC;
                end
                else if(s_w_gnt)
                begin
                    wt_src_sgl     = 1'b0;
                    mem_rd_Ez_en_o = 1'b0;
                    mem_rd_end_o   = 1'b1;
                    s_CS_n         = WAIT_2;
                    status_busy_o  = 1'b0;
                end
            end
                
            WAIT_2:
            begin
				if (calc_Hy_start_en_i)begin
                    s_CS_n = IDLE;
                end
                else 
                    s_CS_n = WAIT_2;
            end
    
            default:
                begin
                    s_CS_n = IDLE;
                end
        endcase
    end
    //
    always_ff @(posedge ACLK,negedge ARESETn)begin
        if (!ARESETn)begin
            s_r_req <= 1'b0;
            s_w_req <= 1'b0;
        end
        else case(r_CS)
            INIT_READ_HY : 
            begin
                s_r_req <= 1'b1; s_w_req <= 1'b0;
            end
            INIT_READ_EZ : 
            begin
                s_r_req <= 1'b1; s_w_req <= 1'b0;
            end
            INIT_WRITE_HY : 
            begin
                s_r_req <= 1'b0; s_w_req <= 1'b1;
            end
            INIT_WRITE_EZ : 
            begin
                s_r_req <= 1'b0; s_w_req <= 1'b1;
            end
            INIT_READ_SRC :
            begin
                s_r_req <= 1'b1; s_w_req <= 1'b0;
            end
            INIT_WRITE_SRC : 
            begin
                s_r_req <= 1'b0; s_w_req <= 1'b1;
            end
            default : 
            begin
                s_r_req <= 1'b0; s_w_req <= 1'b0;
            end
        endcase
    end

    //
    always_ff @(posedge ACLK,negedge ARESETn)begin
        if (!ARESETn)
            calc_Hy_end_flg <= 1'b0;
        else if (r_word_size == 'd0 && r_CS == WAIT_WRITE_HY)
            calc_Hy_end_flg <= 1'b1;
        else if (calc_Hy_end_flg == 1'b1 && calc_Ez_start_en_i )
            calc_Hy_end_flg <= 1'b0;
        else   
            calc_Hy_end_flg <= calc_Hy_end_flg;
    end
    //
    always_ff @(posedge ACLK,negedge ARESETn)begin
        if (!ARESETn)
            calc_Ez_end_flg <= 1'b0;
        else if (r_word_size == 'd0 && r_CS == WAIT_WRITE_EZ)
            calc_Ez_end_flg <= 1'b1;
        else if (calc_Ez_end_flg == 1'b1 && calc_src_start_en_i )
            calc_Ez_end_flg <= 1'b0;
        else   
            calc_Ez_end_flg <= calc_Ez_end_flg;
    end
    //
    always_ff @(posedge ACLK,negedge ARESETn)begin
        if (!ARESETn)
            calc_src_end_flg <= 1'b0;
        else if (s_CS_n == WAIT_2)
            calc_src_end_flg <= 1'b1;
        else if (calc_src_end_flg == 1'b1 && calc_Hy_start_en_i )
            calc_src_end_flg <= 1'b0;
        else   
            calc_src_end_flg <= calc_src_end_flg;
    end
    
    //////////////////////////////////////
    //record number of read/writing data//
    //////////////////////////////////////
    always_ff @(posedge ACLK, negedge ARESETn)
        begin
            if (!ARESETn)
                record_num_cnt <= 'd0;
            else if (r_CS == WAIT_READ_HY)begin	
                record_num_cnt <= (mstr.r_valid & mstr.r_ready) ? (record_num_cnt + 1'b1) : record_num_cnt;
            end
            else if (r_CS == WAIT_READ_EZ)begin
                record_num_cnt <= (mstr.r_valid & mstr.r_ready) ? (record_num_cnt + 1'b1) : record_num_cnt;
            end	
            else if (r_CS == WAIT_WRITE_HY)begin
                record_num_cnt <= (mstr.w_valid & mstr.w_ready) ? (record_num_cnt + 1'b1) : record_num_cnt;
            end			
            else if (r_CS == WAIT_WRITE_EZ)begin
                record_num_cnt <= (mstr.w_valid & mstr.w_ready) ? (record_num_cnt + 1'b1) : record_num_cnt;
            end
            else 
                record_num_cnt <= 'd0;
        end                                       
    ////////////////////////////////
    //mem read/write address////////
    ////////////////////////////////
    always_ff @(posedge ACLK, negedge ARESETn)
        begin
            if (!ARESETn)begin
                r_r_Hy_word_addr <= 'b0;
                r_r_Ez_word_addr <= 'b0;
                r_r_Ez_word_addr_0 <= 'b0;
                r_w_Hy_word_addr <= 'b0;
                r_w_Ez_word_addr <= 'b0;
                r_word_size      <= 'b0;
            end
            else case(r_CS)
            IDLE:
            begin
                r_r_Hy_word_addr <= Hy_addr_i[mstr.AXI_ADDR_WIDTH-1:0];
                r_r_Ez_word_addr <= Ez_addr_i[mstr.AXI_ADDR_WIDTH-1:0];
                r_r_Ez_word_addr_0 <= Ez_addr_i[mstr.AXI_ADDR_WIDTH-1:0] + 'd4;
                r_w_Hy_word_addr <= Hy_addr_i[mstr.AXI_ADDR_WIDTH-1:0];
                r_w_Ez_word_addr <= Ez_addr_i[mstr.AXI_ADDR_WIDTH-1:0] + 'd4;
                r_word_size      <= size_i;
            end
            
            WAIT_READ_HY:
            begin   
                if (buffer_Hy_last_1)
                    r_r_Hy_word_addr <= r_r_Hy_word_addr - 'd4;
                else 
                    r_r_Hy_word_addr <= (mstr.ar_valid && mstr.ar_ready)
                                        ? (r_r_Hy_word_addr + burst_size_byte) : r_r_Hy_word_addr; 
            end
            
            WAIT_READ_EZ:
            begin
                if (calc_Ez_start_en_i)begin 
                    r_r_Ez_word_addr_0 <= (mstr.ar_valid && mstr.ar_ready) 
                                        ? (r_r_Ez_word_addr_0 + 'd4 ) : r_r_Ez_word_addr_0;
                end	
                if(buffer_Ez_last_0)
                    r_r_Ez_word_addr <= r_r_Ez_word_addr - 'd4;
                else 
                    r_r_Ez_word_addr <= (mstr.ar_valid && mstr.ar_ready)
                                        ? (r_r_Ez_word_addr + burst_size_byte) : r_r_Ez_word_addr;
            end
            
            WAIT_WRITE_HY:
            begin
                r_w_Hy_word_addr <= (mstr.aw_valid && mstr.aw_ready)
                                        ? (r_w_Hy_word_addr + burst_size_byte) : r_w_Hy_word_addr; 
                r_word_size      <= (mstr.aw_valid && mstr.aw_ready)
                                        ? (r_word_size - axi4_lenth) : r_word_size;
            end
            
            WAIT_WRITE_EZ:
            begin
                r_w_Ez_word_addr <= (mstr.aw_valid && mstr.aw_ready)
                                        ? (r_w_Ez_word_addr + burst_size_byte) : r_w_Ez_word_addr; 
                r_word_size      <= (mstr.aw_valid && mstr.aw_ready)
                                        ? (r_word_size - axi4_lenth) : r_word_size;
            end
            
            INIT_READ_SRC:
            begin
                r_r_Ez_word_addr <= Ez_addr_i[mstr.AXI_ADDR_WIDTH-1:0];
            end
            
            INIT_WRITE_SRC:
            begin
                r_w_Ez_word_addr <= Ez_addr_i[mstr.AXI_ADDR_WIDTH-1:0];
            end
            
            default:
            begin
                r_r_Hy_word_addr <= r_r_Hy_word_addr;
                r_r_Ez_word_addr <= r_r_Ez_word_addr;
                r_r_Ez_word_addr_0 <= r_r_Ez_word_addr_0;
                r_w_Hy_word_addr <= r_w_Hy_word_addr;
                r_w_Ez_word_addr <= r_w_Ez_word_addr;
                r_word_size 	 <= r_word_size; 
            end
            endcase
    end
    ///////////////////////
    fdtd_mem_rd
    #(
        .AXI4_ADDR_WIDTH ( mstr.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( mstr.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( mstr.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( mstr.AXI_USER_WIDTH )
    )
    mem_rd_i
    (
        .ACLK       ( ACLK           ),
        .ARESETn    ( ARESETn        ),

        .ARID_o     ( mstr.ar_id     ),
        .ARADDR_o   ( mstr.ar_addr   ),
        .ARLEN_o    ( mstr.ar_len    ),
        .ARSIZE_o   ( mstr.ar_size   ),
        .ARBURST_o  ( mstr.ar_burst  ),
        .ARLOCK_o   ( mstr.ar_lock   ),
        .ARCACHE_o  ( mstr.ar_cache  ),
        .ARPROT_o   ( mstr.ar_prot   ),
        .ARREGION_o ( mstr.ar_region ),
        .ARUSER_o   ( mstr.ar_user   ),
        .ARQOS_o    ( mstr.ar_qos    ),
        .ARVALID_o  ( mstr.ar_valid  ),
        .ARREADY_i  ( mstr.ar_ready  ),

        .RID_i      ( mstr.r_id      ),
        .RDATA_i    ( mstr.r_data    ),
        .RRESP_i    ( mstr.r_resp    ),
        .RLAST_i    ( mstr.r_last    ),
        .RUSER_i    ( mstr.r_user    ),
        .RVALID_i   ( mstr.r_valid   ),
        .RREADY_o   ( mstr.r_ready   ),
        
		.axi_lenth_i    ( axi4_lenth    ),
        .rd_req_i       ( s_r_req       ),
        .rd_word_addr_i ( r_r_word_addr ),
        .rd_data_o      ( s_r_data      ),
        .rd_gnt_o       ( s_r_gnt       )
    );

    fdtd_mem_wt
    #(
        .AXI4_ADDR_WIDTH ( mstr.AXI_ADDR_WIDTH ),
        .AXI4_DATA_WIDTH ( mstr.AXI_DATA_WIDTH ),
        .AXI4_ID_WIDTH   ( mstr.AXI_ID_WIDTH   ),
        .AXI4_USER_WIDTH ( mstr.AXI_USER_WIDTH )
    )
    mem_wt_i
    (
        .ACLK       ( ACLK           ),
        .ARESETn    ( ARESETn        ),

        .AWID_o     ( mstr.aw_id     ),
        .AWADDR_o   ( mstr.aw_addr   ),
        .AWLEN_o    ( mstr.aw_len    ),
        .AWSIZE_o   ( mstr.aw_size   ),
        .AWBURST_o  ( mstr.aw_burst  ),
        .AWLOCK_o   ( mstr.aw_lock   ),
        .AWCACHE_o  ( mstr.aw_cache  ),
        .AWPROT_o   ( mstr.aw_prot   ),
        .AWREGION_o ( mstr.aw_region ),
        .AWUSER_o   ( mstr.aw_user   ),
        .AWQOS_o    ( mstr.aw_qos    ),
        .AWVALID_o  ( mstr.aw_valid  ),
        .AWREADY_i  ( mstr.aw_ready  ),

        .WDATA_o    ( mstr.w_data    ),
        .WSTRB_o    ( mstr.w_strb    ),
        .WLAST_o    ( mstr.w_last    ),
        .WUSER_o    ( mstr.w_user    ),
        .WVALID_o   ( mstr.w_valid   ),
        .WREADY_i   ( mstr.w_ready   ),

        .BID_i      ( mstr.b_id      ),
        .BRESP_i    ( mstr.b_resp    ),
        .BVALID_i   ( mstr.b_valid   ),
        .BUSER_i    ( mstr.b_user    ),
        .BREADY_o   ( mstr.b_ready   ),
        
		.axi_lenth_i    ( axi4_lenth    ),
        .wt_req_i       ( s_w_req       ),
        .wt_word_addr_i ( r_w_word_addr ),
        .wt_data_i      ( r_w_data      ),
        .wt_gnt_o       ( s_w_gnt       )
    );

    ///////////////
    // Interrupt //
    ///////////////
    logic r_last_status_busy;

    always_ff @(posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            r_last_status_busy <= 1'b0;
        else
            r_last_status_busy <= status_busy_o;
    end


    always_ff @(posedge ACLK, negedge ARESETn)
    begin
        if (~ARESETn)
            status_int_pending_o <= 1'b0;
        else if (cmd_clr_int_pulse_i)
            status_int_pending_o <= 1'b0;
        else if (~status_int_pending_o)
            status_int_pending_o <= r_last_status_busy & ~status_busy_o;
    end

    assign int_o = ctrl_int_en_i & status_int_pending_o;

endmodule
