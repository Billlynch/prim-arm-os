//------------------------------------------------------------------------------
//			Read MUX
//			Bill Lynch
//			Version: 0.1
//			10/05/2017 (BL)
//
// This is a simple MUx which if read is enabled outputs the selected fan's speed
//
// Last modified: 12/05/2017 (BL)
//
// Know bugs: none
//
//------------------------------------------------------------------------------

//Verilog HDL for "COMP22712", "read_fan_speed_mux" "functional"
module read_fan_speed_mux ( input [7:0] speed_fan0,       //The speed of fan0
                            input [7:0] speed_fan1,       //The speed of fan1
                            input [7:0] speed_fan2,       //The speed of fan2
                            input [7:0] speed_fan3,       //The speed of fan3
                            input [3:0] fan_selection,    //The fan selection
                            input read,                   //read en?
                            output reg [7:0] speed_out);  //the speed output

always @(*) begin     //whenever any input value changes
  if (read) begin     //if read is enabled
    case (fan_selection)    //select the fan 
      4'b0001: speed_out = speed_fan0;  //set the outspeed to correspond
      4'b0010: speed_out = speed_fan1;
      4'b0100: speed_out = speed_fan2;
      4'b1000: speed_out = speed_fan3;
      default: speed_out = 11111111;    //output FF to show fail
    endcase
  end else begin
    speed_out = 11111111;
  end
end

endmodule
