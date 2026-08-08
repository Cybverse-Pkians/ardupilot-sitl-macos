#!/usr/bin/env bash
# Build the local ArduPilot SITL and Gazebo plugin checkout for Apple Silicon.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env.sh"

if [[ "${1:-}" == "--install-deps" ]]; then
  brew install cmake ninja rapidjson opencv gstreamer gz-sim python@3.11
fi

for required in clang clang++ cmake ninja gz; do
  if ! command -v "${required}" >/dev/null 2>&1; then
    echo "Missing ${required}. Run: $0 --install-deps" >&2
    exit 1
  fi
done

if [[ ! -x "${AP_SITL_ROOT}/.venv/bin/python" ]]; then
  if ! command -v python3.11 >/dev/null 2>&1; then
    echo "Python 3.11 is required. Run: $0 --install-deps" >&2
    exit 1
  fi
  python3.11 -m venv "${AP_SITL_ROOT}/.venv"
fi

"${AP_SITL_ROOT}/.venv/bin/python" -m pip install --upgrade pip setuptools wheel
"${AP_SITL_ROOT}/.venv/bin/python" -m pip install \
  'empy==3.3.4' pymavlink MAVProxy pexpect pyserial lxml geocoder

cmake -S "${AP_SITL_ROOT}/ardupilot_gazebo" \
  -B "${AP_SITL_ROOT}/ardupilot_gazebo/build-ninja" \
  -G Ninja \
  -DARDUPILOT_GZ_VERSION=jetty \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="${AP_HOMEBREW_PREFIX}"
cmake --build "${AP_SITL_ROOT}/ardupilot_gazebo/build-ninja" \
  --parallel "$(sysctl -n hw.ncpu)"

(
  cd "${AP_SITL_ROOT}"
  PATH="${AP_SITL_ROOT}/.venv/bin:${PATH}" CC=clang CXX=clang++ ./waf configure --board sitl
  PATH="${AP_SITL_ROOT}/.venv/bin:${PATH}" CC=clang CXX=clang++ ./waf copter
)
