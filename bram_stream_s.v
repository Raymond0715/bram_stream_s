/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/06/01
* Design Name:    poly_systolic_hw
* Module Name:    bram_stream_s
* Project Name:   bram_stream_s
* Target Devices: ZCU 102
* Tool Versions:  Vivado 2021.2
* Description:
*
* Dependencies:
*
* Revision:
* Additional Comments:
* 	- s_instruct_tdata = {addr[25:13], length[12:0]}
* 	- Only one of read or write operation for one of dual port is available for
* 	  each instruction.
*
*******************************************************************************/


module bram_stream_s (
	 input										clk
	,input										rst_n

	,input	[63:0]								s_instruct_a_tdata
	,input										s_instruct_a_tvalid
	,output										s_instruct_a_tready

	,input	[127:0]								s_in_a_tdata
	,input										s_in_a_tvalid
	,output										s_in_a_tready
	,input	[15:0]								s_in_a_tkeep
	,input										s_in_a_tlast

	,output	[127:0]								m_out_a_tdata
	,output										m_out_a_tvalid
	,input										m_out_a_tready
	,output	reg	[15:0]							m_out_a_tkeep = 16'hffff
	,output										m_out_a_tlast
);


	wire	[127:0]					dina_l, dina_h;
	wire	[127:0]					douta_l, douta_h;

	wire							wea_l, wea_h;
	wire	[13:0]					addra_l, addra_h;


	stream_interface_s_wrap # (
		 .RMODE				 	( 2'b01 )
		,.WMODE				 	( 2'b00 )
	)
	stream_interface_s_a (
		 .clk					( clk )
		,.rst_n					( rst_n )

		,.s_instruct_tdata		( s_instruct_a_tdata )
		,.s_instruct_tvalid		( s_instruct_a_tvalid )
		,.s_instruct_tready		( s_instruct_a_tready )
		,.s_in_tdata			( s_in_a_tdata )
		,.s_in_tvalid			( s_in_a_tvalid )
		,.s_in_tready			( s_in_a_tready )
		,.s_in_tlast			( s_in_a_tlast )
		,.m_out_tdata			( m_out_a_tdata )
		,.m_out_tvalid			( m_out_a_tvalid )
		,.m_out_tready			( m_out_a_tready )
		,.m_out_tlast			( m_out_a_tlast )

		,.addr_l				( addra_l )
		,.din_l					( dina_l )
		,.dout_l				( douta_l )
		,.we_l					( wea_l )

		,.addr_h				( addra_h )
		,.din_h					( dina_h )
		,.dout_h				( douta_h )
		,.we_h					( wea_h )
	);


	data_bram_s data_bram_s_low (
		 .clka					( clk )
		,.addra					( addra_l )
		,.dina					( dina_l )
		,.douta					( douta_l )
		,.wea					( wea_l )
	);


	data_bram_s data_bram_s_high (
		 .clka					( clk )
		,.addra					( addra_h )
		,.dina					( dina_h )
		,.douta					( douta_h )
		,.wea					( wea_h )
	);


endmodule
