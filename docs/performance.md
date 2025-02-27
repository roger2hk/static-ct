# TesseraCT Storage Performance

TesseraCT is designed to scale to meet the needs of most currently envisioned workloads in a cost-effective manner.

The indicative figures below were measured using the [CT hammer tool](/internal/hammer/) as of [commit `2872ea2`](https://github.com/transparency-dev/static-ct/commit/2872ea2387b2d3077eb832112277eb19a7a907bd).

## Backends

### GCP

The table below shows some rough numbers of measured performance:

| Instance Type                    | Cloud Spanner | Write QPS |
| -------------------------------- | ------------- | --------- |
| e2-micro (2 vCPUs, 1 GB Memory)  | 100 PUs       | 70        |
| e2-medium (2 vCPUs, 4 GB Memory) | 100 PUs       | 400       |

#### Free Tier VM Instance + Cloud Spanner 100 PUs

- e2-micro (2 vCPUs, 1 GB Memory)

The write QPS is around 70. The bottleneck comes from the CPU usage which is always above 90%. Spanner CPU utilization is around 30%.

```
┌───────────────────────────────────────────────────────────────────────┐
│Read (8 workers): Current max: 0/s. Oversupply in last second: 0       │
│Write (128 workers): Current max: 128/s. Oversupply in last second: 45 │
│TreeSize: 679958 (Δ 62qps over 30s)                                    │
│Time-in-queue: 241ms/585ms/1983ms (min/avg/max)                        │
│Observed-time-to-integrate: 1314ms/4714ms/8963ms (min/avg/max)         │
└───────────────────────────────────────────────────────────────────────┘
```

```
top - 12:47:03 up 1 day,  1:38,  2 users,  load average: 0.15, 0.29, 0.17
Tasks:  96 total,   2 running,  94 sleeping,   0 stopped,   0 zombie
%Cpu(s): 24.0 us,  5.0 sy,  0.0 ni, 69.8 id,  0.0 wa,  0.0 hi,  1.2 si,  0.0 st 
MiB Mem :    970.0 total,    106.9 free,    813.9 used,    193.2 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.    156.1 avail Mem 
```

#### e2-medium VM Instance + Cloud Spanner 100 PUs

- e2-medium (2 vCPUs, 4 GB Memory)

The write QPS is around 400. The bottleneck comes from the VM CPU usage which is always above 90%. Spanner CPU utilization is around 70%.

```
┌──────────────────────────────────────────────────────────────────────┐
│Read (8 workers): Current max: 0/s. Oversupply in last second: 0      │
│Write (300 workers): Current max: 462/s. Oversupply in last second: 0 │
│TreeSize: 1164400 (Δ 425qps over 30s)                                 │
│Time-in-queue: 115ms/217ms/501ms (min/avg/max)                        │
│Observed-time-to-integrate: 1038ms/4368ms/9589ms (min/avg/max)        │
└──────────────────────────────────────────────────────────────────────┘
```

```
top - 15:53:40 up 1 day,  4:45,  2 users,  load average: 1.09, 0.93, 0.47
Tasks:  97 total,   1 running,  96 sleeping,   0 stopped,   0 zombie
%Cpu(s): 32.5 us,  8.1 sy,  0.0 ni, 56.7 id,  0.0 wa,  0.0 hi,  2.5 si,  0.2 st 
MiB Mem :   3924.7 total,   2120.2 free,   1029.5 used,   1021.8 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   2895.3 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND                                                                                                               
 105693 user+     20   0 1596352 290768  31020 S  66.1   7.2   5:47.79 gcp
```

### AWS

Coming soon.
