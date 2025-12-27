`timescale 1ns/1ps

//זה בשביל לקמפל
// iverilog -o gal_first_sim -s tb src/test.v tb/test_tb.v
//יעני תשמור לי את מה שקימפלת לתוך גל פירסט סים
// iverilog -o gal_first_sim   
// איזה מודל- איזה טסט אני מריץ מתוך הTEST BENCH
// -s tb
// איזה קבצים של דיזיין src   אנחנו לוקחים לטסט הזה
// src/test.v

// איזה קבצים של וריפיקציה tb אנחנו לוקחים לטסט הזה
// tb/test_tb.v



////--------------
// להריץ את הטסט שנמצא בתיקיה SIM ולטסט קוראים גל פירס סים
//vvp sim/gal_first_sim


//לפתוח את הגלים שקיבלת מהסימולציה
//gtkwave and3.vcd


//לא למחוק - ככה מריצים כותבים אותן אחת אחרי השניה בטרמינל
//iverilog -o sim/gal_first_sim -s tb src/test.v tb/test_tb.v  
//vvp sim/gal_first_sim
//gtkwave wave.vcd

module tb;

    reg a, b, c;
    wire y;

    and3 dut (
        .a(a),
        .b(b),
        .c(c),
        .y(y)
    );

    initial begin
        $dumpfile("and3.vcd");
        $dumpvars(0, tb);

        $display(" time | a b c | y ");
        $display("--------------------");

        a = 0; b = 0; c = 0; #10;
        $display("%4t | %b %b %b | %b", $time, a, b, c, y);

        a = 1; b = 0; c = 1; #10;
        $display("%4t | %b %b %b | %b", $time, a, b, c, y);

        a = 1; b = 1; c = 0; #10;
        $display("%4t | %b %b %b | %b", $time, a, b, c, y);

        a = 1; b = 1; c = 1; #10;
        $display("%4t | %b %b %b | %b", $time, a, b, c, y);

        $finish;
    end

endmodule
