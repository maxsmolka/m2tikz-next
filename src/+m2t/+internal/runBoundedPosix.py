"""Internal POSIX compiler supervisor; Python 3 standard library only."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys


def run(command_file, output_file, seconds):
    result = {"exitCode": -1, "timedOut": False, "error": ""}
    process = None
    try:
        command = Path(command_file).read_text(encoding="utf-8")
        # Files, not PIPEs: a grandchild retaining stdout cannot block output
        # collection after the parent exits. No shell expansion of file paths.
        with open(output_file, "wb") as output:
            process = subprocess.Popen(
                ["/bin/sh", "-c", command], stdin=subprocess.DEVNULL,
                stdout=output, stderr=subprocess.STDOUT, start_new_session=True,
            )
            try:
                result["exitCode"] = process.wait(timeout=seconds)
            except subprocess.TimeoutExpired:
                result["timedOut"] = True
                result["exitCode"] = 124
            finally:
                # Kill the owned local session's process group on timeout AND
                # normal launcher exit. Deliberately detached/remote work is
                # outside this process boundary; this is not a TeX sandbox.
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                process.wait(timeout=5)
    except Exception as error:
        result["error"] = str(error)
    return result


if __name__ == "__main__":
    command_file, output_file, result_file, seconds = sys.argv[1:]
    result = run(command_file, output_file, float(seconds))
    Path(result_file).write_text(json.dumps(result), encoding="utf-8")
