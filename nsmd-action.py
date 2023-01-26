#!/usr/bin/env python3

import argparse
import psutil
import oscpy.client
import oscpy.server
import sys

from typing import Optional


def add_arguments(parser: argparse.ArgumentParser) -> argparse.ArgumentParser:
    parser.add_argument(
        "action",
        action="store",
        help="action to perform",
        type=str,
        choices=("save", "close", "abort", "quit"),
        default=None,
    )
    parser.add_argument(
        "--server-name",
        action="store",
        help="server process name (default: nsmd)",
        type=str,
        default="nsmd",
    )
    parser.add_argument(
        "--server-host",
        action="store",
        help="server host address (default: localhost)",
        type=str,
        default="localhost",
    )
    parser.add_argument(
        "--server-port",
        action="store",
        help="server process name (default: found through process inspect)",
        type=int,
        default=None,
    )
    return parser


def get_proc_from_name(name: str) -> Optional[psutil.Process]:
    for proc in psutil.process_iter():
        try:
            if proc.name().lower().strip().startswith(name.lower()):
                return proc
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess) as e:
            print("Caught exception when iterating processes: {}".format(e.msg))
            pass
    return None


def main():
    parser = argparse.ArgumentParser(description="Send action to nsmd session")
    args = add_arguments(parser).parse_args()

    if args.server_port is None:
        proc = get_proc_from_name(args.server_name)
        if proc is None:
            print(
                "Process with name '{}' not found".format(args.server_name),
                file=sys.stderr,
            )
            sys.exit(1)
        print(proc)
        print(proc.connections())
        port = proc.connections()[0].laddr.port
    else:
        port = args.server_port

    client = oscpy.client.OSCClient(args.server_host, port)
    msg = "/nsm/server/{}".format(args.action).encode("utf-8")
    client.send_message(msg, [])


if __name__ == "__main__":
    main()
