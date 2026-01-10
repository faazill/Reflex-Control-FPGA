`timescale 1ns / 1ps

module tb_pybullet_replay;

    reg clk, rst;
    
    // Inputs to FPGA
    reg valid_pixel, end_of_line;
    reg [7:0] pixel_val;
    reg [9:0] x_coord, center_x;
    reg signed [15:0] policy_torque;
    
    // Outputs
    wire reflex_active;
    wire [15:0] final_command;
    wire override_status;

    // Config Parameters
    reg [23:0] drift_thresh;
    reg [31:0] spread_thresh;
    reg [23:0] change_thresh;
    reg [15:0] w_drift, w_spread, w_shock, snn_thresh, safe_torque;

    // Memory to store the PyBullet trace
    reg [11:0] trajectory_mem [0:199]; // 200 simulation steps
    integer step, i;
    reg [9:0] current_obj_center;

    // Instantiate Top Level
    top_reflex_system dut (
        .clk(clk), .rst(rst),
        .valid_pixel(valid_pixel), .end_of_line(end_of_line),
        .pixel_val(pixel_val), .x_coord(x_coord), .center_x(center_x),
        .policy_torque(policy_torque),
        .drift_thresh(drift_thresh), .spread_thresh(spread_thresh), .change_thresh(change_thresh),
        .w_drift(w_drift), .w_spread(w_spread), .w_shock(w_shock),
        .snn_threshold(snn_thresh), .safe_torque(safe_torque),
        .final_command(final_command),
        .reflex_active(reflex_active),
        .override_status(override_status)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pybullet_wave.vcd");
        $dumpvars(0, tb_pybullet_replay);

        // 1. Load the PyBullet Data
        // Make sure the path matches where Python saved it
        $readmemh("tb/grasp_trace.hex", trajectory_mem);

        // 2. Setup
        clk = 0; rst = 1;
        valid_pixel = 0; end_of_line = 0;
        center_x = 320; // The target center is pixel 320
        policy_torque = 16'd1000;
        
        // Tuning (High Sensitivity)
        drift_thresh = 24'd2000; spread_thresh = 32'd5000; change_thresh = 24'd1000;
        w_drift = 16'd50; w_spread = 16'd10; w_shock = 16'd200;
        snn_thresh = 16'd100; safe_torque = 16'd0;

        #20 rst = 0;

        // 3. Replay Loop
        // For each timestep in the PyBullet trace...
        for (step = 0; step < 200; step = step + 1) begin
            
            // Read where the object is from file
            current_obj_center = trajectory_mem[step];
            
            // Simulate a "Camera Scan" for this frame
            // We draw a 20-pixel wide object centered at 'current_obj_center'
            for (i = 0; i < 640; i = i + 1) begin
                x_coord = i;
                
                // If x is within +/- 10 pixels of the object center, it's bright
                if (x_coord >= (current_obj_center - 10) && x_coord <= (current_obj_center + 10))
                    pixel_val = 8'd255;
                else
                    pixel_val = 8'd0;
                
                // Send pixel to FPGA
                valid_pixel = 1;
                #10; // 1 clock cycle per pixel
            end
            
            valid_pixel = 0;
            end_of_line = 1; // Sync signal (Frame done)
            #10;
            end_of_line = 0;
            
            // Wait a bit between frames (simulating frame rate)
            #100;
        end
        
        $finish;
    end

endmodule