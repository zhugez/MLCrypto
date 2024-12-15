import streamlit as st
import solcx
import json
import os
from pathlib import Path
from typing import Dict, List, Optional
import tempfile
import joblib
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from evmdasm import EvmBytecode
import re
from packaging import version
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from sklearn.preprocessing import LabelEncoder


# Add BiLSTM model class
class BiLSTMModel(nn.Module):
    def __init__(self, vocab_size, embedding_dim, hidden_dim, n_layers):
        super().__init__()
        self.embedding = nn.Embedding(vocab_size, embedding_dim)
        self.lstm = nn.LSTM(
            embedding_dim, hidden_dim, n_layers, bidirectional=True, batch_first=True
        )
        self.fc = nn.Linear(hidden_dim * 2, 2)  # 2 for binary classification

    def forward(self, x):
        embedded = self.embedding(x)
        output, (hidden, cell) = self.lstm(embedded)
        hidden = torch.cat((hidden[-2, :, :], hidden[-1, :, :]), dim=1)
        return self.fc(hidden)


class ContractAnalyzer:
    def __init__(self):
        self.DEFAULT_SOLC_VERSION = "0.4.26"
        self.models = {}
        self.vectorizer = None
        self.opcode_encoder = None
        self.setup_solc()
        self.load_models()
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    def setup_solc(self) -> bool:
        """Install and setup solc compiler"""
        try:
            # Only include supported versions (0.4.11 and above)
            versions_to_install = [
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

            for version in versions_to_install:
                if version not in solcx.get_installed_solc_versions():
                    solcx.install_solc(version)

            # Set default version
            solcx.set_solc_version(self.DEFAULT_SOLC_VERSION)
            return True
        except Exception as e:
            st.error(f"Error setting up solc: {str(e)}")
            return False

    def get_solidity_version(self, source_code: str) -> str:
        """Extract and validate Solidity version from pragma statement"""
        pragma_pattern = r"pragma solidity \^?([\d.]+);"
        match = re.search(pragma_pattern, source_code)

        if match:
            requested_version = match.group(1)
            # Clean up version string
            requested_version = requested_version.replace(" ", "")

            # If version has only two components (e.g., 0.4), append .0
            if requested_version.count(".") == 1:
                requested_version += ".0"

            # Check if version is supported
            if version.parse(requested_version) < version.parse("0.4.11"):
                st.warning(
                    f"Solidity version {requested_version} is not supported. Using version 0.4.11 instead."
                )
                return "0.4.11"

            return requested_version

        return self.DEFAULT_SOLC_VERSION

    def compile_contract(self, source_code: str) -> Optional[str]:
        """Compile Solidity contract with optimizations"""
        try:
            # Get and setup required version
            sol_version = self.get_solidity_version(source_code)

            # Validate version
            if version.parse(sol_version) < version.parse("0.4.11"):
                st.error("Solidity versions below 0.4.11 are not supported")
                return None

            # Install version if not already installed
            if sol_version not in solcx.get_installed_solc_versions():
                try:
                    solcx.install_solc(sol_version)
                except Exception as e:
                    st.error(
                        f"Failed to install Solidity version {sol_version}: {str(e)}"
                    )
                    st.info("Falling back to version 0.4.11")
                    sol_version = "0.4.11"
                    if "0.4.11" not in solcx.get_installed_solc_versions():
                        solcx.install_solc("0.4.11")

            # Set the compiler version
            solcx.set_solc_version(sol_version)

            # Compile
            compiled_sol = solcx.compile_source(
                source_code, output_values=["bin"], optimize=True
            )

            # Extract bytecode
            if not compiled_sol:
                st.error("Compilation produced no output")
                return None

            # Get the first contract's bytecode
            contract_id = list(compiled_sol.keys())[0]
            contract_interface = compiled_sol[contract_id]

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
            # Remove '0x' prefix if present
            bytecode = bytecode.replace("0x", "")

            # Create disassembler instance
            disassembler = EvmBytecode(bytecode)

            # Get list of instructions
            instructions = disassembler.disassemble()

            # Extract opcode names
            opcodes = [instruction.name for instruction in instructions]

            return opcodes
        except Exception as e:
            st.error(f"Error converting to opcodes: {str(e)}")
            return None

    def load_models(self):
        """Load all selected models"""
        try:
            model_paths = {
                "gradient_boost": "gradientboosting_artifacts/gradientboosting_model.joblib",
                "svc": "svc_artifacts/svc_model.joblib",
                "bilstm": "bilstm_artifacts/bilstm_model.pt",
            }

            # Load traditional ML models
            for model_name in ["gradient_boost", "svc"]:
                if os.path.exists(model_paths[model_name]):
                    self.models[model_name] = joblib.load(model_paths[model_name])

            # Load BiLSTM model
            if os.path.exists(model_paths["bilstm"]):
                # Load model configuration
                config = torch.load("bilstm_artifacts/model_config.pt")
                self.models["bilstm"] = BiLSTMModel(
                    vocab_size=config["vocab_size"],
                    embedding_dim=config["embedding_dim"],
                    hidden_dim=config["hidden_dim"],
                    n_layers=config["n_layers"],
                )
                self.models["bilstm"].load_state_dict(
                    torch.load(model_paths["bilstm"], map_location=self.device)
                )
                self.models["bilstm"].to(self.device)
                self.models["bilstm"].eval()

                # Load opcode encoder for BiLSTM
                if os.path.exists("bilstm_artifacts/opcode_encoder.joblib"):
                    self.opcode_encoder = joblib.load(
                        "bilstm_artifacts/opcode_encoder.joblib"
                    )

            # Load vectorizer for traditional ML models
            if os.path.exists("gradientboosting_artifacts/vectorizer.joblib"):
                self.vectorizer = joblib.load(
                    "gradientboosting_artifacts/vectorizer.joblib"
                )

            if not self.models:
                st.error("No models found in the artifacts directories")
                return False

            return True
        except Exception as e:
            st.error(f"Error loading models: {str(e)}")
            return False

    def analyze_contract(
        self, source_code: str, selected_models: List[str]
    ) -> Optional[Dict]:
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

            predictions = {}

            # Process traditional ML models
            if any(m in selected_models for m in ["gradient_boost", "svc"]):
                features = pd.DataFrame([" ".join(opcodes)], columns=["opcodes"])
                if self.vectorizer:
                    features = self.vectorizer.transform(features["opcodes"])

                for model_name in ["gradient_boost", "svc"]:
                    if model_name in selected_models and model_name in self.models:
                        pred_proba = self.models[model_name].predict_proba(features)[0]
                        predictions[model_name] = {
                            "safe": float(pred_proba[0]),
                            "vulnerable": float(pred_proba[1]),
                        }

            # Process BiLSTM model
            if "bilstm" in selected_models and "bilstm" in self.models:
                # Convert opcodes to indices
                if self.opcode_encoder:
                    opcode_indices = self.opcode_encoder.transform(opcodes)
                    # Pad or truncate sequence as needed
                    max_length = 1000  # Adjust based on your model's requirements
                    if len(opcode_indices) > max_length:
                        opcode_indices = opcode_indices[:max_length]
                    else:
                        opcode_indices = np.pad(
                            opcode_indices, (0, max_length - len(opcode_indices))
                        )

                    # Convert to tensor and get prediction
                    with torch.no_grad():
                        input_tensor = (
                            torch.LongTensor(opcode_indices)
                            .unsqueeze(0)
                            .to(self.device)
                        )
                        output = self.models["bilstm"](input_tensor)
                        probabilities = torch.softmax(output, dim=1)[0].cpu().numpy()

                        predictions["bilstm"] = {
                            "safe": float(probabilities[0]),
                            "vulnerable": float(probabilities[1]),
                        }

            return {
                "bytecode": bytecode,
                "opcodes": opcodes,
                "predictions": predictions,
            }

        except Exception as e:
            st.error(f"Analysis error: {str(e)}")
            return None

    def validate_solidity_code(self, content: str) -> bool:
        """Basic validation of Solidity code structure"""
        required_elements = {
            "pragma": r"pragma\s+solidity\s+[\^]?\d+\.\d+\.\d+;",
            "contract": r"contract\s+\w+\s*{",
            "balanced_braces": lambda c: c.count("{") == c.count("}"),
        }

        try:
            if not re.search(required_elements["pragma"], content):
                st.warning("Missing or invalid pragma solidity statement")
                st.info("Expected format: pragma solidity ^0.4.25;")
                return False

            if not re.search(required_elements["contract"], content):
                st.warning("Missing or invalid contract definition")
                st.info("Expected format: contract ContractName {")
                return False

            if not required_elements["balanced_braces"](content):
                st.warning("Unbalanced braces in contract code")
                st.info(
                    "Check that all opening braces '{' have matching closing braces '}'"
                )
                return False

            return True

        except Exception as e:
            st.error(f"Validation error: {str(e)}")
            return False


def create_prediction_plot(predictions: Dict):
    """Create visualization of model predictions"""
    fig, ax = plt.subplots(figsize=(10, 6))

    models = list(predictions.keys())
    safe_scores = [pred["safe"] * 100 for pred in predictions.values()]
    vulnerable_scores = [pred["vulnerable"] * 100 for pred in predictions.values()]

    x = np.arange(len(models))
    width = 0.35

    ax.bar(x - width / 2, safe_scores, width, label="Safe", color="green", alpha=0.6)
    ax.bar(
        x + width / 2,
        vulnerable_scores,
        width,
        label="Vulnerable",
        color="red",
        alpha=0.6,
    )

    ax.set_ylabel("Probability (%)")
    ax.set_title("Model Predictions Comparison")
    ax.set_xticks(x)
    ax.set_xticklabels([m.replace("_", " ").title() for m in models])
    ax.legend()

    plt.tight_layout()
    return fig


def display_feature_importance(model, opcodes):
    """Display feature importance if available"""
    if hasattr(model, "feature_importances_"):
        st.subheader("🎯 Feature Importance")
        importance_df = pd.DataFrame(
            {"opcode": opcodes, "importance": model.feature_importances_}
        )
        importance_df = importance_df.sort_values("importance", ascending=False).head(
            10
        )

        fig, ax = plt.subplots(figsize=(10, 6))
        ax.bar(importance_df["opcode"], importance_df["importance"])
        plt.xticks(rotation=45)
        plt.title("Top 10 Most Important Opcodes")
        st.pyplot(fig)


def main():
    st.set_page_config(
        page_title="Smart Contract Vulnerability Detection",
        page_icon="🔒",
        layout="wide",
    )

    st.title("🔒 Smart Contract Vulnerability Detection")
    st.write("Upload a Solidity file to analyze potential vulnerabilities")

    # Initialize analyzer
    if "analyzer" not in st.session_state:
        with st.spinner("Initializing analyzer..."):
            st.session_state.analyzer = ContractAnalyzer()

    # Model selection
    available_models = list(st.session_state.analyzer.models.keys())
    selected_models = st.multiselect(
        "Select Models for Analysis",
        available_models,
        default=available_models,
        help="Choose one or more models to analyze the contract",
    )

    # File upload
    uploaded_file = st.file_uploader(
        "Choose a .sol file", type=["sol"], help="Upload a Solidity smart contract file"
    )

    if uploaded_file and selected_models:
        # File info section
        with st.expander("File Details", expanded=True):
            st.write(f"📄 Filename: {uploaded_file.name}")
            st.write(f"📦 File size: {uploaded_file.size:,} bytes")

            # Show file content preview
            content = uploaded_file.getvalue().decode("utf-8")
            st.code(content[:200] + "...", language="solidity")

        # Analysis section
        with st.spinner("Analyzing contract..."):
            results = st.session_state.analyzer.analyze_contract(
                content, selected_models
            )

            if results:
                # Results section
                st.subheader("📊 Analysis Results")

                # Model predictions
                cols = st.columns(len(results["predictions"]))
                for col, (model_name, preds) in zip(
                    cols, results["predictions"].items()
                ):
                    with col:
                        st.metric(
                            label=f"{model_name.replace('_', ' ').title()}",
                            value=f"Vulnerability Risk: {preds['vulnerable']:.2%}",
                            delta=f"Safe: {preds['safe']:.2%}",
                        )

                # Visualization
                st.subheader("📈 Model Comparison")
                fig = create_prediction_plot(results["predictions"])
                st.pyplot(fig)

                # Feature importance (if available)
                if (
                    "gradient_boost" in selected_models
                    and "gradient_boost" in st.session_state.analyzer.models
                ):
                    display_feature_importance(
                        st.session_state.analyzer.models["gradient_boost"],
                        results["opcodes"],
                    )


if __name__ == "__main__":
    main()
