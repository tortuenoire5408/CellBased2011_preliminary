module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output IROM_EN;
output [5:0] IROM_A;
output IRB_RW;
output [7:0] IRB_D;
output [5:0] IRB_A;
output busy;
output done;

`define tb1 tb1
// `define tb2 tb2
//---------------------------------------------------------------------------
reg IROM_EN;
reg [5:0] IROM_A;
reg IRB_RW;
reg [7:0] IRB_D;
reg [5:0] IRB_A;
reg busy;
reg done;

reg [3:0] x, y;
reg [3:0] state;
reg [7:0] i, last_IROMQ, num0, num1, num2, num3;
reg [7:0] mem [63:0];

parameter read_IROM = 2'b00, cmd_input = 2'b01, write_IRB = 2'b10;
parameter Write = 3'b000, Shift_Up = 3'b001, Shift_Down = 3'b010, Shift_Left = 3'b011,
          Shift_Right = 3'b100, Average = 3'b101, Mirror_X = 3'b110, Mirror_Y = 3'b111;
//---------------------------------------------------------------------------
always@(posedge clk or posedge reset) begin
    if(reset) begin
        IROM_EN = 1; IRB_RW = 1; busy = 1; done = 0;
        state = read_IROM; i = 0; x = 4; y = 4;
    end else begin
        case (state)
            read_IROM: begin
                if(i == 0) begin
                    IROM_A = i;
                    IROM_EN = 0;
                    i = i + 1;
                    state = read_IROM;
                end else begin
                    if(IROM_Q !== last_IROMQ) begin
                        last_IROMQ = IROM_Q;
                        mem[i - 1] = IROM_Q;
                        if(i == 64) begin
                            IROM_EN = 1;
                            busy = 0;
                            state = cmd_input;
                        end else begin
                            IROM_A = i;
                            IROM_EN = 0;
                            i = i + 1;
                            state = read_IROM;
                        end
                    end else begin
                        state = read_IROM;
                    end
                end
            end
            cmd_input: begin
                if(cmd_valid) begin
                    busy = 1;
                    case(cmd)
                        Write: begin
                            i = 0;
                            IRB_RW = 0;
                            state = write_IRB;
                        end
                        Shift_Up: begin
                            y = (y == 1) ? 1 : (y - 1);
                            state = cmd_input;
                        end
                        Shift_Down: begin
                            y = (y == 7) ? 7 : (y + 1);
                            state = cmd_input;
                        end
                        Shift_Left: begin
                            x = (x == 1) ? 1 : (x - 1);
                            state = cmd_input;
                        end
                        Shift_Right: begin
                            x = (x == 7) ? 7 : (x + 1);
                            state = cmd_input;
                        end
                        Average: begin
                            num0 = mem[((y - 1) * 8) + (x - 1)];
                            num1 = mem[((y - 1) * 8) + (x)];
                            num2 = mem[(y * 8) + (x - 1)];
                            num3 = mem[(y * 8) + (x)];

                            mem[((y - 1) * 8) + (x - 1)] = (num0 + num1 + num2 + num3) / 4;
                            mem[((y - 1) * 8) + (x)] = (num0 + num1 + num2 + num3) / 4;
                            mem[(y * 8) + (x - 1)] = (num0 + num1 + num2 + num3) / 4;
                            mem[(y * 8) + (x)] = (num0 + num1 + num2 + num3) / 4;
                        end
                        Mirror_X: begin
                            num0 = mem[((y - 1) * 8) + (x - 1)];
                            num1 = mem[((y - 1) * 8) + (x)];
                            num2 = mem[(y * 8) + (x - 1)];
                            num3 = mem[(y * 8) + (x)];

                            mem[((y - 1) * 8) + (x - 1)] = num2;
                            mem[((y - 1) * 8) + (x)] = num3;
                            mem[(y * 8) + (x - 1)] = num0;
                            mem[(y * 8) + (x)] = num1;
                        end
                        Mirror_Y: begin
                            num0 = mem[((y - 1) * 8) + (x - 1)];
                            num1 = mem[((y - 1) * 8) + (x)];
                            num2 = mem[(y * 8) + (x - 1)];
                            num3 = mem[(y * 8) + (x)];

                            mem[((y - 1) * 8) + (x - 1)] = num1;
                            mem[((y - 1) * 8) + (x)] = num0;
                            mem[(y * 8) + (x - 1)] = num3;
                            mem[(y * 8) + (x)] = num2;
                        end
                    endcase
                end else begin
                    busy = 0;
                end
            end
            write_IRB: begin
                if(i == 65) begin
                    IRB_RW = 1;
                    busy = 0;
                    done = 1;
                end else begin
                    IRB_A = i;
                    IRB_D = mem[i];
                    i = i + 1;
                    busy = 1;
                    state = write_IRB;
                end
            end
        endcase
    end
end
//---------------------------------------------------------------------------
endmodule

