`timescale 1ns / 1ps

module tb_reflex_system;

    reg clk, rst;
    
    // Camera Inputs
    reg valid_pixel;
    reg end_of_line;
    reg [7:0] pixel_val;
    reg [9:0] x_coord;
    reg [9:0] center_x;
    
    // Policy Input
    reg signed [15:0] policy_torque;

    // Config Inputs
    reg [23:0] drift_thresh;
    reg [31:0] spread_thresh;
    reg [23:0] change_thresh;
    reg [15:0] w_drift, w_spread, w_shock;
    reg [15:0] snn_threshold;
    reg [15:0] safe_torque;

    // Outputs
    wire signed [15:0] final_command;
    wire reflex_active;
    wire override_status;

    // Instantiate Top Module
    top_reflex_system dut (
        .clk(clk), .rst(rst),
        .valid_pixel(valid_pixel), .end_of_line(end_of_line),
        .pixel_val(pixel_val), .x_coord(x_coord), .center_x(center_x),
        .policy_torque(policy_torque),
        .drift_thresh(drift_thresh), .spread_thresh(spread_thresh), .change_thresh(change_thresh),
        .w_drift(w_drift), .w_spread(w_spread), .w_shock(w_shock),
        .snn_threshold(snn_threshold), .safe_torque(safe_torque),
        .final_command(final_command),
        .reflex_active(reflex_active),
        .override_status(override_status)
    );

    // Clock
    always #5 clk = ~clk;

    // Helper task to simulate one "Pixel"
    task send_pixel;
        input [9:0] x;
        input [7:0] val;
        begin
            valid_pixel = 1;
            x_coord = x;
            pixel_val = val;
            #10; // 1 cycle
            valid_pixel = 0;
        end
    endtask

    // Helper task to simulate a whole line of an object
    // center_pos: where the object actually is
    task send_object_line;
        input [9:0] actual_center;
        integer i;
        begin
            // Send a block of pixels around the actual center
            // Simulate a 10-pixel wide object
            for (i = -5; i < 5; i = i + 1) begin
                send_pixel(actual_center + i, 8'd100); // Intensity 100
            end
            // End of line sync
            #10;
            end_of_line = 1;
            #10;
            end_of_line = 0;
            #10;
        end
    endtask

    initial begin
        $dumpfile("reflex_wave.vcd");
        $dumpvars(0, tb_reflex_system);

        // 1. Initialize
        clk = 0; rst = 1;
        valid_pixel = 0; end_of_line = 0; pixel_val = 0; x_coord = 0;
        center_x = 300; // Target is pixel 300
        
        // AI wants to move full speed
        policy_torque = 16'd1000; 
        safe_torque = 16'd0; // Stop if unsafe

        // Setup Thresholds (Tuning)
        drift_thresh = 24'd500;   // Sensitivity
        spread_thresh = 32'd1000;
        change_thresh = 24'd200;
        
        // SNN Weights
        w_drift = 16'd50;
        w_spread = 16'd10;
        w_shock = 16'd200; // Shock has high weight
        snn_threshold = 16'd150; // Fire when potential > 150

        #20 rst = 0;

        // 2. PHASE 1: NORMAL (Object is Centered at 300)
        // Send 5 lines. Drift should be ~0. SNN should be quiet.
        repeat(5) begin
            send_object_line(300); // Object is exactly where it should be
        end

        // 3. PHASE 2: SLIP START (Object shifts to 310)
        // This causes Drift error.
        repeat(5) begin
            send_object_line(310); 
        end

        // 4. PHASE 3: MAJOR SLIP (Object shifts to 350)
        // This causes HUGE Drift + Shock. SNN should FIRE here.
        repeat(5) begin
            send_object_line(350); 
        end

        #100;
        $finish;
    end

endmodule