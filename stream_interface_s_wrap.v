/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/08/23
* Design Name:    poly_systolic_hw
* Module Name:    stream_interface_s_wrap
* Project Name:   bram_streams_
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


module stream_interface_s_wrap # (
	parameter RMODE = 2'b01,
	parameter WMODE = 2'b00
)(
	 input										clk
	,input										rst_n

	,input	[63:0]								s_instruct_tdata
	,input										s_instruct_tvalid
	,output										s_instruct_tready

	,input	[127:0]								s_in_tdata
	,input										s_in_tvalid
	,output										s_in_tready
	,input	[15:0]								s_in_tkeep
	,input										s_in_tlast

	,output	reg	[127:0]							m_out_tdata
	,output	reg									m_out_tvalid
	,input										m_out_tready
	,output	[15:0]								m_out_tkeep
	,output	reg									m_out_tlast

	,output										weight_switch

	,output	[13:0]								addr_l
	,output	[127:0]								din_l
	,input	[127:0]								dout_l
	,output										we_l

	,output	[13:0]								addr_h
	,output	[127:0]								din_h
	,input	[127:0]								dout_h
	,output										we_h
);


	//wire	[127:0]			out_tdata, in_tdata;
	wire	[127:0]			out_tdata;
	//wire	[5:0]			m_first, m_last, s_first, s_last;
	//wire	[5:0]			m_first, m_last;
	wire					out_tvalid, out_tready, out_tlast;
	//wire					in_tvalid, in_tready, in_tlast;


	//interface_in interface_in_inst (
		 //.clk				( clk )
		//,.rst_n				( rst_n )

		//,.s_tdata			( s_in_tdata )
		//,.s_tvalid			( s_in_tvalid )
		//,.s_tready			( s_in_tready )
		//,.s_tlast			( s_in_tlast )

		//,.s_first			( s_first )
		//,.s_last			( s_last )

		//,.m_tdata			( in_tdata )
		//,.m_tvalid			( in_tvalid )
		//,.m_tready			( in_tready )
		//,.m_tlast			( in_tlast )
	//);


	//interface_out interface_out_inst (
		 //.clk				( clk )
		//,.rst_n				( rst_n )
		//,.s_tdata			( out_tdata )
		//,.s_tvalid			( out_tvalid )
		//,.s_tready			( out_tready )
		//,.s_tkeep			( 16'hffff )
		//,.s_tlast			( out_tlast )

		//,.m_first			( m_first )
		//,.m_last			( m_last )

		//,.m_tdata			( m_out_tdata )
		//,.m_tvalid			( m_out_tvalid )
		//,.m_tready			( m_out_tready )
		//,.m_tkeep			( m_out_tkeep )
		//,.m_tlast			( m_out_tlast )
	//);


	always @(posedge clk) begin
		if (~rst_n) begin
			m_out_tdata <= 128'h0;
			m_out_tlast <= 1'b0;
		end
		else if (out_tvalid & out_tready) begin
			m_out_tdata <= out_tdata;
			m_out_tlast <= out_tlast;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			m_out_tvalid <= 1'b0;
		end
		else if (out_tvalid) begin
			m_out_tvalid <= 1'b1;
		end
		else if (m_out_tready) begin
			m_out_tvalid <= 1'b0;
		end
	end

	assign out_tready = (m_out_tready | ~m_out_tvalid) & rst_n;


	stream_interface_s # (
		 .RMODE				( RMODE )
		,.WMODE				( WMODE )
	)
	stream_interface_s_inst (
		 .clk				( clk )
		,.rst_n				( rst_n )

		,.s_instruct_tdata	( s_instruct_tdata )
		,.s_instruct_tvalid	( s_instruct_tvalid )
		,.s_instruct_tready	( s_instruct_tready )
		,.s_in_tdata		( s_in_tdata )
		,.s_in_tvalid		( s_in_tvalid)
		,.s_in_tready		( s_in_tready )
		,.s_in_tlast		( s_in_tlast )
		,.m_out_tdata		( out_tdata )
		,.m_out_tvalid		( out_tvalid )
		,.m_out_tready		( out_tready )
		,.m_out_tlast		( out_tlast )
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
