module test;

parameter CONST = 8'h55;
initial
begin
    if ( 8'h55 == CONST ) $display("8'h55 == CONST");
    if ( 4'h5 == CONST[7:4]) $display("4'h5 == CONST[7:4]");
    if ( 8'h6 == CONST[7:4]) $display("you are full of shit");
end
endmodule