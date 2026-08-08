# ArduPilot SITL + Gazebo Sim on macOS (Apple Silicon)

This repository provides a pre-configured environment to run ArduPilot SITL (Software In The Loop) integrated with Gazebo Sim (`gz-sim10` / Jetty) on macOS (Apple Silicon). 

It features portability fixes to work seamlessly with macOS Homebrew, custom shell setups (`zsh`/`bash`), and MAVLink stream control scripts.

---

## Prerequisites & Installation

### 1. Install Dependencies
You will need Homebrew installed. To install all required dependencies (Gazebo Sim, RapidJSON, GStreamer, Python 3.11, etc.), run:
```bash
cd ardupilot-sitl-macos
./scripts/build_macos.sh --install-deps
```

### 2. Build the Autopilot and Gazebo Plugins
Build the ArduPilot Copter binary and compile the C++ Gazebo-to-ArduPilot bridge plugins:
```bash
./scripts/build_macos.sh
```

---

## How to Run the Simulation

To launch the full 3D interactive simulation, you will need **three terminal windows/tabs**:

### Terminal 1: Start Gazebo Sim (GUI)
Navigate to the project folder, source the environment variables, and launch the 3D simulator:
```bash
cd ardupilot-sitl-macos
source scripts/env.sh
scripts/launch_iris.sh
```
*This opens the Gazebo window showing the Runway world and the drone.*

### Terminal 2: Start ArduPilot SITL
In a second terminal, navigate to the folder, source the environment, and start the autopilot:
```bash
cd ardupilot-sitl-macos
source scripts/env.sh
build/sitl/bin/arducopter -w --model JSON --speedup 1 --defaults Tools/autotest/default_params/copter.parm --serial0 udpclient:127.0.0.1:14550 --sim-address=127.0.0.1
```
*This loads the drone's flight controller, boots the EKF/GPS alignment, and connects to Gazebo.*

### Terminal 3: Send Flight Commands (MAVProxy)
In a third terminal, source the environment and run MAVProxy to control the drone:
```bash
cd ardupilot-sitl-macos
source scripts/env.sh
mavproxy.py --master=udpin:127.0.0.1:14550 --console --map
```
Once MAVProxy connects, enter the following commands to command a takeoff:
```text
mode guided
arm throttle
takeoff 5
```
*The drone will arm its motors, take off, and hover at 5 meters in the Gazebo 3D simulation.*

---

## Running Automated Headless Test
To run a headless guided-takeoff smoke test (useful for continuous integration or validation without the GUI), run:
```bash
cd ardupilot-sitl-macos
./scripts/test_iris_flight.sh
```
This automated script launches Gazebo headlessly, boots the SITL, connects via MAVLink, commands arming/takeoff, verifies altitude rise, and prints the result.
