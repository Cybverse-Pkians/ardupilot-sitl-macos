# macOS ArduPilot SITL + Gazebo

This checkout is configured for Apple Silicon, Homebrew, and Gazebo Jetty
(`gz-sim10`). It keeps the Python packages in `.venv` and does not modify
shell startup files.

From this directory:

```bash
scripts/build_macos.sh --install-deps  # only needed on a new Mac
scripts/build_macos.sh                 # build SITL and the Gazebo plugins
scripts/test_iris_flight.sh            # headless guided-takeoff smoke test
```

The automated test starts Gazebo and ArduCopter, waits for MAVLink, changes to
GUIDED mode, arms, commands a 3 m takeoff, and passes only after it observes
the simulated altitude rise. Logs are retained in a `.iris-flight-test.*`
folder when the command finishes.

For an interactive 3D Gazebo session, open one terminal with:

```bash
scripts/launch_iris.sh
```

Then use a second terminal to run SITL (or simply run the automated test).
The local `ardupilot_gazebo` copy includes two portability fixes: Jetty is
persisted as a CMake cache option across builds, and the GStreamer header paths
are expanded correctly by CMake 4 on macOS. The Iris model also uses
non-lock-step JSON transport because strict lock-step stalls the Homebrew Jetty
server during its initial UDP handshake on this system.
