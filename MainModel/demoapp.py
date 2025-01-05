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
        self.models = {}
        self.vectorizer = None
        self.opcode_encoder = None
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.load_models()

    def load_models(self):
        """Load all models and associated files."""
        try:
            model_paths = {
                "gradient_boost": "gradientboosting_artifacts/gradientboosting_model.joblib",
                "svc": "svc_artifacts/svc_model.joblib",
                "bilstm": "bilstm_artifacts/bilstm_model.pt",
            }

            # Load SVC and GradientBoosting models
            for model_name in ["gradient_boost", "svc"]:
                if os.path.exists(model_paths[model_name]):
                    self.models[model_name] = joblib.load(model_paths[model_name])

            # Load BiLSTM model
            if os.path.exists(model_paths["bilstm"]):
                # Load BiLSTM model configuration
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

            # Load vectorizer for SVC and GradientBoosting
            if os.path.exists("gradientboosting_artifacts/vectorizer.joblib"):
                self.vectorizer = joblib.load(
                    "gradientboosting_artifacts/vectorizer.joblib"
                )

        except Exception as e:
            st.error(f"Error loading models: {str(e)}")

    def analyze_contract(
        self, bytecode: str, selected_models: List[str]
    ) -> Optional[Dict]:
        """Analyze contract bytecode with selected models."""
        try:
            predictions = {}

            # Process traditional ML models
            if any(m in selected_models for m in ["gradient_boost", "svc"]):
                features = pd.DataFrame([bytecode], columns=["bytecode"])
                if self.vectorizer:
                    features = self.vectorizer.transform(features["bytecode"])

                for model_name in ["gradient_boost", "svc"]:
                    if model_name in selected_models and model_name in self.models:
                        pred_proba = self.models[model_name].predict_proba(features)[0]
                        predictions[model_name] = {
                            "safe": float(pred_proba[0]),
                            "vulnerable": float(pred_proba[1]),
                        }

            # Process BiLSTM model
            if "bilstm" in selected_models and "bilstm" in self.models:
                if self.opcode_encoder:
                    opcode_indices = self.opcode_encoder.transform(bytecode)
                    max_length = 1000
                    if len(opcode_indices) > max_length:
                        opcode_indices = opcode_indices[:max_length]
                    else:
                        opcode_indices = np.pad(
                            opcode_indices, (0, max_length - len(opcode_indices))
                        )
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

            return predictions
        except Exception as e:
            st.error(f"Analysis error: {str(e)}")
            return None


def create_prediction_plot(predictions: Dict):
    """Create a bar chart for model predictions."""
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


def main():
    st.set_page_config(
        page_title="Smart Contract Analyzer", page_icon="🔒", layout="wide"
    )
    st.title("🔒 Smart Contract Vulnerability Detection")
    st.write("Upload a bytecode file to analyze potential vulnerabilities.")

    # Initialize the analyzer
    if "analyzer" not in st.session_state:
        st.session_state.analyzer = ContractAnalyzer()

    # Model selection
    available_models = list(st.session_state.analyzer.models.keys())
    selected_models = st.multiselect(
        "Select Models for Analysis",
        available_models,
        default=available_models,
        help="Choose one or more models to analyze the contract.",
    )

    # File upload
    uploaded_file = st.file_uploader("Choose a bytecode file", type=["txt"])
    if uploaded_file and selected_models:
        bytecode = uploaded_file.getvalue().decode("utf-8").strip()
        if not bytecode:
            st.error("Invalid bytecode file.")
            return

        with st.spinner("Analyzing contract..."):
            predictions = st.session_state.analyzer.analyze_contract(
                bytecode, selected_models
            )
            if predictions:
                st.subheader("📊 Analysis Results")
                fig = create_prediction_plot(predictions)
                st.pyplot(fig)
                st.success("Analysis complete. Check the chart above for results.")


if __name__ == "__main__":
    main()
