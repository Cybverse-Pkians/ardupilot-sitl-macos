#!/usr/bin/env bash
# Start the interactive Gazebo Iris world. Run scripts/test_iris_flight.sh for
# the automated headless flight check instead.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

if [[ ! -f "${AP_SITL_ROOT}/ardupilot_gazebo/build-ninja/libArduPilotPlugin.dylib" ]]; then
  echo "Gazebo plugin is not built. Run scripts/build_macos.sh first." >&2
  exit 1
fi

exec gz sim -r "${AP_SITL_ROOT}/ardupilot_gazebo/worlds/iris_runway.sdf"
