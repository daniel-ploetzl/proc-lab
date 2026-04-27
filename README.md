# proc-lab --- Linux Process Behaviour and Ephemeral Execution Lab

## Overview

This project implements a Linux process lifecycle and behaviour
simulation lab using Bash. It explores transient execution, process
isolation and controlled runtime behaviour for research and educational
analysis of:

-   process lifecycle management in user space
-   ephemeral execution from volatile memory
-   behaviour patterns of short-lived rotating processes

------------------------------------------------------------------------

## Architecture

### Runtime script

-   `god-ram.sh` Main execution engine:
    -   migrates itself into `/dev/shm`
    -   detaches using `nohup` and `setsid`
    -   manages lifecycle and rotation of payload processes

### Monitoring utility

-   `monitor-god-ram.sh` Observer component:
    -   tracks active migrated instances
    -   counts running payload processes
    -   logs lifecycle events to shared memory

------------------------------------------------------------------------

## Execution Model

The system follows a **self-migrating, detached execution model**:

-   initial process copies itself into `/dev/shm/.sysXXXXXXXX`
-   execution continues from the migrated instance
-   original process exits immediately
-   runtime is bounded by a time window with jitter

### Constraint model

-   no persistent disk usage after initial launch
-   execution isolated to process groups
-   cleanup limited strictly to artefacts created by the script

------------------------------------------------------------------------

## Behaviour Model

Payload execution is implemented as a rotating process pattern:

-   payload copied to temporary paths (`/dev/shm/ex0N`)
-   short overlap windows between successive executions
-   bounded random runtime per payload instance
-   controlled termination of previous process group

### Timing model

-   base runtime derived from user input (hours)
-   additional jitter applied to avoid deterministic behaviour
-   per-iteration randomness using Bash `$RANDOM`

------------------------------------------------------------------------

## Process Isolation

Each payload is executed in its own process group:

-   launched via `setsid`
-   terminated using negative PID targeting (process group scope)
-   prevents interference with unrelated system processes

### Cleanup guarantees

-   only tracked payload paths are removed
-   stable payload copy is deleted at termination
-   migrated script instance removes itself

------------------------------------------------------------------------

## Monitoring Model

The monitoring script provides visibility into runtime behaviour:

-   detects active migrated instances via pattern matching
-   logs payload count every 30 seconds
-   records termination and residual processes

Log file:

``` bash
/dev/shm/.god-ram-monitor.log
```

------------------------------------------------------------------------

## Requirements

-   Linux with Bash
-   utilities: `setsid`, `nohup`, `pgrep`, `awk`, `realpath`
-   payload file at:

``` bash
/dev/shm/home_work/payload.bin
```

------------------------------------------------------------------------

## Usage

### Runtime

``` bash
chmod +x god-ram.sh
./god-ram.sh            # default 6 hours
./god-ram.sh 1.5        # custom runtime
```

### Monitoring

``` bash
chmod +x monitor-god-ram.sh
./monitor-god-ram.sh
```

------------------------------------------------------------------------

## Design Notes

-   `/dev/shm` is used as a volatile execution environment
-   process rotation introduces non-deterministic lifecycle patterns
-   behaviour remains bounded and observable via monitoring script

------------------------------------------------------------------------

## Disclaimer

This project is intended for controlled lab environments focusing on
Linux process behaviour, lifecycle analysis and transient execution
patterns.
