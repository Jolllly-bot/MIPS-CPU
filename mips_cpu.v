`timescale 10ns / 1ns

module mips_cpu(
	input  rst,
	input  clk,

	output reg [31:0] PC,
	input  [31:0] Instruction,

	output [31:0] Address,
	output MemWrite,
	output [31:0] Write_data,
	output [3:0] Write_strb,

	input  [31:0] Read_data,
	output MemRead
);

	// THESE THREE SIGNALS ARE USED IN OUR TESTBENCH
	// PLEASE DO NOT MODIFY SIGNAL NAMES
	// AND PLEASE USE THEM TO CONNECT PORTS
	// OF YOUR INSTANTIATION OF THE REGISTER FILE MODULE
	wire			RF_wen;
	wire [4:0]		RF_waddr;
	wire [31:0]		RF_wdata;

	// TODO: PLEASE ADD YOUT CODE BELOW
	//alu define
	wire  [31:0]    ALU_A;
	wire  [31:0]    ALU_B;
	wire  [2:0]     ALUop;
	wire  [31:0]    ALU_result;
	wire		    ALU_overflow;
	wire            ALU_carryout;
	wire            ALU_zero;
	//reg_file define
	wire  [4:0]     raddr1;
	wire  [4:0]     raddr2;
	wire  [31:0]    rdata1;
	wire  [31:0]    rdata2;
	//shifter define
	wire  [31:0]    Shift_A;
	wire  [31:0]    Shift_B;
	wire  [1:0]     Shiftop;
	wire  [31:0]    Shift_result;
	//instruction
	wire  [5:0]     Opcode;
	wire  [5:0]     Func;
	wire  [4:0]     rs;
	wire  [4:0]     rd;
	wire  [4:0]     rt;
	wire  [4:0]     sa;
	//type decode
	wire Rtype;
	wire REGIMM;
	wire Jtype;
	wire Ibranch;
	wire Ioprt;
	wire Iload;
	wire Istore;
	wire Ibeq;
	wire Iblez;
	wire op_shift;
	wire op_jump;
	wire op_mov;
	wire jumpal;
	wire jr;
	wire jal;
	wire lui;
	//control signals
	wire RegDst;
	wire Jump;
	wire Mem2Reg;
	wire ALUsrc;
	wire RegWrite;
	wire ALUop0;
	wire ALUop1;
	wire PCsrc;
	//sign extesion
	wire  [31:0]    sign_ext;
	wire  [31:0]    zero_ext;
	wire  [31:0]    shift_ext;
	wire  [31:0]    imm_data;
	//PC
	wire  [31:0]    PC_next;
	wire  [31:0]    PC_plus4;
	wire  [31:0]    PC_add;
	wire  [31:0]    PC_result;
	wire  [31:0]    PC_tar;
	wire  [31:0]    Jump_tar;
	wire  [31:0]    Jump_addr;
	//load & store
	wire 			sb;
	wire 			sh;
	wire 			sw;
	wire 			swl;
	wire 			swr;
	wire  [3:0]     addrtype;//one-hot code
	wire  [31:0]    swl_data;
	wire  [31:0]    swr_data;
	wire  			lbu;     //others are same as store
	wire  			lhu;
	wire  [31:0]    lb_data;
	wire  [31:0]    lh_data;
	wire  [31:0]    lw_data;
	wire  [31:0]    lbu_data;
	wire  [31:0]    lhu_data;
	wire  [31:0]    lwl_data;
	wire  [31:0]    lwr_data;
	wire  [31:0]    Load_data;
	//others
	wire  [31:0]    lui_data;
	wire  [31:0]    Data_result;
	wire 			mov_judge;//if (==1) rf_wen=0
	wire  [3:0]		func_m;
	wire  [3:0]		opcode_modified;

	// **********************************

	/*
	instruction
	*/
	assign Opcode = Instruction[31:26];
	assign rs     = Instruction[25:21];
	assign rt     = Instruction[20:16];
	assign rd     = Instruction[15:11];
	assign sa     = Instruction[10:6];
	assign Func   = Instruction[5:0];

	/*
	decoder
	*/
	assign Rtype   = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] & ~Opcode[2]) & (~Opcode[1] & ~Opcode[0]);//6'b000000
	assign REGIMM  = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] & ~Opcode[2]) & (~Opcode[1] & Opcode[0]);//6'b000001
	assign Jtype   = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] & ~Opcode[2]) &   Opcode[1];//5'b000001
	assign Ibranch = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] &  Opcode[2]);//4'b0001
	assign Ioprt   = (~Opcode[5] & ~Opcode[4]) &   Opcode[3];//3'b001
	assign Iload   = ( Opcode[5] & ~Opcode[4]) &  ~Opcode[3];//3'b100
	assign Istore  = ( Opcode[5] & ~Opcode[4]) &   Opcode[3];//3'b101

	assign Ibeq = Ibranch & ~Opcode[1];
	assign Iblez = Ibranch & Opcode[1];
	assign op_shift = Rtype & Func[5:3]==3'b000;
	assign op_jump = Rtype & {Func[5:3], Func[1]} == 4'b0010;
	assign op_mov = Rtype & {Func[5:3],Func[1]} == 4'b0011;
	assign jumpal = (op_jump & Func[0]) | (Jtype & Opcode[0]);
	assign jr = op_jump & ~Func[0];
	assign jal = Jtype & Opcode[0];
	assign lui = Ioprt & Opcode[2:0]==3'b111;

	/*
	control unit
	*/
	assign MemRead = Opcode[5] & (~Opcode[3]);
	assign MemWrite = Opcode[5] & Opcode[3];
	assign RegDst = Rtype;
	assign Jump = Jtype | op_jump;
	assign ALUsrc = Iload | Istore | Ioprt;
	assign Mem2Reg = Iload;
	assign RegWrite = Rtype | Iload | Ioprt | jal;
	assign ALUop1 = Rtype | Ioprt | Iblez | REGIMM;
	assign ALUop0 = Ibranch | REGIMM ;
	assign PCsrc = (Ibranch & (Opcode[0] ^ ALU_zero)) | (REGIMM & (rt[0] ^~ ALU_zero));

	/*
	sign extension
	*/
	assign sign_ext  = {{16{Instruction[15]}}, Instruction[15:0]};
	assign zero_ext  = { 16'b0               , Instruction[15:0]};
	assign shift_ext = { sign_ext[29:0]      , 2'b00};
	assign imm_data = Opcode[2]? zero_ext : sign_ext;

	/*
	PC
	*/
	assign PC_plus4 = PC + 32'd4;
	assign PC_add = jumpal ? 32'd4 : shift_ext;
	assign PC_result = PC_plus4 + PC_add;
	assign Jump_tar = {PC_plus4[31:28],Instruction[25:0],2'b00};
	assign Jump_addr = op_jump? rdata1 : Jump_tar;
	assign PC_tar = PCsrc? PC_result : PC_plus4;
	assign PC_next = Jump? Jump_addr : PC_tar;

	always @(posedge clk) begin
		if(rst) PC<=32'd0; 
		else PC <= PC_next;
	end

	/*
	store
	*/
	assign sb  = ~Opcode[2] & ~Opcode[1] & ~Opcode[0];//Opcode[2:0]==3'b000;
	assign sh  = ~Opcode[2] & ~Opcode[1] &  Opcode[0];//3'b001;
	assign sw  = ~Opcode[2] &  Opcode[1] &  Opcode[0];//3'b011;
	assign swl = ~Opcode[2] &  Opcode[1] & ~Opcode[0];//3'b010;
	assign swr =  Opcode[2] &  Opcode[1] & ~Opcode[0];//3'b110;
	assign addrtype[0] = ~ALU_result[1] & ~ALU_result[0];//2'b00;
	assign addrtype[1] = ~ALU_result[1] &  ALU_result[0];//2'b01;
	assign addrtype[2] =  ALU_result[1] & ~ALU_result[0];//2'b10;
	assign addrtype[3] =  ALU_result[1] &  ALU_result[0];//2'b11;

	assign Write_strb[3] = sw | sb & addrtype[3] | sh & addrtype[2] | swl &  addrtype[3] 				 | swr;
	assign Write_strb[2] = sw | sb & addrtype[2] | sh & addrtype[2] | swl & (addrtype[3] | addrtype[2])  | swr & ~addrtype[3];
	assign Write_strb[1] = sw | sb & addrtype[1] | sh & addrtype[0] | swl & ~addrtype[0] 				 | swr & (addrtype[0] | addrtype[1]);
	assign Write_strb[0] = addrtype[0] | swl;

	assign swr_data = ({32{addrtype[3]}} & {rdata2[ 7:0],24'd0})
				    | ({32{addrtype[2]}} & {rdata2[15:0],16'd0})
				    | ({32{addrtype[1]}} & {rdata2[23:0], 8'd0})
				    | ({32{addrtype[0]}} & rdata2);
	assign swl_data = ({32{addrtype[3]}} & rdata2)
				    | ({32{addrtype[2]}} & { 8'd0,rdata2[31:8]})
				    | ({32{addrtype[1]}} & {16'd0,rdata2[31:16]})
				    | ({32{addrtype[0]}} & {24'd0,rdata2[31:24]});
	assign Write_data = ({32{sb}}  & {4{rdata2[7:0]}})
					  | ({32{sh}}  & {2{rdata2[15:0]}})
					  | ({32{sw}}  & rdata2)
					  | ({32{swl}} & swl_data)
					  | ({32{swr}} & swr_data);

	/*
	load
	*/
	assign lbu =  Opcode[2] & ~Opcode[1] & ~Opcode[0];//Opcode[2:0]==3'b100;
	assign lhu =  Opcode[2] & ~Opcode[1] &  Opcode[0];//Opcode[2:0]==3'b101;

	assign lb_data = ({32{addrtype[3]}} & {{24{Read_data[31]}}, Read_data[31:24]})
				   | ({32{addrtype[2]}} & {{24{Read_data[23]}}, Read_data[23:16]})
				   | ({32{addrtype[1]}} & {{24{Read_data[15]}}, Read_data[15:8]})
				   | ({32{addrtype[0]}} & {{24{Read_data[7]}} , Read_data[7:0]});
	assign lh_data = ({32{(addrtype[3] | addrtype[2])}} & {{16{Read_data[31]}}, Read_data[31:16]})
				   | ({32{(addrtype[1] | addrtype[0])}} & {{16{Read_data[15]}}, Read_data[15:0]});
	assign lw_data  =  Read_data[31:0];
	assign lbu_data = {24'b0, lb_data[7:0]};
	assign lhu_data = {16'b0, lh_data[15:0]};
	assign lwl_data =  ({32{addrtype[3]}} &  Read_data[31:0])
					 | ({32{addrtype[2]}} & {Read_data[23:0],  rdata2[7:0]})
					 | ({32{addrtype[1]}} & {Read_data[15:0],  rdata2[15:0]})
					 | ({32{addrtype[0]}} & {Read_data[7:0] ,  rdata2[23:0]});
	assign lwr_data = ({32{addrtype[3]}} & {rdata2[31:8] , Read_data[31:24]})
					| ({32{addrtype[2]}} & {rdata2[31:16], Read_data[31:16]})
					| ({32{addrtype[1]}} & {rdata2[31:24], Read_data[31:8]})
					| ({32{addrtype[0]}} &  Read_data[31:0]);
	assign Load_data = ({32{sb}} & lb_data)
					 | ({32{sh}} & lh_data)
					 | ({32{sw}} & lw_data)
					 | ({32{lbu}} & lbu_data)
					 | ({32{lhu}} & lhu_data)
					 | ({32{swl}} & lwl_data)
				     | ({32{swr}} & lwr_data);

	/*
	data path
	*/
	assign mov_judge = op_mov & (Func[0] ^~ rdata2==0);
	assign lui_data = {Instruction[15:0],16'd0};
	assign raddr1 = rs;
	assign raddr2 = REGIMM? 0:rt;
	assign RF_wen = (jr | mov_judge)? 0:RegWrite;
	assign RF_waddr = jal? 6'd31 :RegDst? rd:rt;
	assign Data_result = ({32{jumpal}}   & PC_result)
						|({32{lui}}      & lui_data)
						|({32{op_mov}}   & rdata1)
						|({32{op_shift}} & Shift_result)
						|({32{~jumpal & ~lui & ~op_mov & ~op_shift}} & ALU_result);
	assign RF_wdata = Mem2Reg? Load_data: Data_result;
	assign Address  = {ALU_result[31:2], 2'b00};

	/*
	alu control
	*/
	assign opcode_modified = (Opcode[2:1]==2'b01)? Opcode[3:0] : {1'b0,Opcode[2:0]};
	assign func_m = ({4{Rtype}} & Instruction [3:0]) | ({4{Ioprt}} & opcode_modified);
	assign op2 = (~func_m[3] & func_m[1]) | (func_m[1] & ~func_m[0]);
	assign op1 = ~func_m[2];
	assign op0 = (func_m[2] & func_m[0]) | func_m[3];
	assign ALUop[2] = ALUop0 | (op2 & ALUop1);
	assign ALUop[1] = ~ALUop1 | ALUop0 | op1;
	assign ALUop[0] = (ALUop1 & ALUop0) | (ALUop1 & ~ALUop0 & op0);

	assign ALU_A = Iblez? rdata2: op_mov? 32'b0 :rdata1;
	assign ALU_B = Iblez? rdata1: ALUsrc? imm_data : rdata2;

	/*
	shifter
	*/
	assign Shiftop = Func[1:0];
	assign Shift_A = rdata2;
	assign Shift_B = Func[2]? rdata1 : {27'b0,sa};

	/*
	instantiation
	*/
	alu u_alu(
		.A(ALU_A),
		.B(ALU_B),
		.ALUop(ALUop),
		.Overflow(ALU_overflow),
		.CarryOut(ALU_carryout),
		.Zero(ALU_zero),
		.Result(ALU_result)
	);
	reg_file u_reg_file(
		.clk(clk),
		.rst(rst),
		.waddr(RF_waddr),
		.raddr1(raddr1),
		.raddr2(raddr2),
		.wen(RF_wen),
		.wdata(RF_wdata),
		.rdata1(rdata1),
		.rdata2(rdata2)
	);
	shifter u_shifter(
		.A(Shift_A),
		.B(Shift_B),
	    .Shiftop(Shiftop),
		.Result(Shift_result)
	);

endmodule

