`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc_update.sv
// Author: Joseph Zuckerman
// write back to memory 

module llc_update(clk, rst, update_en, wr_en, wr_data_dirty_bit, wr_en_evict_way, is_rst_to_resume, is_flush_to_resume, is_rsp_to_get, is_req_to_get, is_dma_req_to_get, is_dma_read_to_resume, is_dma_write_to_resume, update_evict_way, states_buf, hprots_buf, lines_buf, tags_buf, sharers_buf, owners_buf, dirty_bits_buf, evict_way_buf, way, wr_data_hprot, wr_data_state, wr_data_sharers, wr_data_tag, wr_data_owner, wr_data_evict_way, wr_data_line, wr_rst_flush, incr_rst_flush_stalled_set); 

    input logic clk, rst, update_en; 
    input logic is_rst_to_resume, is_flush_to_resume, is_rsp_to_get, is_req_to_get, is_dma_req_to_get, is_dma_read_to_resume, is_dma_write_to_resume;
    input logic update_evict_way; 
    input llc_state_t states_buf[`LLC_WAYS];
    input hprot_t hprots_buf[`LLC_WAYS];
    input line_t lines_buf[`LLC_WAYS];
    input llc_tag_t tags_buf[`LLC_WAYS];
    input sharers_t sharers_buf[`LLC_WAYS];
    input owner_t owners_buf[`LLC_WAYS];
    input logic dirty_bits_buf[`LLC_WAYS];
    input llc_way_t evict_way_buf, way; 


    output hprot_t wr_data_hprot;
    output llc_state_t wr_data_state;
    output sharers_t wr_data_sharers;
    output llc_tag_t wr_data_tag;
    output owner_t wr_data_owner; 
    output llc_way_t wr_data_evict_way;
    output line_t wr_data_line;
    output logic wr_en, wr_en_evict_way, wr_data_dirty_bit;
    output logic [(`LLC_NUM_PORTS-1):0] wr_rst_flush;
    output logic incr_rst_flush_stalled_set; 

    always_comb begin 
        wr_rst_flush = {`LLC_NUM_PORTS{1'b0}};
        wr_data_state = 0;
        wr_data_dirty_bit = 1'b0; 
        wr_data_sharers = 0;
        wr_data_evict_way = 0;
        wr_data_tag = 0; 
        wr_data_line = 0;
        wr_data_hprot = 0; 
        wr_data_owner = 0; 
        wr_data_evict_way = 0; 
        wr_en = 1'b0; 
        wr_en_evict_way = 1'b0;
        incr_rst_flush_stalled_set = 1'b0;
        if (update_en) begin 
            if (is_rst_to_resume) begin 
                wr_rst_flush  = {`LLC_NUM_PORTS{1'b1}};
                wr_data_state = `INVALID;
                wr_data_dirty_bit = 1'b0; 
                wr_data_sharers = 0; 
                wr_data_evict_way = 0; 
                wr_en_evict_way = 1'b1;
                incr_rst_flush_stalled_set = 1'b1;
            end else if (is_flush_to_resume) begin 
                wr_data_state = `INVALID;
                wr_data_dirty_bit = 1'b0; 
                wr_data_sharers = 0; 
                wr_data_evict_way = 0; 
                incr_rst_flush_stalled_set = 1'b1; 
                for (int cur_way = 0; cur_way < `LLC_WAYS; cur_way++) begin 
                    if (states_buf[cur_way] == `VALID && hprots_buf[cur_way] == `DATA) begin 
                        wr_rst_flush[cur_way] = 1'b1; 
                    end
                end
            end else if (is_rsp_to_get || is_req_to_get || is_dma_req_to_get ||
                         is_dma_read_to_resume || is_dma_write_to_resume) begin 
                wr_en = 1'b1; 
                wr_data_tag = tags_buf[way]; 
                wr_data_state = states_buf[way];
                wr_data_line = lines_buf[way];  
                wr_data_hprot = hprots_buf[way]; 
                wr_data_owner = owners_buf[way]; 
                wr_data_sharers = sharers_buf[way]; 
                wr_data_dirty_bit = dirty_bits_buf[way];
                wr_data_evict_way = evict_way_buf;
                wr_en_evict_way = update_evict_way;
            end
        end
    end
endmodule
