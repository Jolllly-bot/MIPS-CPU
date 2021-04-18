`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module shifter (
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [1:0] Shiftop,
	output [`DATA_WIDTH - 1:0] Result
);

	// TODO: Please add your logic code here
	wire sll;
	wire sra;
	wire srl;
	wire [`DATA_WIDTH - 1:0]sll_result;
	wire [`DATA_WIDTH - 1:0]sra_result;
	wire [`DATA_WIDTH - 1:0]srl_result;

	assign sll = Shiftop == 2'b00;
	assign sra = Shiftop == 2'b11;
	assign srl = Shiftop == 2'b10;
	assign sll_result = A << B[4:0];
	assign sra_result = ($signed(A)) >>> B[4:0];
	assign srl_result = A >> B[4:0];

	assign Result = ({`DATA_WIDTH{sll}} & sll_result)
				  | ({`DATA_WIDTH{sra}} & sra_result)
				  | ({`DATA_WIDTH{srl}} & srl_result);
	
endmodule
