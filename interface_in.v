/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/08/24
* Design Name:    poly_systolic_hw
* Module Name:    interface_in
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


module interface_in (
	 input										clk
	,input										rst_n

	,input	[1535:0]							s_tdata
	,input										s_tvalid
	,output										s_tready
	,input	[15:0]								s_tkeep
	,input	[23:0]								s_tlast

	,input	[5:0]								s_first
	,input	[5:0]								s_last

	,output	reg [1535:0]						m_tdata
	,output	reg									m_tvalid
	,input										m_tready
	,output	reg	[15:0]							m_tkeep = 16'hffff
	,output										m_tlast
);


	reg		[1535:0]				tdata_reg;
	wire	[1535:0]				data_h, data_l;
	wire	[11:0]					data_h_shift, data_l_shift;
	reg								m_valid_reg, m_last_reg, first_reg;

	wire							last_word;


	always @(posedge clk) begin
		if (~rst_n) begin
			tdata_reg <= 1536'h0;
		end
		else if (s_tvalid & s_tready) begin
			tdata_reg <= s_tdata;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			m_valid_reg <= 1'b0;
		end
		else begin
			if (s_tvalid & s_tready) begin
				if (last_word && s_first + s_last < 24) begin
					m_valid_reg <= 1'b0;
				end
				else begin
					m_valid_reg <= 1'b1;
				end
			end
			else if (m_tvalid & m_tready) begin
				m_valid_reg <= 1'b0;
			end
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			first_reg <= 1'b1;
		end
		else begin
			if (first_reg & s_tvalid & s_tready) begin
				first_reg <= 1'b0;
			end
			else if (m_tlast) begin
				first_reg <= 1'b1;
			end
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			m_last_reg <= 1'b0;
		end
		else begin
			if (s_tvalid && (~m_tready || s_first + s_last > 23)) begin
				m_last_reg <= last_word;
			end
			else if (m_tready) begin
				m_last_reg <= 1'b0;
			end
		end
	end


	always @( * ) begin
		if (~rst_n) begin
			m_tdata = 1536'h0;
		end
		else begin
			if (first_reg) begin
				m_tdata = data_h;
			end
			else if (s_first + s_last > 23 && m_tlast) begin
				m_tdata = data_l;
			end
			else begin
				m_tdata = data_h | data_l;
			end
		end
	end

	always @( * ) begin
		if (~rst_n) begin
			m_tvalid = 0;
		end
		else begin
			if (first_reg) begin
				m_tvalid = s_tvalid;
			end
			else if (s_first + s_last > 23 && m_tlast) begin
				m_tvalid = m_valid_reg;
			end
			else begin
				m_tvalid = s_tvalid & m_valid_reg;
			end
		end
	end

	assign last_word = |s_tlast;
	assign m_tlast = (s_first + s_last < 24 && last_word) || m_last_reg;

	assign data_h_shift = {s_first, 6'h0};
	assign data_l_shift = {6'd24 - s_first, 6'h0};

	assign data_h = s_tdata << data_h_shift;
	assign data_l = tdata_reg >> data_l_shift;

	assign s_tready = m_tready;


endmodule
