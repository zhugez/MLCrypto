import streamlit as st
import solcx
import json
import os
from pathlib import Path
from typing import Dict, List, Optional
import tempfile
import joblib
import numpy as np
from evmdasm import EvmBytecode
import re
from packaging import version

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

    def compile_contract(self, source_code: str) -> Optional[Dict]:
        """Compile Solidity contract with optimizations"""
        try:
            # Get and setup required version
            sol_version = self.get_solidity_version(source_code)
            solcx.set_solc_version(sol_version)

            # Compile settings
            compile_settings = {
                "language": "Solidity",
                "optimize": True,
                "optimize_runs": 200,
                "output_values": ["bin", "bin-runtime"],
            }

            # Compile
            compiled_sol = solcx.compile_source(
                source_code,
                output_values=["bin"],
                optimize=True,
                solc_version=sol_version
            )

            # Extract bytecode
            if not compiled_sol:
                st.error("Compilation produced no output")
                return None

            # Get the first contract's bytecode
            contract_id, contract_interface = next(iter(compiled_sol.items()))
            if "bin" not in contract_interface:
                st.error("No bytecode generated")
                return None
            
            return contract_interface["bin"]

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
        """Load the trained model"""
        try:
            self.model = joblib.load('gradientboosting_artifacts/gradientboosting_model.joblib')
            self.vectorizer = joblib.load('gradientboosting_artifacts/vectorizer.joblib')
            return True
        except Exception as e:
            st.error(f"Error loading model: {str(e)}")
            return False

    def analyze_contract(self, source_code: str) -> Optional[Dict]:
        """Complete contract analysis pipeline"""
        try:
            # Validate code structure
            if not self.validate_solidity_code(source_code):
                return None

            # Compile to bytecode
            bytecode = self.compile_contract(source_code)
            if not bytecode:
                return None

            # Convert to opcodes
            opcodes = self.get_opcodes(bytecode)
            if not opcodes:
                return None

            # Create feature vector
            features = pd.DataFrame([' '.join(opcodes)], columns=['opcodes'])

            # Get predictions
            predictions = {}
            for model_name, model in self.models.items():
                pred_proba = model.predict_proba(features)[0]
                predictions[model_name] = {
                    "safe": float(pred_proba[0]),
                    "vulnerable": float(pred_proba[1])
                }

            return {
                "bytecode": bytecode,
                "opcodes": opcodes,
                "predictions": predictions
            }

        except Exception as e:
            st.error(f"Analysis error: {str(e)}")
            return None

    def validate_solidity_code(self, content: str) -> bool:
        """
        Basic validation of Solidity code structure
        Returns: True if basic structure looks valid, False otherwise
        """
        # Check for basic required elements
        required_elements = {
            'pragma': r'pragma\s+solidity\s+[\^]?\d+\.\d+\.\d+;',
            'contract': r'contract\s+\w+\s*{',
            'balanced_braces': lambda c: c.count('{') == c.count('}')
        }
        
        try:
            # Check pragma
            if not re.search(required_elements['pragma'], content):
                st.warning("Missing or invalid pragma solidity statement")
                st.info("""
                Expected format: pragma solidity ^0.4.25;
                Make sure to specify the Solidity version at the start of your contract.
                """)
                return False
            
            # Check contract definition
            if not re.search(required_elements['contract'], content):
                st.warning("Missing or invalid contract definition")
                st.info("""
                Expected format: contract ContractName {
                Make sure your contract has a valid name and opening brace.
                """)
                return False
            
            # Check balanced braces
            if not required_elements['balanced_braces'](content):
                st.warning("Unbalanced braces in contract code")
                st.info("""
                Check that all opening braces '{' have matching closing braces '}'.
                Use an IDE or code editor to help match your braces.
                """)
                return False
            
            # Basic syntax validation passed
            return True
            
        except Exception as e:
            st.error(f"Validation error: {str(e)}")
            return False

def main():
    st.set_page_config(
        page_title="Smart Contract Vulnerability Detection",
        page_icon="🔒",
        layout="wide"
    )

    st.title("🔒 Smart Contract Vulnerability Detection")
    st.write("Upload a Solidity file to analyze potential vulnerabilities")

    # Initialize analyzer
    if 'analyzer' not in st.session_state:
        with st.spinner('Initializing analyzer...'):
            st.session_state.analyzer = ContractAnalyzer()

    # File upload
    uploaded_file = st.file_uploader(
        "Choose a .sol file",
        type=['sol'],
        help="Upload a Solidity smart contract file"
    )

    if uploaded_file:
        # File info section
        with st.expander("File Details", expanded=True):
            st.write(f"📄 Filename: {uploaded_file.name}")
            st.write(f"📦 File size: {uploaded_file.size:,} bytes")
            
            # Show file content preview
            content = uploaded_file.getvalue().decode("utf-8")
            st.code(content[:200] + "...", language='solidity')

        # Analysis section
        with st.spinner('Analyzing contract...'):
            results = st.session_state.analyzer.analyze_contract(content)
            
            if results:
                # Results section
                st.subheader("📊 Analysis Results")
                
                # Model predictions
                cols = st.columns(len(results["predictions"]))
                for col, (model_name, preds) in zip(cols, results["predictions"].items()):
                    with col:
                        st.metric(
                            label=f"{model_name.title()}",
                            value=f"Vulnerability Risk: {preds['vulnerable']:.2%}",
                            delta=f"Safe: {preds['safe']:.2%}"
                        )

                # Visualization
                st.subheader("📈 Model Comparison")
                fig = create_prediction_plot(results["predictions"])
                st.pyplot(fig)

                # Feature importance (if available)
                if hasattr(st.session_state.analyzer.models["gradient_boost"], 'feature_importances_'):
                    display_feature_importance(
                        st.session_state.analyzer.models["gradient_boost"],
                        results["opcodes"]
                    )

if __name__ == "__main__":
    main()