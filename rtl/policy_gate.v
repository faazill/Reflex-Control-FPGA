module policy_gate (
    input clk,
    input rst,
    
    // Inputs
    input reflex_active,           // From SNN Core (The Veto)
    input signed [15:0] policy_torque, // From Python/AI (The Request)
    
    // Configuration
    input signed [15:0] safe_torque,   // e.g., 0 for Stop, or Hold value
    input [15:0] lock_duration,        // How long to hold brake (in cycles)

    // Output to Motor
    output reg signed [15:0] final_command,
    output reg override_status         // For logging: "Did we veto?"
);

    reg [15:0] lock_counter;
    reg locked;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            final_command <= 0;
            override_status <= 0;
            lock_counter <= 0;
            locked <= 0;
        end else begin
            
            // 1. Lock Logic (Hysteresis)
            if (reflex_active) begin
                locked <= 1;
                lock_counter <= lock_duration; // Reset timer
            end else if (lock_counter > 0) begin
                locked <= 1;
                lock_counter <= lock_counter - 1;
            end else begin
                locked <= 0;
            end

            // 2. Gate Logic (The Veto)
            if (locked) begin
                final_command <= safe_torque; // OVERRIDE!
                override_status <= 1;
            end else begin
                final_command <= policy_torque; // Pass-through
                override_status <= 0;
            end
        end
    end

endmodule