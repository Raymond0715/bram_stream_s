/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/08/24
* Design Name:    poly_systolic_hw
* Module Name:    interface_out
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


module interface_out (
	 input										clk
	,input										rst_n

	,input	[1535:0]							s_tdata
	,input										s_tvalid
	,output										s_tready
	,input	[15:0]								s_tkeep
	,input										s_tlast

	,input	[5:0]								m_first
	,input	[5:0]								m_last

	,output	[1535:0]							m_tdata
	,output										m_tvalid
	,input										m_tready
	,output	reg	[15:0]							m_tkeep = 16'hffff
	,output	[23:0]								m_tlast

);


	reg		[1535:0]				out_tdata_reg;
	wire	[1535:0]				m_out_tdata_h, m_out_tdata_l;
	wire	[11:0]					tdata_h_shift, tdata_l_shift;
	reg		[23:0]					m_out_tlast_reg;
	reg								out_tvalid_reg, out_tlast_reg;


	always @(posedge clk) begin
		if (~rst_n) begin
			out_tdata_reg <= 1536'h0;
		end
		else if (s_tvalid & s_tready) begin
			out_tdata_reg <= s_tdata;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			out_tlast_reg <= 1'b0;
		end
		else begin
			if (s_tvalid & s_tready) begin
				out_tlast_reg <= s_tlast;
			end
			else if (out_tlast_reg & m_tready) begin
				out_tlast_reg <= 1'b0;
			end
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			m_out_tlast_reg <= 24'h0;
		end
		else begin
			m_out_tlast_reg <= 1 << m_last;
		end
	end


	assign m_tlast = out_tlast_reg ? m_out_tlast_reg : 24'h0;


	always @(posedge clk) begin
		if (~rst_n) begin
			out_tvalid_reg <= 1'b0;
		end
		else begin
			if (s_tvalid) begin
				out_tvalid_reg <= 1'b1;
			end
			else if (m_tready) begin
				out_tvalid_reg <= 1'b0;
			end
		end
	end

	assign tdata_h_shift = {6'd24 - m_first, 6'h0};
	assign tdata_l_shift = {m_first, 6'h0};

	assign m_out_tdata_h = s_tdata << tdata_h_shift;
	assign m_out_tdata_l = out_tdata_reg >> tdata_l_shift;

	assign s_tready = (m_tready | ~out_tvalid_reg) & rst_n;
	assign m_tdata = out_tlast_reg ?
					  m_out_tdata_l : m_out_tdata_h | m_out_tdata_l;
	assign m_tvalid = out_tvalid_reg;


endmodule
