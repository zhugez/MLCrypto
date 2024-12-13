import os
import subprocess
import re
from packaging import version


def run_solc_and_save(source_directory, destination_directory):
    filenames = [f for f in os.listdir(source_directory) if f.endswith(".sol")]

    for filename in filenames:
        file_path = os.path.join(source_directory, filename)

        mid_version = "0.8.26"
        with open(file_path, "r", encoding="latin1") as f:
            lines = f.readlines()
            pragma_lines = [
                line for line in lines if line.strip().startswith("pragma solidity")
            ]
            versions = []
            try:
                for pragma_line in pragma_lines:
                    versions.extend(re.findall(r"\d+\.\d+\.\d+", pragma_line))
                if versions:
                    mid_version = max(versions, key=lambda v: version.parse(v))
            except Exception as e:
                print(
                    f"Error parsing Solidity version for {filename}: {str(e)}. Using default version {mid_version}."
                )

        try:
            subprocess.run(["solc-select", "install", mid_version], check=True)
        except subprocess.CalledProcessError:
            print(
                f"Failed to install Solidity version {mid_version}. Skipping {filename}."
            )
            continue

        try:
            subprocess.run(["solc-select", "use", mid_version], check=True)
        except subprocess.CalledProcessError:
            print(
                f"Failed to switch to Solidity version {mid_version}. Skipping {filename}."
            )
            continue

        bin_file_path = os.path.join(
            destination_directory, os.path.splitext(filename)[0]
        )
        if not os.path.exists(bin_file_path):
            os.makedirs(bin_file_path)

        if os.path.exists(
            os.path.join(bin_file_path, f"{os.path.splitext(filename)[0]}.bin")
        ):
            print(f"Bin file for {filename} already exists. Skipping...")
            continue

        try:
            subprocess.run(
                ["solc", "--bin", file_path, "-o", bin_file_path],
                check=True,
            )
            print(f"Saved bytecode for {filename} to {bin_file_path}")
        except subprocess.CalledProcessError as e:
            print(f"Solc could not run on {filename}: {e}. Skipping...")


SOURCE_DIR = r"./Dataset/gaslimit"
DESTINATION_DIR = r"./output/gaslimit"


run_solc_and_save(SOURCE_DIR, DESTINATION_DIR)
