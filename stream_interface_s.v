/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/06/05
* Design Name:    poly_systolic_hw
* Module Name:    stream_interface_s
* Project Name:   bram_stream_s
* Target Devices: ZCU 102
* Tool Versions:  Vivado 2021.2
* Description:
*
* Dependencies:
*
* Revision:
* Additional Comments:
* - There is still problem for asserting m_out_tvalid.
*
*******************************************************************************/


`include "define_bram_stream_s.vh"

module stream_interface_s # (
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
	,output	reg									s_in_tready
	,input										s_in_tkeep
	,input										s_in_tlast

	,output	[127:0]								m_out_tdata
	,output	reg									m_out_tvalid
	,input										m_out_tready
	,output	reg	[15:0]							m_out_tkeep = 16'hffff
	,output	reg									m_out_tlast

	,output	reg									weight_switch

	,output	[13:0]								addr_l
	,output	[127:0]								din_l
	,input	[127:0]								dout_l
	,output	reg									we_l

	,output	[13:0]								addr_h
	,output	[127:0]								din_h
	,input	[127:0]								dout_h
	,output	reg									we_h
);


	localparam IDLE  = 2'b00;
	localparam READ  = 2'b01;
	localparam WRITE = 2'b10;

	reg 	[127:0]				out_tdata_storage_l, out_tdata_storage_h;
	reg		[14:0]				len_reg, count;
	reg		[14:0]				addr_l_reg, addr_h_reg;
	reg		[1:0]				c_state, n_state;
	reg							has_storage_l, has_storage_h, valid_origin, conf;
	reg							write_last_pre, write_last;

	wire	[14:0]				addr_h_sub;
	wire						addr_it_n;

	assign addr_it_n = ~(m_out_tvalid & ~m_out_tready);


	// fsm
	always @(posedge clk) begin
		if (~rst_n) begin
			c_state <= IDLE;
		end
		else begin
			c_state <= n_state;
		end
	end


	always @( * ) begin
		if (~rst_n) begin
			n_state = IDLE;
		end
		else begin
			case(c_state)
				IDLE:
					begin
						if (s_instruct_tvalid
							&& s_instruct_tdata[31:30] == RMODE) begin
							n_state = READ;
						end
						else if (s_instruct_tvalid
							&& s_instruct_tdata[31:30] == WMODE) begin
							n_state = WRITE;
						end
						else begin
							n_state = IDLE;
						end
					end

				READ:
					begin
						if (m_out_tvalid & m_out_tready
								&& count == len_reg) begin
							n_state = IDLE;
						end
						else begin
							n_state = READ;
						end
					end

				WRITE:
					begin
						// write end
						if (s_in_tvalid & s_in_tready & write_last) begin
							n_state = IDLE;
						end
						else begin
							n_state = WRITE;
						end
					end
			endcase
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			conf <= 1'b0;
			addr_l_reg <= 15'h0;
			addr_h_reg <= 15'h0;
			count <= 15'h0;
			s_in_tready <= 1'b0;
			len_reg <= 15'h0;
			valid_origin <= 1'b0;
			weight_switch <= 1'b0;
		end
		else if (n_state == READ) begin
			if (~conf) begin
				conf <= 1'b1;
				weight_switch <= s_instruct_tdata[33];
				addr_l_reg <= s_instruct_tdata[29:15];
				addr_h_reg <= s_instruct_tdata[29:15];
				len_reg <= s_instruct_tdata[14:0];
				valid_origin <= 1'b1;
			end
			else if (addr_it_n && ((~has_storage_l & ~has_storage_h) | m_out_tready)
					&& count < len_reg) begin
				addr_l_reg <= addr_l_reg + 15'h1;
				addr_h_reg <= addr_h_reg + 15'h1;
				count <= count + 15'h1;
			end
		end
		else if (n_state == WRITE) begin
			if (~conf) begin
				conf <= 1'b1;
				weight_switch <= s_instruct_tdata[33];
				addr_l_reg <= s_instruct_tdata[29:15];
				addr_h_reg <= s_instruct_tdata[29:15];
				len_reg <= s_instruct_tdata[14:0];
				s_in_tready <= 1'b1;
			end
			else if (s_in_tvalid) begin
				addr_l_reg <= addr_l_reg + 15'h1;
				addr_h_reg <= addr_h_reg + 15'h1;
				count <= count + 15'h1;
			end
		end
		else begin
			weight_switch <= 1'b0;
			conf <= 1'b0;
			addr_l_reg <= 15'h0;
			addr_h_reg <= 15'h0;
			count <= 15'h0;
			s_in_tready <= 1'b0;
			len_reg <= 15'h0;
			valid_origin <= 1'b0;
		end
	end


	assign addr_h_sub = addr_h_reg - 15'h12544;

	assign addr_l = addr_l_reg < 15'd12544 ? addr_l_reg[13:0] : 14'd12543;
	assign addr_h = addr_h_reg < 15'd12544 ? 14'd0 : addr_h_sub[13:0];

	assign din_l = s_in_tdata;
	assign din_h = s_in_tdata;


	always @(posedge clk) begin
		if (~rst_n) begin
			write_last_pre <= 1'b0;
		end
		else if (s_in_tvalid & s_in_tready) begin
			if (count == len_reg - 3) begin
				write_last_pre <= 1'b1;
			end
			else begin
				write_last_pre <= 1'b0;
			end
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			write_last <= 1'b0;
		end
		else if (s_in_tvalid & s_in_tready) begin
			write_last <= write_last_pre;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			we_l <= 1'b0;
		end
		else if (n_state == WRITE && addr_l_reg < 15'd12544) begin
			we_l <= 1'b1;
			//if (~conf) begin
				//we_l <= `WE_192 << {6'd23 - s_instruct_tdata[34:30], 8'h0};
			//end
			//else if (write_last_pre) begin
				//we_l <= `WE_192 >> {6'd23 - s_instruct_tdata[34:30], 8'h0};
			//end
			//else begin
				//we_l <= `WE_192;
			//end
		end
		else begin
			we_l <= 1'b0;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			we_h <= 1'h0;
		end
		else if (n_state == WRITE && addr_l_reg >= 15'd12544) begin
			we_h <= 1'b1;
			//if (~conf) begin
				//we_h <= `WE_192 << {6'd23 - s_instruct_tdata[34:30], 8'h0};
			//end
			//else if (write_last_pre) begin
				//we_h <= `WE_192 >> {6'd23 - s_instruct_tdata[34:30], 8'h0};
			//end
			//else begin
				//we_h <= `WE_192;
			//end
		end
		else begin
			we_h <= 1'h0;
		end
	end


	// Control signal
	assign s_instruct_tready = c_state == IDLE ? 1 : 0;


	always @(posedge clk) begin
		if (~rst_n) begin
			m_out_tvalid <= 1'b0;
		end
		else if (n_state == READ) begin
			if (valid_origin) begin
				m_out_tvalid <= 1'b1;
			end
		end
		else begin
			m_out_tvalid <= 1'b0;
		end
	end


	reg m_out_tready_pad_l, m_out_tready_pad_h;

	always @(posedge clk) begin
		if (~rst_n) begin
			m_out_tready_pad_l <= 1'b0;
			m_out_tready_pad_h <= 1'b0;
		end
		else if (c_state == READ && n_state == READ) begin
			m_out_tready_pad_l <= m_out_tready;
			m_out_tready_pad_h <= m_out_tready;
		end
		else begin
			m_out_tready_pad_l <= 1'b0;
			m_out_tready_pad_h <= 1'b0;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			has_storage_l <= 1'b0;
		end
		else if (n_state == READ &&
				((m_out_tready_pad_l | (~has_storage_l & m_out_tvalid))
					& ~m_out_tready) &&
				addr_l_reg < 15'd12544) begin
			has_storage_l <= 1'b1;
		end
		else if (n_state == READ &&
				(~m_out_tready_pad_l & m_out_tready & has_storage_l)) begin
			has_storage_l <= 1'b0;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			has_storage_h <= 1'b0;
		end
		else if (n_state == READ &&
				((m_out_tready_pad_h | (~has_storage_h & m_out_tvalid))
					& ~m_out_tready) &&
				addr_h_reg >= 15'd12544) begin
			has_storage_h <= 1'b1;
		end
		else if (n_state == READ &&
				(~m_out_tready_pad_h & m_out_tready & has_storage_h)) begin
			has_storage_h <= 1'b0;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			out_tdata_storage_l <= 127'h0;
		end
		else if (n_state == READ
				&& (m_out_tready_pad_l | ~has_storage_l)) begin
			out_tdata_storage_l <= dout_l;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			out_tdata_storage_h <= 127'h0;
		end
		else if (n_state == READ
				&& (m_out_tready_pad_h | ~has_storage_h)) begin
			out_tdata_storage_h <= dout_h;
		end
	end


	always @(posedge clk) begin
		if (~rst_n) begin
			m_out_tlast <= 1'b0;
		end
		else if (c_state == READ) begin
			if (count == len_reg - 1 && m_out_tvalid && m_out_tready) begin
				m_out_tlast <= 1'b1;
			end
			else begin
				m_out_tlast <= 1'b0;
			end
		end
		else begin
			m_out_tlast <= 1'b0;
		end
	end


	assign m_out_tdata = addr_l_reg < 15'd12545 ?
					  has_storage_l ? out_tdata_storage_l : dout_l :
					  has_storage_h ? out_tdata_storage_h : dout_h;


endmodule
