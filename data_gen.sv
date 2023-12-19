/**
*
* Company:        Zhejiang University
* Engineer:       Raymond
*
* Create Date:    2023/05/29
* Design Name:    poly_systolic_hw
* Module Name:    data_gen
* Project Name:   None
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


`timescale 1ns/1ps


module data_gen # (
	parameter WIDTH,
	parameter LENGTH,
	parameter DPATH,
	parameter PERIOD,
	parameter RAND_CYC
)
(
	input                  clk,
	input                  rst_n,

	output [WIDTH-1: 0]    m_tdata,

	output                 m_tvalid,
	output                 m_tlast,
	input                  m_tready

	);


	reg                m_tvalid_reg=1;
	reg                m_tvalid_reg_pad;

	reg  [WIDTH-1: 0]  input_data[0:LENGTH-1];


	initial begin
		$readmemh(DPATH,input_data,0,LENGTH-1);
	end

	// ----------------------------------------------------------
	reg [64:0]      count   = 64'b0   ;
	reg             valid_ctrl = 0 ;


	always @(posedge clk) begin
		if (~rst_n) begin
			count <= 0;
			valid_ctrl <= 1;
		end
		else if (count==(LENGTH-1) && m_tvalid && m_tready) begin
			valid_ctrl <=  0;
		end
		else if (m_tvalid && m_tready)
			count <= count + 1;
		else;
	end


	integer delay1, delay2, k;
	initial
		begin
			for (k = 0; k < 100; k = k+1)
				begin
					delay1 = 5 * ( {$random} % RAND_CYC );
					delay2 = 5 * ( {$random} % RAND_CYC );
					# delay1 m_tvalid_reg = 1;
					# delay2 m_tvalid_reg = 0;
				end
		end


	always @(posedge clk) begin
		m_tvalid_reg_pad <= m_tvalid_reg;
	end


	assign m_tdata = input_data[count];
	assign m_tvalid = m_tvalid_reg_pad & valid_ctrl;
	assign m_tlast = ( (count % LENGTH) == LENGTH-1 ) ? 1 : 0;


endmodule
