# pwscf

## Overview
- **Author:** Paolo Giannozzi
- **Version:** v6.1
- **Summary:** This is the main program for the executable "pw.x". It serves as a driver for the Plane Wave Self-Consistent Field (PWSCF) calculations.
- **Role:** The `pwscf` program (typically run as `pw.x`) orchestrates different modes of execution for PWSCF calculations:
    - **Standard `pw.x` mode:** Performs a standard self-consistent calculation or other specified calculations (e.g., 'scf', 'nscf', 'bands', 'relax', 'md'). This is the default mode if no special options are provided.
    - **Server mode (i-Pi):** If called as "pw.x -ipi server-address" or "pw.x --ipi server-address", it works in "server" mode, typically interacting with an i-Pi client for advanced molecular dynamics or path integral simulations. In this mode, it calls `run_driver`.
    - **`manypw.x` mode:** If the executable is named `manypw.x` (often via a symbolic link), it works in "manypw" mode. This mode is used for running multiple instances of pw.x, commonly for image-based calculations like those in Nudged Elastic Band (NEB) methods. It calls `run_manypw` and then `run_pwscf`.
    - **`dist.x` mode:** If the executable is named `dist.x` (via a symbolic link), it operates in a "dry run" mode. It computes distances, angles, and neighbor lists, writing this information to a file named "dist.out", and then stops. This mode is described in the introductory comments.

## Key Components

The `pwscf` program itself is the main driver. Its execution logic is primarily determined by command-line arguments and the name by which the executable is called.

- **Main Execution Blocks:**
    - **Server Mode (i-Pi):**
        - Activated by the `-ipi` or `--ipi` command-line option.
        - Retrieves a server address using `get_server_address`.
        - Reads input specific to 'PW+iPi'.
        - Calls `run_driver` to handle the client-server interaction and calculations.
    - **`manypw.x` Mode:**
        - Activated if the command line matches `'manypw.x'`.
        - Sets `use_images = .TRUE.`.
        - Calls `run_manypw()` to manage multiple PWSCF instances (images).
        - Subsequently calls `run_pwscf()` for the actual calculation logic, likely coordinated by `run_manypw`.
    - **Standard `pw.x` Execution:**
        - This is the default path if not in server mode or `manypw.x` mode.
        - If `nimage_ > 1` (from command line options, indicating image parallelization for standard pw.x), it's an error.
        - Calls `read_input_file` for standard 'PW' input.
        - Calls `run_pwscf` to perform the main PWSCF calculation.
    - **`dist.x` Mode:**
        - Described in comments as a mode for computing geometric properties. The provided source snippet does not explicitly show the `dist.x` logic block, but it's a known operational mode.

- **Key External Subroutine Calls:**
    - `mp_startup`: Initializes the parallel environment (MPI). Called at the beginning.
    - `laxlib_start`: Initializes LAXlib (Linear Algebra Xml LIBrary), setting up distributed diagonalization strategies based on `ndiag_` and `do_diag_in_band_group`.
    - `environment_start`: Sets up the PWSCF specific environment, possibly timing and resource management.
    - `read_input_file`: Reads the input file for the calculation. Called with different contexts ('PW', 'PW+iPi').
    - `run_pwscf`: Executes the main self-consistent field calculation or other specified run types.
    - `run_manypw`: Manages the execution of multiple PWSCF instances, typically for image-based calculations (e.g., NEB).
    - `run_driver`: Handles the i-Pi server mode, managing communication and calculations driven by an external client.
    - `laxlib_end`: Finalizes LAXlib operations.
    - `stop_run`: A routine to gracefully stop the program, possibly finalizing MPI and printing final messages. It receives an `exit_status`.
    - `do_stop`: Likely the final MPI stop call or system exit, using the `exit_status`.

## Important Variables/Constants
- `srvaddress` (CHARACTER(len=256)): Stores the server address when running in i-Pi server mode. Obtained via `get_server_address`.
- `exit_status` (INTEGER): Holds the exit status of the program. It's passed to `stop_run` and `do_stop`.
- `use_images` (LOGICAL): Set to `.TRUE.` if the program is run as `manypw.x`, indicating that multiple images (instances) are being managed.
- `do_diag_in_band_group` (LOGICAL): A logical flag (defaulting to `.TRUE.`) that controls the strategy for distributed diagonalization within LAXlib, affecting how diagonalization groups are set up relative to band groups or pools.
- `matches` (LOGICAL, EXTERNAL): An external function used to check if a substring (like 'manypw.x') is present in the command line string, determining the execution mode.

## Usage Examples
No explicit command-line usage examples are detailed within the source code comments of `pwscf.f90` itself, beyond the descriptions of how different modes (`-ipi`, `manypw.x`) are invoked. Standard usage involves `pw.x < input_file > output_file`.

## Dependencies and Interactions
- **Modules Used:**
    - `environment`: `ONLY : environment_start`
    - `mp_global`: `ONLY : mp_startup`
    - `mp_world`: `ONLY : world_comm`
    - `mp_pools`: `ONLY : intra_pool_comm`
    - `mp_bands`: `ONLY : intra_bgrp_comm, inter_bgrp_comm`
    - `mp_exx`: `ONLY : negrp`
    - `read_input`: `ONLY : read_input_file`
    - `command_line_options`: `ONLY : input_file_, command_line, ndiag_, nimage_`
- **Included Files:**
    - `laxlib.fh`: Contains definitions and interfaces for the LAXlib library.
- **Interactions:**
    - Interacts heavily with the MPI library for parallel execution across multiple processors/nodes.
    - Interacts with the file system for reading input files and writing output files, checkpoints, and other data.
    - Acts as the main driver program that calls various computational modules and libraries to perform PWSCF calculations.
    - Can interact with an i-Pi client over a network socket when running in server mode.
```
