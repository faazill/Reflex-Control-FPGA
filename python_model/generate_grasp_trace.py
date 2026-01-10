import pybullet as p
import pybullet_data
import time
import numpy as np

def generate_grasp_trace():
    # 1. Setup World
    p.connect(p.DIRECT)  # Headless mode for speed
    p.setAdditionalSearchPath(pybullet_data.getDataPath())
    p.setGravity(0, 0, -9.8)
    
    # 2. Setup Scene
    p.loadURDF("plane.urdf")
    
    # The Object (Red Cube)
    box_start_pos = [0, 0, 0.5]
    boxId = p.loadURDF("cube.urdf", box_start_pos, globalScaling=0.1) # 10cm cube
    p.changeVisualShape(boxId, -1, rgbaColor=[1, 0, 0, 1])

    # The Gripper (Two kinematic blocks squeezing the cube)
    # Left Finger
    finger_L = p.loadURDF("cube.urdf", [-0.06, 0, 0.5], globalScaling=0.02, useFixedBase=True)
    # Right Finger
    finger_R = p.loadURDF("cube.urdf", [0.06, 0, 0.5], globalScaling=0.02, useFixedBase=True)

    # 3. Apply Initial Friction (High)
    p.changeDynamics(boxId, -1, lateralFriction=1.0)
    
    print(">>> SIMULATION START: Holding Object...")
    
    trace_data = []
    
    # 4. Simulation Loop (300 Steps)
    for t in range(300):
        
        # EXPERIMENT: Reduce Friction slowly to cause SLIP
        if t > 50:
            current_friction = max(0.01, 1.0 - (t - 50) * 0.005)
            p.changeDynamics(boxId, -1, lateralFriction=current_friction)
        
        p.stepSimulation()
        
        # 5. Virtual Camera Logic
        # We track the Z-height of the box.
        # As it slips DOWN, the visual feature moves in our "Scanline".
        pos, _ = p.getBasePositionAndOrientation(boxId)
        z_height = pos[2]
        
        # Initial Z is 0.5. If it drops to 0.49, that is a slip.
        # Map Z-Drop to Horizontal Pixel Shift (Simulating a camera viewing the edge)
        # Slip of 1mm = 10 pixels shift
        slip_dist = 0.5 - z_height
        
        # Center Pixel = 320. 
        # If box drops, edge appears to shift "Right" in the image (arbitrary mapping)
        pixel_center = 320 + (slip_dist * 5000) 
        
        # Clamp and integerize
        pixel_center = int(max(0, min(639, pixel_center)))
        
        # Format for Hex File: 3-digit hex (e.g., "140")
        trace_data.append(f"{pixel_center:03x}")
        
        # Stop if it falls too far
        if z_height < 0.2:
            print(">>> OBJECT DROPPED!")
            break

    # 5. Export Trace
    with open("../tb/grasp_trace.hex", "w") as f:
        for val in trace_data:
            f.write(val + "\n")
            
    print(f"Trace Generated: {len(trace_data)} frames captured.")
    p.disconnect()

if __name__ == "__main__":
    generate_grasp_trace() 