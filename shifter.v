`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module shifter (
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [1:0] Shiftop,
	output [`DATA_WIDTH - 1:0] Result
);

	// TODO: Please add your logic code here
	wire shift_left;
	wire shifta_right;
	wire shiftl_right;

	assign shift_left = Shiftop == 2'b00;
	assign shifta_right = Shiftop == 2'b11;
	assign shiftl_right = Shiftop == 2'b10;
	assign result = ({`DATA_WIDTH{shift_left}} 		& (A << B[4:0])          )
				  | ({`DATA_WIDTH{shifta_right}} 	& ($signed(A) >>> B[4:0]))
				  | ({`DATA_WIDTH{shiftl_right}} 	& (A >> B[4:0])          );
	
endmodule
