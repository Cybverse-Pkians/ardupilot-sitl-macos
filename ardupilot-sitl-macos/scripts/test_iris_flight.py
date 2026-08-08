#!/usr/bin/env python3
"""MAVLink smoke test for the Gazebo Iris simulation."""

from __future__ import annotations

import argparse
import sys
import time

from pymavlink import mavutil


def wait_for_heartbeat(master: mavutil.mavfile, timeout: float) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        message = master.recv_match(type="HEARTBEAT", blocking=True, timeout=1)
        if message is not None:
            print(f"Heartbeat from system {master.target_system}, component {master.target_component}")
            return
    raise TimeoutError("No MAVLink heartbeat received from SITL")


def wait_for_position(master: mavutil.mavfile, timeout: float) -> None:
    """Wait until Gazebo FDM data has propagated through the autopilot."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        position = master.recv_match(type="GLOBAL_POSITION_INT", blocking=True, timeout=1)
        if position is not None:
            print(
                "Gazebo position stream ready: "
                f"relative altitude {position.relative_alt / 1000.0:.2f} m"
            )
            return
    raise TimeoutError("No simulated position received from the Gazebo bridge")


def wait_for_armed(master: mavutil.mavfile, timeout: float) -> None:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        master.mav.command_long_send(
            master.target_system,
            master.target_component,
            mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            0,
        )
        until = min(deadline, time.monotonic() + 3)
        while time.monotonic() < until:
            heartbeat = master.recv_match(type="HEARTBEAT", blocking=True, timeout=1)
            if heartbeat is not None and heartbeat.base_mode & mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED:
                print("Vehicle armed")
                return
    raise TimeoutError("Vehicle did not arm; inspect the SITL log for pre-arm failures")


def wait_for_takeoff(master: mavutil.mavfile, target_altitude_m: float, timeout: float) -> None:
    master.mav.command_long_send(
        master.target_system,
        master.target_component,
        mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        target_altitude_m,
    )

    threshold = target_altitude_m - 0.75
    deadline = time.monotonic() + timeout
    peak = 0.0
    while time.monotonic() < deadline:
        position = master.recv_match(type="GLOBAL_POSITION_INT", blocking=True, timeout=1)
        if position is None:
            continue
        altitude_m = position.relative_alt / 1000.0
        peak = max(peak, altitude_m)
        print(f"Relative altitude: {altitude_m:.2f} m")
        if altitude_m >= threshold:
            print(f"Flight check passed: reached {altitude_m:.2f} m (target {target_altitude_m:.2f} m)")
            return
    raise TimeoutError(f"Vehicle did not reach {threshold:.2f} m; peak altitude was {peak:.2f} m")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--connection", default="udpin:127.0.0.1:14550")
    parser.add_argument("--altitude", type=float, default=3.0)
    parser.add_argument("--heartbeat-timeout", type=float, default=60.0)
    parser.add_argument("--position-timeout", type=float, default=90.0)
    parser.add_argument("--arm-timeout", type=float, default=90.0)
    parser.add_argument("--takeoff-timeout", type=float, default=45.0)
    args = parser.parse_args()

    master = mavutil.mavlink_connection(args.connection, dialect="ardupilotmega")
    try:
        wait_for_heartbeat(master, args.heartbeat_timeout)
        print("Requesting MAVLink data streams...")
        master.mav.request_data_stream_send(
            master.target_system,
            master.target_component,
            mavutil.mavlink.MAV_DATA_STREAM_ALL,
            4,  # Hz
            1,  # start
        )
        master.mav.request_data_stream_send(
            master.target_system,
            master.target_component,
            mavutil.mavlink.MAV_DATA_STREAM_POSITION,
            10,  # Hz
            1,  # start
        )
        wait_for_position(master, args.position_timeout)
        # Let EKF and pre-arm checks receive several FDM frames after Gazebo
        # has loaded the model before sending the arm command.
        time.sleep(5)
        master.set_mode_apm("GUIDED")
        time.sleep(1)
        wait_for_armed(master, args.arm_timeout)
        wait_for_takeoff(master, args.altitude, args.takeoff_timeout)
    except (TimeoutError, ValueError) as error:
        print(f"Flight check failed: {error}", file=sys.stderr)
        return 1
    finally:
        master.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
