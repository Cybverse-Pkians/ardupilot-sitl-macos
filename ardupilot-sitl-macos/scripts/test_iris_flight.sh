#!/usr/bin/env bash
# Launch Gazebo headlessly, run ArduCopter SITL, then verify a guided takeoff.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

SITL_BIN="${AP_SITL_ROOT}/build/sitl/bin/arducopter"
WORLD="${AP_SITL_ROOT}/ardupilot_gazebo/worlds/iris_runway.sdf"
if [[ ! -x "${SITL_BIN}" || ! -f "${AP_SITL_ROOT}/ardupilot_gazebo/build-ninja/libArduPilotPlugin.dylib" ]]; then
  echo "SITL or Gazebo plugin is not built. Run scripts/build_macos.sh first." >&2
  exit 1
fi

RUN_DIR="$(mktemp -d "${AP_SITL_ROOT}/.iris-flight-test.XXXXXX")"
GZ_PID=""
SITL_PID=""

cleanup() {
  [[ -n "${SITL_PID}" ]] && kill "${SITL_PID}" 2>/dev/null || true
  [[ -n "${GZ_PID}" ]] && kill "${GZ_PID}" 2>/dev/null || true
  [[ -n "${SITL_PID}" ]] && wait "${SITL_PID}" 2>/dev/null || true
  [[ -n "${GZ_PID}" ]] && wait "${GZ_PID}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

gz sim -s -r -v 3 "${WORLD}" >"${RUN_DIR}/gazebo.log" 2>&1 &
GZ_PID=$!

# Let Gazebo load the model and bind the JSON FDM socket before SITL starts.
sleep 3
(
  cd "${RUN_DIR}"
  exec "${SITL_BIN}" -w --model JSON --speedup 1 \
    --defaults "${AP_SITL_ROOT}/Tools/autotest/default_params/copter.parm" \
    --serial0 udpclient:127.0.0.1:14550 --sim-address=127.0.0.1
) >"${RUN_DIR}/sitl.log" 2>&1 &
SITL_PID=$!

if ! "${AP_SITL_ROOT}/.venv/bin/python" "${SCRIPT_DIR}/test_iris_flight.py"; then
  echo "Flight logs retained in ${RUN_DIR}" >&2
  tail -80 "${RUN_DIR}/gazebo.log" >&2 || true
  tail -80 "${RUN_DIR}/sitl.log" >&2 || true
  exit 1
fi

echo "Flight test passed. Logs retained in ${RUN_DIR}"
