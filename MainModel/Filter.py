from pathlib import Path
from shutil import copy2
import joblib
import numpy as np
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass


@dataclass
class ContractResult:
    address: str
    confidence: float


class OpcodeFilter:
    VULNERABILITY_TYPES = {
        0: "gaslimit",
        1: "integeroverflow",
        2: "reentrancy",
        3: "other",
    }
    CONFIDENCE_THRESHOLD = 0.7

    def __init__(self, model_path: Optional[Path] = None):
        if model_path is None:
            model_path = Path(__file__).parent.parent / "Labeling" / "model.joblib"
        self.model = joblib.load(model_path)

    def process_opcodes(self, opcode_sequence: str | List[str]) -> Tuple[str, float]:
        opcode_text = (
            " ".join(opcode_sequence)
            if isinstance(opcode_sequence, list)
            else opcode_sequence
        )

        prediction_proba = self.model.predict_proba([opcode_text])[0]
        max_prob_idx = np.argmax(prediction_proba)
        max_confidence = prediction_proba[max_prob_idx]

        return (
            self.VULNERABILITY_TYPES[max_prob_idx]
            if max_confidence >= self.CONFIDENCE_THRESHOLD
            else "uncertain",
            max_confidence,
        )


def filter_contracts(input_folder: Path) -> Optional[Dict[str, List[ContractResult]]]:
    if not input_folder.is_dir():
        print(f"Error: Input folder {input_folder} not found")
        return None

    filter = OpcodeFilter()
    results = {
        vuln_type: []
        for vuln_type in [*OpcodeFilter.VULNERABILITY_TYPES.values(), "uncertain"]
    }

    print(f"Scanning directory: {input_folder}")
    files = list(input_folder.glob("*"))
    print(f"Found {len(files)} files")

    for file_path in files:
        if not file_path.is_file():
            continue

        try:
            process_file(file_path, filter, results)
        except Exception as e:
            print(f"Error processing file {file_path}: {str(e)}")

    print_results_summary(results)
    return results


def print_results_summary(results: Dict[str, List[ContractResult]]) -> None:
    print("\nResults summary:")
    for vuln_type, contracts in results.items():
        print(f"{vuln_type}: {len(contracts)} contracts")


def process_file(
    file_path: Path, filter: OpcodeFilter, results: Dict[str, List[ContractResult]]
) -> None:
    with open(file_path, "r") as f:
        opcodes = f.read().strip()
        if not opcodes:
            print(f"Skipping empty file: {file_path}")
            return

        address = file_path.stem
        vuln_type, confidence = filter.process_opcodes(opcodes)
        results[vuln_type].append(
            ContractResult(address=address, confidence=confidence)
        )
        # print(f"Processed {address}: {vuln_type} ({confidence:.2f})")
        # save the file to the output folder
        output_folder = (
            Path(__file__).parent.parent
            / "Datapreprocessing"
            / "filtered_results"
            / vuln_type
        )
        output_folder.mkdir(parents=True, exist_ok=True)
        copy2(str(file_path), str(output_folder / file_path.name))


def save_results(
    results: Dict[str, List[ContractResult]], output_dir: Path, input_folder: Path
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"\nSaving results to: {output_dir}")

    for vuln_type, contracts in results.items():
        vuln_folder = output_dir / vuln_type
        vuln_folder.mkdir(exist_ok=True)

        for contract in contracts:
            copy_contract_file(contract, input_folder, vuln_folder)

    write_summary_file(results, output_dir)


def copy_contract_file(
    contract: ContractResult, input_folder: Path, vuln_folder: Path
) -> None:
    possible_extensions = ["", ".txt", "_opcodes.txt", "_opcodes"]
    source_file = None

    for ext in possible_extensions:
        possible_source = input_folder / f"{contract.address}{ext}"
        if possible_source.exists():
            source_file = possible_source
            break

    if source_file:
        try:
            copy2(str(source_file), str(vuln_folder / source_file.name))
            print(f"Successfully copied {source_file.name}")
        except Exception as e:
            print(f"Error copying {source_file}: {str(e)}")
    else:
        print(f"Warning: No source file found for contract {contract.address}")


def write_summary_file(
    results: Dict[str, List[ContractResult]], output_dir: Path
) -> None:
    total_contracts = sum(len(contracts) for contracts in results.values())

    with open(output_dir / "summary.txt", "w") as f:
        f.write("Vulnerability Type Analysis Summary\n")
        f.write("=================================\n\n")

        for vuln_type, contracts in results.items():
            percentage = (
                (len(contracts) / total_contracts * 100) if total_contracts > 0 else 0
            )
            f.write(f"{vuln_type.capitalize()}:\n")
            f.write(f"  Count: {len(contracts)}\n")
            f.write(f"  Percentage: {percentage:.2f}%\n")
            f.write("  Contracts:\n")
            for contract in contracts:
                f.write(
                    f"    - {contract.address} (confidence: {contract.confidence:.2f})\n"
                )
            f.write("\n")


def main():
    base_dir = Path(__file__).parent.parent
    input_folder = base_dir / "Datapreprocessing" / "OutputOpcodes"
    output_dir = base_dir / "Datapreprocessing" / "filtered_results"

    print(f"Processing files from: {input_folder}")
    filter_contracts(input_folder)
    # if results := filter_contracts(input_folder):
    # print("Done")
    # print_results_summary(results)


if __name__ == "__main__":
    main()
