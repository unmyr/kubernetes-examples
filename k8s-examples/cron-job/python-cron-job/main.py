#!env python
import datetime
import os
import time
try:
    import requests
except ImportError:
    import subprocess
    import sys
    subprocess.run([
        sys.executable,
        "-m",
        "pip",
        "--disable-pip-version-check",
        "install",
        "requests"
    ])
    import requests


def main():
    """main"""
    t_0: float
    t_1: float
    t_0 = time.time()
    usage_path_cpuacct = "/sys/fs/cgroup/cpuacct/cpuacct.usage"
    usage_path_memory = "/sys/fs/cgroup/memory/memory.usage_in_bytes"
    if os.path.isfile(usage_path_cpuacct):
        with open(usage_path_cpuacct) as file_handle:
            cpuacct_ns_t0 = int(file_handle.read())
    print(datetime.datetime.now().strftime('%Y-%m-%dT%H:%M:%S'))
    print("Hello from the Kubernetes cluster")
    res = requests.get("https://httpbin.org/get", params={
        "message": "Hello"
    })
    print(res.text)

    if os.path.isfile(usage_path_memory):
        with open(usage_path_memory) as file_handle:
            memory_usage_in_bytes = int(file_handle.read())
    if os.path.isfile(usage_path_cpuacct):
        with open(usage_path_cpuacct) as file_handle:
            cpuacct_ns_t1 = int(file_handle.read())
    t_1 = time.time()
    print(f"dt={t_1 - t_0:.2f}s {memory_usage_in_bytes/(1024*1024):.1f}MB {(cpuacct_ns_t1 - cpuacct_ns_t0)/1000000:.1f}ms")


if __name__ == '__main__':
    main()
