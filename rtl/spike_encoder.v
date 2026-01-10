module spike_encoder (
    input clk,
    input rst,
    input line_sync,            // Update only when new metrics arrive (end of line)
    
    // Inputs from Symmetry Monitor
    input signed [23:0] drift_in,
    input signed [31:0] spread_in,
    input signed [23:0] change_in,

    // Configuration (Sensitivity)
    // Lower threshold = More sensitive (Fires faster)
    input [23:0] drift_thresh, 
    input [31:0] spread_thresh,
    input [23:0] change_thresh,

    // Spike Outputs to SNN
    output reg spike_drift,
    output reg spike_spread,
    output reg spike_shock      // The "Jerk" spike
);

    // Internal Accumulators (The "Potentials")
    reg [24:0] acc_drift;
    reg [32:0] acc_spread;
    reg [24:0] acc_change;

    // Helper: Absolute Value Function
    function [31:0] abs_val;
        input signed [31:0] val;
        begin
            abs_val = (val < 0) ? -val : val;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc_drift <= 0;
            acc_spread <= 0;
            acc_change <= 0;
            spike_drift <= 0;
            spike_spread <= 0;
            spike_shock <= 0;
        end else begin
            // Default: Spikes are single-cycle pulses
            spike_drift <= 0;
            spike_spread <= 0;
            spike_shock <= 0;

            if (line_sync) begin
                // 1. Encode Drift (First Moment)
                // Add absolute error to the accumulator
                // Logic: Error acts like "Current" charging a capacitor
                if (acc_drift >= drift_thresh) begin
                    spike_drift <= 1;
                    acc_drift <= abs_val(drift_in); // Reset with residual? Or zero? 
                                                    // "Standard" is subtract thresh, 
                                                    // but Reset is safer for Reflexes (prevents runaways)
                end else begin
                    acc_drift <= acc_drift + abs_val(drift_in);
                end

                // 2. Encode Spread (Second Moment)
                if (acc_spread >= spread_thresh) begin
                    spike_spread <= 1;
                    acc_spread <= abs_val(spread_in);
                end else begin
                    acc_spread <= acc_spread + abs_val(spread_in);
                end

                // 3. Encode Shock (Derivative)
                // This is critical. Sudden changes should fire IMMEDIATELY.
                // We give it a "Boost" multiplier if it's very high.
                if (acc_change >= change_thresh) begin
                    spike_shock <= 1;
                    acc_change <= abs_val(change_in);
                end else begin
                    acc_change <= acc_change + abs_val(change_in);
                end
            end
        end
    end

endmodule