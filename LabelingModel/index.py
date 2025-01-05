import os
import subprocess
import re
from packaging import version
from pathlib import Path
import logging


class SolidityVersionCompiler:
    def __init__(self, source_dir: str, destination_dir: str):
        self.source_dir = Path(source_dir).resolve()
        self.destination_dir = Path(destination_dir).resolve()

        # List of available Solidity versions less than 5.0
        available_versions = [
            "0.4.0",
            "0.4.1",
            "0.4.2",
            "0.4.3",
            "0.4.4",
            "0.4.5",
            "0.4.6",
            "0.4.7",
            "0.4.8",
            "0.4.9",
            "0.4.10",
            "0.4.11",
            "0.4.12",
            "0.4.13",
            "0.4.14",
            "0.4.15",
            "0.4.16",
            "0.4.17",
            "0.4.18",
            "0.4.19",
            "0.4.20",
            "0.4.21",
            "0.4.22",
            "0.4.23",
            "0.4.24",
            "0.4.25",
            "0.4.26",
        ]

        # Calculate the middle version
        middle_index = len(available_versions) // 2
        self.default_version = available_versions[middle_index]

        # Setup logging
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            handlers=[logging.FileHandler("compilation.log"), logging.StreamHandler()],
        )
        self.logger = logging.getLogger(__name__)

        # Log the resolved paths and default version
        self.logger.info(f"Source directory resolved to: {self.source_dir}")
        self.logger.info(f"Destination directory resolved to: {self.destination_dir}")
        self.logger.info(f"Default Solidity version set to: {self.default_version}")

        # Create destination directory if it doesn't exist
        self.destination_dir.mkdir(parents=True, exist_ok=True)

    def get_solidity_version(self, file_path: Path) -> str:
        """Extract Solidity version from pragma statement"""
        try:
            content = file_path.read_text(encoding="latin1")
            pragma_lines = [
                line
                for line in content.splitlines()
                if line.strip().startswith("pragma solidity")
            ]

            versions = []
            for pragma_line in pragma_lines:
                versions.extend(re.findall(r"\d+\.\d+\.\d+", pragma_line))

            if versions:
                return max(versions, key=lambda v: version.parse(v))

            return self.default_version

        except Exception as e:
            self.logger.warning(
                f"Error parsing Solidity version: {str(e)}. Using default {self.default_version}"
            )
            return self.default_version

    def setup_solidity_version(self, sol_version: str) -> bool:
        """Install and switch to specified Solidity version"""
        try:
            # Install version
            subprocess.run(
                ["solc-select", "install", sol_version], check=True, capture_output=True
            )

            # Switch to version
            result = subprocess.run(
                ["solc-select", "use", sol_version], check=True, capture_output=True
            )
            self.logger.info(f"{result.stdout.decode()}")
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(
                f"Failed to setup Solidity version {sol_version}: {e.stderr.decode()}"
            )
            return False

    def compile_contract(self, sol_file: Path) -> bool:
        """Compile single Solidity contract with enhanced error handling"""
        try:
            # Simplified compiler options
            compile_command = [
                "solc",
                "--bin",
                "--optimize",
                "--optimize-runs",
                "200",
                str(sol_file),
            ]

            result = subprocess.run(compile_command, capture_output=True, text=True)

            if result.returncode != 0:
                self.logger.error(
                    f"Compilation failed for {sol_file.name}: {result.stderr}"
                )
                return False

            # Only save if we have actual bytecode output
            if result.stdout.strip():
                # Extract just the bytecode (remove the header/comments)
                bytecode = result.stdout.split("\n")
                # Find the actual bytecode line (after the Binary: line)
                for i, line in enumerate(bytecode):
                    if line.startswith("Binary:"):
                        if i + 1 < len(bytecode):
                            actual_bytecode = bytecode[i + 1].strip()
                            if actual_bytecode:
                                output_file = (
                                    self.destination_dir / f"{sol_file.stem}.bin"
                                )
                                output_file.write_text(actual_bytecode)
                                self.logger.info(f"Saved bytecode for {sol_file.name}")
                                return True

            self.logger.warning(f"No bytecode generated for {sol_file.name}")
            return False

        except Exception as e:
            self.logger.error(f"Unexpected error processing {sol_file.name}: {str(e)}")
            return False

    def compile_all(self):
        """Compile all Solidity files in source directory with optimized processing"""
        self.logger.info(f"Searching for .sol files in: {self.source_dir.absolute()}")

        if not self.source_dir.exists():
            self.logger.error(f"Directory does not exist: {self.source_dir.absolute()}")
            return

        # Get all .sol files and add recursive search
        sol_files = list(
            self.source_dir.glob("**/*.sol")
        )  # Changed to recursive search
        total_files = len(sol_files)

        self.logger.info(f"Found {total_files} Solidity files")
        # Add detailed file listing
        for file in sol_files:
            self.logger.info(f"Found file: {file}")

        # Group files by Solidity version to minimize version switching
        version_groups = {}
        for sol_file in sol_files:
            version = self.get_solidity_version(sol_file)
            self.logger.info(
                f"File {sol_file.name} uses Solidity version {version}"
            )  # Added version logging
            version_groups.setdefault(version, []).append(sol_file)

        processed = 0
        failed = 0

        # Process files grouped by version
        for version, files in version_groups.items():
            # Setup version once for all files using it
            if self.setup_solidity_version(version):
                for sol_file in files:
                    try:
                        if self.compile_contract(sol_file):
                            processed += 1
                        else:
                            failed += 1
                    except Exception as e:
                        self.logger.error(f"Error compiling {sol_file.name}: {str(e)}")
                        failed += 1
            else:
                failed += len(files)
                self.logger.error(
                    f"Failed to set up version {version}, skipping {len(files)} files"
                )

        self.logger.info(f"\nProcessing Summary:")
        self.logger.info(f"Total files found: {total_files}")
        self.logger.info(f"Files processed: {len(sol_files)}")
        self.logger.info(f"Successfully compiled: {processed}")
        self.logger.info(f"Failed to compile: {failed}")


def main():
    inPath = [
        "../Dataset/reentrancy/",
        "../Dataset/gaslimit/",
        "../Dataset/Integeroverflow/",
    ]
    outPath = [
        "./output/reentrancy/",
        "./output/gaslimit/",
        "./output/integeroverflow/",
    ]
    for i in range(len(inPath)):
        compiler = SolidityVersionCompiler(
            source_dir=inPath[i], destination_dir=outPath[i]
        )
        compiler.compile_all()


if __name__ == "__main__":
    main()
