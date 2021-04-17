`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [2:0] ALUop,
	output Overflow,
	output CarryOut,
	output Zero,
	output [`DATA_WIDTH - 1:0] Result
);

	// TODO: Please add your logic code here
	parameter MSB = `DATA_WIDTH - 1;
	wire op_and;
	wire op_or;
	wire op_add;
	wire op_sub;
	wire op_slt;
	wire op_sltu;
	wire op_xor;
	wire op_nor;

	assign op_and = ALUop == 3'b000;
	assign op_or = ALUop  == 3'b001;
	assign op_add = ALUop == 3'b010;
	assign op_sub = ALUop == 3'b110;
	assign op_slt = ALUop == 3'b111;
	assign op_sltu = ALUop == 3'b011;
	assign op_xor = ALUop == 3'b100;
	assign op_nor = ALUop == 3'b101;

	wire [`DATA_WIDTH-1:0] and_result;
	wire [`DATA_WIDTH-1:0] or_result;
	wire [`DATA_WIDTH-1:0] add_sub_result;
	wire [`DATA_WIDTH-1:0] slt_result;
	wire [`DATA_WIDTH-1:0] sltu_result;
	wire [`DATA_WIDTH-1:0] xor_result;
	wire [`DATA_WIDTH-1:0] nor_result;
	wire [`DATA_WIDTH-1:0] B_adder;
	wire Cout;
	wire Cin;

	assign and_result = A & B;
	assign or_result  = A | B;
	assign xor_result = A ^ B;
	assign nor_result = ~(A | B);
	assign B_adder = (op_sub | op_slt | op_sltu)? ~B:B;
	assign Cin 	   = (op_sub | op_slt | op_sltu)? 1'b1:1'b0;
	assign {Cout,add_sub_result} = A + B_adder + Cin;
	
	assign CarryOut = (op_add & Cout) | ((op_sub|op_slt|op_sltu) & ~Cout);
	assign Overflow = (A[MSB] ^~ B_adder[MSB]) & (add_sub_result[MSB] ^ A[MSB]);
	assign slt_result = add_sub_result[MSB] ^ Overflow;
	assign sltu_result = {31'b0, ~Cout};
	
	assign Result = ({`DATA_WIDTH{op_and}} 			& and_result)
				  | ({`DATA_WIDTH{op_or}} 			& or_result)
				  | ({`DATA_WIDTH{op_add|op_sub}} 	& add_sub_result)
				  | ({`DATA_WIDTH{op_slt}} 			& slt_result)
				  | ({`DATA_WIDTH{op_sltu}} 		& sltu_result)
				  | ({`DATA_WIDTH{op_xor}} 			& xor_result)
				  | ({`DATA_WIDTH{op_nor}} 			& nor_result);
	assign Zero = Result==`DATA_WIDTH'b0;
endmodule