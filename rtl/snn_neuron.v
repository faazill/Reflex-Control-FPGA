module snn_neuron (
    input clk,
    input rst,
    input spike_in,           // Input from Spike Encoder
    input [7:0] weight,       // Synaptic weight
    input [7:0] leak_rate,    // How fast it forgets
    input [15:0] threshold,   // When to fire
    
    output reg fire_out       // The Reflex Signal
);

    reg signed [15:0] v_mem;  // Membrane Potential

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_mem <= 0;
            fire_out <= 0;
        end else begin
            // 1. Fire & Reset Logic
            if (v_mem >= threshold) begin
                fire_out <= 1;
                v_mem <= 0; // Reset after firing
            end else begin
                fire_out <= 0;
                
                // 2. Integration & Leak Logic
                // If spike comes, add Weight. Always subtract Leak.
                if (spike_in)
                    v_mem <= v_mem + weight - leak_rate;
                else if (v_mem > leak_rate) // Prevent going negative
                    v_mem <= v_mem - leak_rate;
                else
                    v_mem <= 0;
            end
        end
    end
endmodule