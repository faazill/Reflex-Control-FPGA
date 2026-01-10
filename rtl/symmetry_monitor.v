module symmetry_monitor (
    input clk,
    input rst,
    
    // Streaming Interface
    input valid_pixel,        // High when pixel data is valid
    input end_of_line,        // High for 1 tick at end of a row (sync)
    input [7:0] pixel_val,    // Intensity/Depth (I)
    input [9:0] x_coord,      // Current X position
    input [9:0] center_x,     // Target Center (Set-point)

    // Control-Relevant Outputs (The "Reflex Trigger" signals)
    output reg signed [23:0] drift_metric,     // First Moment Imbalance
    output reg signed [31:0] spread_metric,    // Second Moment Imbalance
    output reg signed [23:0] sudden_change     // Temporal Derivative
);

    // --- Internal Accumulators ---
    // m1: First Moment (Mass Balance)
    // m2: Second Moment (Variance/Spread)
    reg signed [23:0] acc_m1; 
    reg signed [31:0] acc_m2;
    
    // History for Derivative Calculation
    reg signed [23:0] prev_m1_final;

    // --- Combinational Math (DSP Slices) ---
    // Calculate distance from center (signed)
    wire signed [10:0] dist; 
    assign dist = $signed({1'b0, x_coord}) - $signed({1'b0, center_x});

    // Moment Terms
    wire signed [19:0] term_1; // Pixel * Dist
    wire signed [29:0] term_2; // Pixel * Dist^2

    // Q: Why separate terms? 
    // A: To optimize timing, synthesis can map these to DSP48 blocks.
    assign term_1 = $signed({1'b0, pixel_val}) * dist;
    assign term_2 = term_1 * dist; // Efficiently reuse term_1 mult

    // --- Main Logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc_m1 <= 0;
            acc_m2 <= 0;
            prev_m1_final <= 0;
            drift_metric <= 0;
            spread_metric <= 0;
            sudden_change <= 0;
        end else begin
            
            // 1. Accumulate Line Data (Streaming)
            if (valid_pixel) begin
                acc_m1 <= acc_m1 + term_1;
                
                // For m2 (Spread), we want imbalance. 
                // A perfectly symmetric object has equal spread on L and R.
                // So we actually want to know if the Spread is ASYMMETRIC?
                // Or just total spread change? 
                // Standard Reflex: Track total spread (deformation) or L-vs-R spread.
                // Here, we track L-vs-R spread difference by keeping the sign of 'dist'.
                // If dist is negative (Left), term_2 becomes negative? 
                // Wait: term_2 = term_1 * dist. 
                // Left: (Neg * Neg) * Neg = Neg? No.
                // Left: (Pix * -d) * -d = Pix * d^2. Always Positive.
                // To detect Spread IMBALANCE, we need to manually apply sign.
                // If Left, subtract. If Right, add.
                if (dist < 0) 
                    acc_m2 <= acc_m2 - $signed({1'b0, pixel_val}) * (dist * dist);
                else
                    acc_m2 <= acc_m2 + $signed({1'b0, pixel_val}) * (dist * dist);
            end

            // 2. End of Line Processing (Reflex Update)
            if (end_of_line) begin
                // Update Outputs
                drift_metric  <= acc_m1;
                spread_metric <= acc_m2;
                
                // Calculate Derivative (Jerk)
                // How much did the Drift change since the last line/frame?
                // This catches sudden slips.
                sudden_change <= acc_m1 - prev_m1_final;
                
                // Store history
                prev_m1_final <= acc_m1;
                
                // Reset Accumulators for next line
                acc_m1 <= 0;
                acc_m2 <= 0;
            end
        end
    end

endmodule