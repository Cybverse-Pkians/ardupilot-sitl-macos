#!/usr/bin/env bash
# Shared environment for ArduPilot SITL and Gazebo Jetty on macOS.

if [ -n "${ZSH_VERSION:-}" ]; then
  AP_ENV_SOURCE="${(%):-%x}"
elif [ -n "${BASH_SOURCE[0]:-}" ]; then
  AP_ENV_SOURCE="${BASH_SOURCE[0]}"
else
  AP_ENV_SOURCE="$0"
fi

if [[ "${AP_ENV_SOURCE}" == "$0" && -z "${ZSH_VERSION:-}" ]]; then
  echo "Source this file instead: source scripts/env.sh" >&2
  exit 1
fi

AP_SITL_ROOT="$(cd -- "$(dirname -- "${AP_ENV_SOURCE}")/.." && pwd)"
export AP_SITL_ROOT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This environment is intended for macOS." >&2
  return 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required; install it from https://brew.sh/." >&2
  return 1
fi

AP_HOMEBREW_PREFIX="$(brew --prefix)"
export PATH="${AP_SITL_ROOT}/.venv/bin:${AP_HOMEBREW_PREFIX}/bin:${PATH}"
export CMAKE_PREFIX_PATH="${AP_HOMEBREW_PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export PKG_CONFIG_PATH="${AP_HOMEBREW_PREFIX}/lib/pkgconfig${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"

# Homebrew currently ships the Jetty generation of Gazebo as gz-sim10.
export GZ_VERSION=jetty
export GZ_SIM_SYSTEM_PLUGIN_PATH="${AP_SITL_ROOT}/ardupilot_gazebo/build-ninja${GZ_SIM_SYSTEM_PLUGIN_PATH:+:${GZ_SIM_SYSTEM_PLUGIN_PATH}}"
export GZ_SIM_RESOURCE_PATH="${AP_SITL_ROOT}/ardupilot_gazebo/models:${AP_SITL_ROOT}/ardupilot_gazebo/worlds${GZ_SIM_RESOURCE_PATH:+:${GZ_SIM_RESOURCE_PATH}}"
