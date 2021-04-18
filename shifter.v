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

	assign sll = Shiftop == 2'b00;
	assign sra = Shiftop == 2'b11;
	assign srl = Shiftop == 2'b10;
	assign Result = ({`DATA_WIDTH{sll}} 	& (A << B[4:0])          )
				  | ({`DATA_WIDTH{sra}} 	& ($signed(A)) >>> B[4:0])
				  | ({`DATA_WIDTH{srl}} 	& (A >> B[4:0])          );
	
endmodule
