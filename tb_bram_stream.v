`timescale 1ns/1ps

module tb_bram_stream ;


	// Clock and reset
	reg		clk = 1;
	reg		rst_n = 0;

	parameter PERIOD = 5;

	initial
	begin
		forever # (PERIOD/2) clk=~clk;
	end


	initial
	begin
		# (PERIOD * 5)	rst_n = 1;
	end


	// Logic
	wire	[63:0]				instruct_tdata;
	wire						instruct_tready, instruct_tvalid;

	data_gen # (
		.WIDTH					( 64 ),
		.LENGTH					( 3 ),
		.DPATH					( "/media/Projects/poly_systolic_unit/py-sim/dat/bram_stream/instruct.txt" ),
		.PERIOD					( PERIOD ),
		.RAND_CYC				( 8 )
	)
	instruct_gen (
		.clk					( clk ),
		.rst_n					( rst_n ),
		.m_tdata				( instruct_tdata ),
		.m_tvalid				( instruct_tvalid ),
		.m_tready				( instruct_tready ),
		.m_tlast				( )
	);

	wire	[1535:0]			in_a_tdata, in_b_tdata, out_a_tdata, out_b_tdata;
	wire						in_a_tready, in_a_tvalid, in_b_tready, in_b_tvalid,
								out_a_tready, out_a_tvalid, out_b_tready, out_b_tvalid;
	wire						in_a_tlast;
	wire	[23:0]				in_b_tlast;
	reg							out_a_tready_reg, out_a_tready_reg_pad,
								out_b_tready_reg, out_b_tready_reg_pad;

	assign out_a_tready = out_a_tready_reg_pad;
	assign out_b_tready = out_b_tready_reg_pad;

	integer delay1, delay2, k;
	initial
		begin
			out_a_tready_reg = 0;
			for (k = 0; k < 100; k = k+1)
				begin
					delay1 = PERIOD * ( {$urandom} % 8 );
					delay2 = PERIOD * ( {$urandom} % 8 );
					# delay1 out_a_tready_reg = 1;
					# delay2 out_a_tready_reg = 0;
				end
		end

	integer delay3, delay4, j;
	initial
		begin
			out_b_tready_reg = 1;
			for (j = 0; j < 100; j = j+1)
				begin
					delay3 = PERIOD * ( {$random} % 12 );
					delay4 = PERIOD * ( {$random} % 12 );
					# delay3 out_b_tready_reg = 1;
					# delay4 out_b_tready_reg = 0;
				end
		end


	always @(posedge clk) begin
		out_a_tready_reg_pad <= out_a_tready_reg;
		out_b_tready_reg_pad <= out_b_tready_reg;
	end


	data_gen # (
		.WIDTH					( 1536 ),
		.LENGTH					( 64 ),
		.DPATH					( "/media/Projects/poly_systolic_unit/py-sim/dat/bram_stream/input.txt" ),
		.PERIOD					( PERIOD ),
		.RAND_CYC				( 8 )
	)
	data_gen_inst (
		.clk					( clk ),
		.rst_n					( rst_n ),
		.m_tdata				( in_a_tdata ),
		.m_tvalid				( in_a_tvalid ),
		.m_tready				( in_a_tready ),
		.m_tlast				( in_a_tlast )
	);


	bram_stream_s bram_stream_inst (
		 .clk						( clk )
		,.rst_n						( rst_n )

		,.s_instruct_a_tdata		( instruct_tdata )
		,.s_instruct_a_tvalid		( instruct_tvalid )
		,.s_instruct_a_tready		( instruct_tready )

		,.s_instruct_b_tdata		( )
		,.s_instruct_b_tvalid		( )
		,.s_instruct_b_tready		( )

		,.s_in_a_tdata				( in_a_tdata )
		,.s_in_a_tvalid				( in_a_tvalid )
		,.s_in_a_tready				( in_a_tready )
		,.s_in_a_tlast				( {23'h0, in_a_tlast} )

		,.m_out_a_tdata				( out_a_tdata )
		,.m_out_a_tvalid			( out_a_tvalid )
		,.m_out_a_tready			( out_a_tready )
	);


	integer handle0 ;
	initial handle0=$fopen("/media/Projects/poly_systolic_unit/py-sim/dat/bram_stream/out_a_sim.txt");
	always @ (posedge clk) begin
		if (rst_n) begin
			if (out_a_tvalid & out_a_tready) begin
				$fdisplay(handle0,"%h", out_a_tdata);
			end
		end
	end

endmodule
