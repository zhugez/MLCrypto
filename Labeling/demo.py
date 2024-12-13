import streamlit as st
import solcx
import json
import os
from pathlib import Path
from typing import Dict, List, Optional
import tempfile
import joblib
import numpy as np


class ContractAnalyzer:
    def __init__(self):
        self.SOLC_VERSION = "0.4.26"
        self.model = None
        self.vectorizer = None
        self.setup_solc()
        self.load_model()

    def setup_solc(self) -> bool:
        """Install and setup solc compiler"""
        try:
            solcx.install_solc(self.SOLC_VERSION)
            solcx.set_solc_version(self.SOLC_VERSION)
            return True
        except Exception as e:
            st.error(f"Error setting up solc: {str(e)}")
            return False

    def compile_contract(
        self, source_code: str, optimization: bool = True
    ) -> Optional[Dict]:
        """Compile Solidity contract with optional optimization"""
        try:
            compile_settings = {
                "language": "Solidity",
                "optimize": optimization,
                "optimize_runs": 200 if optimization else 0,
                "output_values": ["abi", "bin", "bin-runtime"],
            }

            compiled_sol = solcx.compile_source(
                source_code,
                output_values=["abi", "bin", "bin-runtime"],
                optimize=optimization,
                solc_version=self.SOLC_VERSION,
                allow_paths=".",
            )

            return compiled_sol
        except Exception as e:
            st.error(f"Compilation error: {str(e)}")
            return None

    def get_opcodes(self, bytecode: str) -> Optional[List[str]]:
        """Convert bytecode to opcodes using evmdasm"""
        try:
            from evmdasm import EvmBytecode

            # Remove '0x' prefix if present
            bytecode = bytecode.replace("0x", "")

            # Create disassembler instance
            disassembler = EvmBytecode(bytecode)

            # Get list of instructions
            instructions = disassembler.disassemble()

            # Extract opcode names
            opcodes = [instruction.name for instruction in instructions]

            return opcodes
        except ImportError:
            st.error(
                "Required package 'evmdasm' is not installed. Please install it using: pip install evmdasm"
            )
            return None
        except Exception as e:
            st.error(f"Error converting to opcodes: {str(e)}")
            return None

    def load_model(self):
        """Load the trained model and vectorizer"""
        try:
            model_path = Path(__file__).parent / "model.joblib"
            self.grid_search = joblib.load(model_path)

            # No need to extract best_estimator or vectorizer
            # We'll use the GridSearchCV object directly
            if not hasattr(self.grid_search, "predict"):
                st.error("Loaded model does not have predict method")
                self.grid_search = None

        except Exception as e:
            st.error(f"Error loading model: {str(e)}")
            self.grid_search = None

    def predict_contract(self, opcodes: List[str]) -> Optional[Dict]:
        """Predict contract classification using the loaded model"""
        try:
            if self.grid_search is None:
                st.error("Model not loaded")
                return None

            # Label mapping for vulnerability types
            label_names = {0: "gaslimit", 1: "integeroverflow", 2: "reentrancy"}

            # Convert opcodes list to space-separated string
            opcode_text = " ".join(opcodes)

            # Use the GridSearchCV object directly for prediction
            # The pipeline will handle the vectorization internally
            prediction = self.grid_search.predict([opcode_text])[0]
            probabilities = self.grid_search.predict_proba([opcode_text])[0]

            return {
                "prediction": int(prediction),
                "vulnerability_type": label_names[int(prediction)],
                "confidence": float(np.max(probabilities)),
                "probabilities": {
                    f"{label_names[i]}": float(prob)
                    for i, prob in enumerate(probabilities)
                },
            }
        except Exception as e:
            st.error(f"Error making prediction: {str(e)}")
            return None


def render_sidebar():
    """Render sidebar with settings"""
    st.sidebar.header("Settings")

    optimization = st.sidebar.checkbox(
        "Enable Optimization", value=True, help="Enable solc optimizer"
    )

    solc_version = st.sidebar.selectbox(
        "Solc Version",
        ["0.4.26", "0.4.25", "0.4.24", "0.4.23", "0.4.22"],
        help="Select solidity compiler version",
    )

    return {"optimization": optimization, "solc_version": solc_version}


def save_upload_file(uploaded_file) -> Optional[str]:
    """Save uploaded file to temp directory"""
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".sol") as tmp_file:
            tmp_file.write(uploaded_file.getvalue())
            return tmp_file.name
    except Exception as e:
        st.error(f"Error saving file: {str(e)}")
        return None


def main():
    st.set_page_config(
        page_title="Solidity Contract Analyzer", page_icon="🔍", layout="wide"
    )

    st.title("🔍 Solidity Contract Labeling")

    # Get settings from sidebar
    settings = render_sidebar()

    # Initialize analyzer
    analyzer = ContractAnalyzer()

    # File upload
    uploaded_file = st.file_uploader(
        "Upload Solidity Contract",
        type=["sol"],
        help="Upload a Solidity smart contract file",
    )

    if uploaded_file:
        # Save file
        file_path = save_upload_file(uploaded_file)
        if not file_path:
            return

        # Read source code
        source_code = uploaded_file.getvalue().decode("utf-8")

        # Create columns for display
        col1, col2 = st.columns(2)

        with col1:
            st.subheader("📝 Source Code")
            st.code(source_code, language="solidity")

        # Compile button
        if st.button("🔨 Compile and Analyze"):
            with st.spinner("Compiling and analyzing contract..."):
                # Compile contract
                compiled_sol = analyzer.compile_contract(
                    source_code, settings["optimization"]
                )

                if compiled_sol:
                    # Get contract data
                    contract_id, contract_interface = compiled_sol.popitem()
                    bytecode = contract_interface["bin"]
                    runtime_bytecode = contract_interface["bin-runtime"]
                    abi = contract_interface["abi"]

                    with col2:
                        st.subheader("📊 Analysis Results")

                        # Display contract info
                        st.write("Contract Information:")
                        contract_info = {
                            "name": Path(uploaded_file.name).stem,
                            "size": len(bytecode) // 2,
                            "functions": len(
                                [x for x in abi if x["type"] == "function"]
                            ),
                        }
                        st.json(contract_info)

                        # Get and display opcodes
                        opcodes = analyzer.get_opcodes(bytecode)
                        if opcodes:
                            st.write("Opcodes:")
                            st.json(opcodes)

                            # Make prediction
                            prediction_result = analyzer.predict_contract(opcodes)
                            if prediction_result:
                                st.write("🎯 Vulnerability Analysis:")
                                st.markdown(
                                    f"**Detected Vulnerability: {prediction_result['vulnerability_type']}**"
                                )
                                st.markdown(
                                    f"**Confidence: {prediction_result['confidence']:.2%}**"
                                )
                                st.write("Vulnerability Probabilities:")
                                for vuln_type, prob in prediction_result[
                                    "probabilities"
                                ].items():
                                    st.write(f"- {vuln_type}: {prob:.2%}")

                            # Save results
                            results = {
                                "contract_name": Path(uploaded_file.name).stem,
                                "bytecode": bytecode,
                                "runtime_bytecode": runtime_bytecode,
                                "abi": abi,
                                "opcodes": opcodes,
                                "prediction": prediction_result,
                            }

                            # Download button
                            if st.download_button(
                                "💾 Download Analysis Results",
                                data=json.dumps(results, indent=2),
                                file_name=f"{Path(uploaded_file.name).stem}_analysis.json",
                                mime="application/json",
                            ):
                                st.success("Analysis results downloaded!")

        # Cleanup
        if file_path and os.path.exists(file_path):
            os.unlink(file_path)


if __name__ == "__main__":
    main()
