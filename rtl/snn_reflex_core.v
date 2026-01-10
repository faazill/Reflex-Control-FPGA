module snn_reflex_core (
    input clk,
    input rst,
    
    // Spikes from Encoder
    input spike_drift,
    input spike_spread,
    input spike_shock,

    // Synaptic Weights
    input [15:0] w_drift,  
    input [15:0] w_spread, 
    input [15:0] w_shock,  
    
    // Neuron Properties
    input [15:0] leak_rate,
    input [15:0] threshold,

    // The Output
    output reg reflex_active,
    output reg [15:0] v_mem
);

    // Internal Potential Accumulator
    reg signed [19:0] potential;

    // --- FIX: Calculate Input Current here (Combinational Logic) ---
    // We sum up the weights of any active spikes using a wire
    wire signed [19:0] input_current;
    assign input_current = (spike_drift  ? w_drift  : 16'd0) + 
                           (spike_spread ? w_spread : 16'd0) + 
                           (spike_shock  ? w_shock  : 16'd0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            potential <= 0;
            reflex_active <= 0;
            v_mem <= 0;
        end else begin
            
            // 1. Check for Firing (Immediate Reflex)
            if (potential >= threshold) begin
                reflex_active <= 1;      // Fire!
                potential <= 0;          // Reset
            end else begin
                reflex_active <= 0;
                
                // 2. Leaky Integration Logic
                // New Potential = Old + Input - Leak
                if (potential + input_current > leak_rate) begin
                    potential <= potential + input_current - leak_rate;
                end else begin
                    potential <= 0;      // Floor at 0
                end
            end
            
            // Debug Output
            v_mem <= potential[15:0];
        end
    end

endmodule