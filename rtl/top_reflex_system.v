module top_reflex_system (
    input clk,
    input rst,
    
    // 1. Sensor Input (From Event Camera/Camera)
    input valid_pixel,
    input end_of_line,
    input [7:0] pixel_val,
    input [9:0] x_coord,
    input [9:0] center_x, // Target center
    
    // 2. Policy Input (From Python AI)
    input signed [15:0] policy_torque,

    // 3. Tunable Parameters (Configuration)
    input [23:0] drift_thresh,
    input [31:0] spread_thresh,
    input [23:0] change_thresh,
    input [15:0] w_drift,
    input [15:0] w_spread,
    input [15:0] w_shock,
    input [15:0] snn_threshold,
    input [15:0] safe_torque,

    // 4. Output (To Motor)
    output signed [15:0] final_command,
    output reflex_active,      // Debug: Did SNN fire?
    output override_status     // Debug: Is Gate locking?
);

    // --- Interconnect Wires ---
    wire signed [23:0] drift_metric;
    wire signed [31:0] spread_metric;
    wire signed [23:0] sudden_change;

    wire spike_drift, spike_spread, spike_shock;
    wire snn_fire_signal;

    // --- Module A: Symmetry Monitor ---
    symmetry_monitor mon_inst (
        .clk(clk), .rst(rst),
        .valid_pixel(valid_pixel), .end_of_line(end_of_line),
        .pixel_val(pixel_val), .x_coord(x_coord), .center_x(center_x),
        .drift_metric(drift_metric),
        .spread_metric(spread_metric),
        .sudden_change(sudden_change)
    );

    // --- Module B: Spike Encoder ---
    spike_encoder enc_inst (
        .clk(clk), .rst(rst), .line_sync(end_of_line),
        .drift_in(drift_metric), .spread_in(spread_metric), .change_in(sudden_change),
        .drift_thresh(drift_thresh), .spread_thresh(spread_thresh), .change_thresh(change_thresh),
        .spike_drift(spike_drift), .spike_spread(spike_spread), .spike_shock(spike_shock)
    );

    // --- Module C: SNN Reflex Core ---
    snn_reflex_core snn_inst (
        .clk(clk), .rst(rst),
        .spike_drift(spike_drift), .spike_spread(spike_spread), .spike_shock(spike_shock),
        .w_drift(w_drift), .w_spread(w_spread), .w_shock(w_shock),
        .leak_rate(16'd5),          // Hardcoded or make input
        .threshold(snn_threshold),
        .reflex_active(snn_fire_signal),
        .v_mem()                    // Disconnected for now
    );

    // --- Module D: Policy Gate ---
    policy_gate gate_inst (
        .clk(clk), .rst(rst),
        .reflex_active(snn_fire_signal),
        .policy_torque(policy_torque),
        .safe_torque(safe_torque),
        .lock_duration(16'd100),    // Lock for 100 cycles
        .final_command(final_command),
        .override_status(override_status)
    );

    // Expose internal signal for debug
    assign reflex_active = snn_fire_signal;

endmodule