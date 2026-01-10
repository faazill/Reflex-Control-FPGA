import random

def generate_hex_file():
    filename = "../tb/synthetic_trace.hex"
    with open(filename, "w") as f:
        print(f"Generating {filename}...")
        
        # 1. NORMAL PHASE (0-100 lines) - Perfectly centered
        # Center = 320. Object at 320.
        for i in range(100):
            # Format: Valid=1, EndOfLine=0/1, Pixel=255, X=320
            # We simulate a "Scanline" of 10 pixels for simplicity
            for x in range(315, 325): 
                # Write simple valid pixels centered at 320
                # We will simplify the testbench to read 1 line = 1 transaction for ease
                pass 
            
            # actually, let's just write CONTROL SIGNALS for the testbench
            # Format: drift_val (simulated output from monitor)
            # We skip simulating the pixels and inject into the Spike Encoder directly
            # to verify the "Brain" first.
            pass

# Wait! The best way to verify the WHOLE system (Monitor + Brain) 
# is to feed pixel streams. But that makes the file huge.
# Let's verify the TOP LEVEL by injecting raw pixels.