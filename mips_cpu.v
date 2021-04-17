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

	wire [31:0]ALU_A;
	wire [31:0]ALU_B;
	wire [2:0]ALUop;
	wire [31:0]ALU_result;
	wire Overflow;
	wire CarryOut;
	wire Zero;
	alu u_alu(
		.A(ALU_A),
		.B(ALU_B),
		.ALUop(ALUop),
		.Overflow(Overflow),
		.CarryOut(CarryOut),
		.Zero(zero),
		.Result(ALU_result)
	);

	wire [4:0]raddr1;
	wire [4:0]raddr2;
	wire [31:0]rdata1;
	wire [31:0]rdata2;
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

	wire [31:0]Shift_A;
	wire [31:0]Shift_B;
	wire [1:0]Shiftop;
	wire [31:0]Shift_result;
	shifter u_shifter(
		.A(Shift_A),
		.B(Shift_B),
	    .Shiftop(Shiftop),
		.Result(Shift_result)
	);

	// **********************************

	/*
	instruction
	*/
	wire [5:0]Opcode;
	wire [5:0]Func;
	wire [5:0]rs;
	wire [5:0]rd;
	wire [5:0]rt;
	wire [5:0]sa;

	assign Opcode = Instruction[31:26];
	assign rs     = Instruction[25:21];
	assign rt     = Instruction[20:16];
	assign rd     = Instruction[15:11];
	assign sa     = Instruction[10:6];
	assign Func   = Instruction[5:0];

	/*
	decoder
	*/
	wire Rtype;
	wire REGIMM;
	wire Jtype;
	wire Ibeq;
	wire Iblez;
	wire Ioprt;
	wire Iload;
	wire Istore;

	assign Rtype   = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] & ~Opcode[2]) & (~Opcode[1] & ~Opcode[0]);//6'b000000
	assign REGIMM  = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] & ~Opcode[2]) & (~Opcode[1] & Opcode[0]);//6'b000001
	assign Jtype   = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] & ~Opcode[2]) &   Opcode[1];//5'b000001
	assign Ibeq	   = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] &  Opcode[2]) &  ~Opcode[1];//5'b00010
	assign Iblez   = (~Opcode[5] & ~Opcode[4]) & (~Opcode[3] &  Opcode[2]) &   Opcode[1];//5'b00011
	assign Ioprt   = (~Opcode[5] & ~Opcode[4]) &   Opcode[3];//3'b001
	assign Iload   = ( Opcode[5] & ~Opcode[4]) &  ~Opcode[3];//3'b100
	assign Istore  = ( Opcode[5] & ~Opcode[4]) &   Opcode[3];//3'b101

	//special
	wire op_shift;
	wire op_jump;
	wire op_mov;
	wire jumpal;
	wire jr;
	wire jal;
	wire bltz;
	wire bgez;
	wire beq;
	wire bne;
	wire blez;
	wire bgtz;
	assign op_shift = Rtype & Func[5:3]==3'b000;
	assign op_jump = Rtype & {Func[5:3], Func[1]} == 4'b0010;
	assign op_mov = Rtype & {Func[5:3],Func[1]==4'b0011};
	assign jumpal = (op_jump & Func[0]) | (Jtype & Opcode[0]);
	assign jr = op_jump & ~Func[0];
	assign jal = Jtype & Opcode[0];
	assign bltz = REGIMM & ~rt[0];
	assign bgez = REGIMM & rt[0];
	assign beq = Ibeq & ~Opcode[0];
	assign bne = Ibeq & Opcode[0];
	assign blez = Iblez & ~Opcode[0];
	assign bgtz = Iblez & Opcode[0];

	/*
	control unit
	*/
	wire RegDst;
	wire Jump;
	wire Branch;
	wire Mem2Reg;
	wire ALUsrc;
	wire RegWrite;
	wire ALUop0;
	wire ALUop1;
	wire PCsrc;

	assign RegDst = Rtype;
	assign Jump = Jtype | op_jump;
	assign ALUsrc = Iload | Istore | Ioprt;
	assign Mem2Reg = Iload;
	assign RegWrite = Rtype | Iload | Ioprt | jal;
	assign MemRead = Opcode[5] & (~Opcode[3]);
	assign MemWrite = Opcode[5] & Opcode[3];
	assign Branch = Ibeq | Iblez | REGIMM;
	assign ALUop1 = Rtype | Ioprt | Iblez | REGIMM;
	assign ALUop0 = Ibeq | Iblez | REGIMM ;
	
	wire mov_judge;//if 1 rf_wen=0
	wire branch_judge;

	assign branch_judge = (zero & (bgez | beq | blez)) | (~zero & (bltz | bne | bgtz));
	assign PCsrc = Branch & branch_judge;
	assign mov_judge = op_mov & (Func[0] ^ raddr2==0);

	/*
	data path
	*/
	assign raddr1 = rs;
	assign raddr2 = REGIMM? 0:rt;
	assign RF_wen = (jr | mov_judge)? 0:RegWrite;
	assign RF_waddr = jal? 6'd31 :RegDst? rd:rt;
	assign RF_wdata = Mem2Reg? Read_data: (jumpal? PC+8: (op_shift? Shift_result : ALU_result));//todo
	assign Address  = {ALU_result[31:2], 2'b00};

	/*
	sign extension
	*/
	wire [31:0]sign_ext;
	wire [31:0]zero_ext;
	wire [31:0]shift_ext;
	wire [31:0]imm_data;
	assign sign_ext  = {{16{Instruction[15]}}, Instruction[15:0]};
	assign zero_ext  = { 16'b0               , Instruction[15:0]};
	assign shift_ext = { sign_ext[29:0]      , 2'b00};

	assign imm_data =   Opcode[2] == 1'b1                       ? zero_ext
                    :  (Opcode[2] == 1'b0 || Opcode[5] == 1'b1) ? sign_ext
					:   shift_ext;

	/*
	alu control
	*/
	wire [3:0]func_m;
	wire [3:0]opcode_modified;
	assign opcode_modified = (Opcode[2:1]==2'b01)? Opcode[3:0] : {1'b0,Opcode[2:0]};
	assign func_m = ({4{Rtype}} & Instruction [3:0]) | ({4{Ioprt}} & opcode_modified);
	assign op2 = (~func_m[3]&func_m[1]) | (func_m[1]&~func_m[0]);
	assign op1 = ~func_m[2];
	assign op0 = (func_m[2]&func_m[0]) | func_m[3];
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
	assign Shift_B = Func[2]? {27'b0,sa} : rdata1;

	/*
	pc
	*/
	wire [31:0] PC_next;
	wire [31:0] PC_plus4;
	wire [31:0] PC_result;
	wire [31:0] Jump_addr;
	assign PC_plus4 = PC + 4;
	assign PC_add = PC_plus4 + shift_ext;
	assign Jump_addr = {PC_plus4[31:28],Instruction[25:0] << 2,2'b00};
	assign PC_result = PCsrc? PC_add : PC_plus4;
	assign PC_next = Jump? (op_jump? rdata1:Jump_addr) : PC_result;

	always @(posedge clk) begin
		if(rst) PC<=32'd0;
		else PC <= PC_next;
	end

endmodule

