/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/08/23
* Design Name:    poly_systolic_hw
* Module Name:    stream_interface_wrap
* Project Name:   bram_stream
* Target Devices: ZCU 102
* Tool Versions:  Vivado 2021.2
* Description:
*
* Dependencies:
*
* Revision:
* Additional Comments:
*
*******************************************************************************/


module stream_interface_wrap # (
	parameter RMODE = 2'b01,
	parameter WMODE = 2'b00
)(
	 input										clk
	,input										rst_n

	,input	[63:0]								s_instruct_tdata
	,input										s_instruct_tvalid
	,output										s_instruct_tready

	,input	[1535:0]							s_in_tdata
	,input										s_in_tvalid
	,output										s_in_tready
	,input	[15:0]								s_in_tkeep
	,input	[23:0]								s_in_tlast

	,output	[1535:0]							m_out_tdata
	,output										m_out_tvalid
	,input										m_out_tready
	,output	[15:0]								m_out_tkeep
	,output	[23:0]								m_out_tlast

	,output										weight_switch

	,output	[9:0]								addr_l
	,output	[1535:0]							din_l
	,input	[1535:0]							dout_l
	,output	[191:0]								we_l

	,output	[9:0]								addr_h
	,output	[1535:0]							din_h
	,input	[1535:0]							dout_h
	,output	[191:0]								we_h
);


	wire	[1535:0]		out_tdata, in_tdata;
	wire	[5:0]			m_first, m_last, s_first, s_last;
	wire					out_tvalid, out_tready, out_tlast;
	wire					in_tvalid, in_tready, in_tlast;


	interface_in interface_in_inst (
		 .clk				( clk )
		,.rst_n				( rst_n )

		,.s_tdata			( s_in_tdata )
		,.s_tvalid			( s_in_tvalid )
		,.s_tready			( s_in_tready )
		,.s_tlast			( s_in_tlast )

		,.s_first			( s_first )
		,.s_last			( s_last )

		,.m_tdata			( in_tdata )
		,.m_tvalid			( in_tvalid )
		,.m_tready			( in_tready )
		,.m_tlast			( in_tlast )
	);


	interface_out interface_out_inst (
		 .clk				( clk )
		,.rst_n				( rst_n )
		,.s_tdata			( out_tdata )
		,.s_tvalid			( out_tvalid )
		,.s_tready			( out_tready )
		,.s_tkeep			( 16'hffff )
		,.s_tlast			( out_tlast )

		,.m_first			( m_first )
		,.m_last			( m_last )

		,.m_tdata			( m_out_tdata )
		,.m_tvalid			( m_out_tvalid )
		,.m_tready			( m_out_tready )
		,.m_tkeep			( m_out_tkeep )
		,.m_tlast			( m_out_tlast )
	);


	stream_interface # (
		 .RMODE				( RMODE )
		,.WMODE				( WMODE )
	)
	stream_interface_inst (
		 .clk				( clk )
		,.rst_n				( rst_n )
		,.s_instruct_tdata	( s_instruct_tdata )
		,.s_instruct_tvalid	( s_instruct_tvalid )
		,.s_instruct_tready	( s_instruct_tready )
		,.s_in_tdata		( in_tdata )
		,.s_in_tvalid		( in_tvalid )
		,.s_in_tready		( in_tready )
		,.s_in_tlast		( in_tlast )
		,.s_first			( s_first )
		,.s_last			( s_last )
		,.m_out_tdata		( out_tdata )
		,.m_out_tvalid		( out_tvalid )
		,.m_out_tready		( out_tready )
		,.m_out_tlast		( out_tlast )
		,.m_first			( m_first )
		,.m_last			( m_last )
		,.weight_switch		( weight_switch )

		,.addr_l			( addr_l )
		,.din_l				( din_l )
		,.dout_l			( dout_l )
		,.we_l				( we_l )

		,.addr_h			( addr_h )
		,.din_h				( din_h )
		,.dout_h			( dout_h )
		,.we_h				( we_h )
	);


endmodule
