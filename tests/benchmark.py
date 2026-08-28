#!/usr/bin/env python3
"""Fresh-process Typst benchmarks; compare revisions on the same machine.

Example: python3 tests/benchmark.py --root before=/tmp/baseline --root after=.
No wall-clock thresholds are imposed on the correctness suite.
"""

import argparse
import json
import os
import platform
from pathlib import Path
import signal
import statistics
import subprocess
import tempfile
import time


CASES = {
    "grid": ("tests/stress.typ", {}),
    "polygons": ("tests/shape-stress.typ", {}),
    "curves": ("tests/curve-stress.typ", {}),
    **{name: ("tests/benchmark.typ", {"workload": name}) for name in (
        "ports", "named-chain", "captured-chain", "grouped-axes",
    )},
}


def compile_once(command, timeout):
    """Time a compile and reap its process group even when the timer times out."""
    started = time.perf_counter()
    with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          text=True, start_new_session=os.name == "posix") as child:
        try:
            stdout, stderr = child.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            # /usr/bin/time has a compiler child. Killing just the timer would
            # leave a hung compiler running and contaminate later measurements.
            if os.name == "posix":
                os.killpg(child.pid, signal.SIGKILL)
            else:
                child.kill()
            child.communicate()
            raise
        if child.returncode:
            raise subprocess.CalledProcessError(child.returncode, command, stdout, stderr)
    return time.perf_counter() - started


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", action="append", metavar="LABEL=PATH",
                        help="repeat to compare roots; each needs src/ and the benchmark fixtures")
    parser.add_argument("--case", action="append", choices=CASES)
    parser.add_argument("--runs", type=int, default=7)
    parser.add_argument("--warmups", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=60, help="maximum seconds per compile")
    parser.add_argument("--no-memory", action="store_true", help="wall time only; avoids platform-specific memory probes")
    parser.add_argument("--output", type=Path, help="write raw measurements and environment as JSON")
    args = parser.parse_args()
    if args.runs < 1 or args.warmups < 0 or args.timeout <= 0:
        parser.error("runs/timeout must be positive and warmups non-negative")
    roots = {}
    for spec in args.root or ["current=."]:
        label, separator, path = spec.partition("=")
        if not separator or not label or not path or label in roots:
            parser.error("each root must be a unique LABEL=PATH")
        roots[label] = Path(path).resolve()
    cases = args.case or list(CASES)
    system = platform.system()
    report = {
        "environment": {
            "platform": platform.platform(),
            "machine": platform.machine(),
            "typst": subprocess.check_output(["typst", "--version"], text=True).strip(),
            "fonts": "Typst bundled fonts only",
        },
        "roots": {label: str(root) for label, root in roots.items()},
        "runs": args.runs,
        "warmups": args.warmups,
        "results": {},
    }
    print(json.dumps(report["environment"]), flush=True)
    with tempfile.TemporaryDirectory(prefix="typograph-benchmark-") as temporary:
        output = Path(temporary) / "out.pdf"
        memory = Path(temporary) / "memory.txt"
        for case in cases:
            fixture, inputs = CASES[case]
            results = {label: [] for label in roots}
            for iteration in range(args.warmups + args.runs):
                # Alternate revision order to reduce systematic warm-cache or
                # thermal bias. Every measurement starts a new compiler process.
                order = list(roots.items())
                if iteration % 2:
                    order.reverse()
                for label, root in order:
                    command = ["typst", "compile", "--root", str(root), "--ignore-system-fonts"]
                    for key, value in inputs.items():
                        command += ["--input", f"{key}={value}"]
                    command += [str(root / fixture), str(output)]
                    timer = []
                    if not args.no_memory and system == "Darwin":
                        timer = ["/usr/bin/time", "-l", "-o", str(memory)]
                    elif not args.no_memory and system == "Linux":
                        timer = ["/usr/bin/time", "-f", "%M", "-o", str(memory)]
                    try:
                        elapsed = compile_once(timer + command, args.timeout)
                    except subprocess.CalledProcessError as error:
                        parser.exit(1, f"{case}/{label} failed:\n{error.stderr}")
                    except subprocess.TimeoutExpired:
                        parser.exit(1, f"{case}/{label} exceeded {args.timeout}s\n")
                    rss = None
                    if timer and system == "Darwin":
                        rss = next(int(line.split()[0]) for line in memory.read_text().splitlines()
                                   if "maximum resident set size" in line) / 1024**2
                    elif timer and system == "Linux":
                        rss = int(memory.read_text().strip()) / 1024
                    if iteration >= args.warmups:
                        results[label].append({"seconds": elapsed, "peak_rss_mib": rss})
            report["results"][case] = {}
            for label, samples in results.items():
                seconds = [sample["seconds"] for sample in samples]
                rss = [sample["peak_rss_mib"] for sample in samples if sample["peak_rss_mib"] is not None]
                summary = {
                    "median_seconds": statistics.median(seconds),
                    "min_seconds": min(seconds),
                    "max_seconds": max(seconds),
                    "median_peak_rss_mib": statistics.median(rss) if rss else None,
                    "samples": samples,
                }
                report["results"][case][label] = summary
                print(f"{case:16} {label:12} {summary['median_seconds']:.3f}s "
                      f"[{min(seconds):.3f}, {max(seconds):.3f}] "
                      f"RSS {summary['median_peak_rss_mib']} MiB", flush=True)
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
