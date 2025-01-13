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
from collections import defaultdict

class CerberusAnalyzer:
    def __init__(self):
        self.SOLC_VERSION = "0.4.26"
        self.model = None
        self.vectorizer = None
        self.setup_solc()
        self.load_artifacts()

    def setup_solc(self) -> bool:
        """Install and setup solc compiler"""
        try:
            solcx.install_solc(self.SOLC_VERSION)
            solcx.set_solc_version(self.SOLC_VERSION)
            return True
        except Exception as e:
            st.error(f"Error setting up solc: {str(e)}")
            return False

    def load_artifacts(self):
        """Load model and vectorizer from artifacts"""
        try:
            artifacts_dir = Path(__file__).parent / "gradientboosting_artifacts"
            model_path = artifacts_dir / "gradientboosting_model.joblib"
            vectorizer_path = artifacts_dir / "vectorizer.joblib"

            self.model = joblib.load(model_path)
            self.vectorizer = joblib.load(vectorizer_path)

            if not hasattr(self.model, "predict"):
                st.error("Invalid model format")
                self.model = None
        except Exception as e:
            st.error(f"Error loading artifacts: {str(e)}")
            self.model = None
            self.vectorizer = None

    def validate_solidity_code(self, source_code: str) -> bool:
        """Validate basic Solidity code structure"""
        required_elements = [
            'pragma solidity',
            'contract',
            '{'
        ]
        return all(element in source_code for element in required_elements)

    def compile_contract(self, source_code: str, optimization: bool = True) -> Optional[Dict]:
        """Compile Solidity contract with validation"""
        try:
            if not self.validate_solidity_code(source_code):
                st.error("Invalid Solidity code structure. Make sure to include pragma and contract declaration.")
                return None

            # Add pragma if missing
            if 'pragma solidity' not in source_code:
                source_code = f'pragma solidity ^{self.SOLC_VERSION};\n{source_code}'

            # Ensure proper contract structure
            if 'contract' not in source_code:
                source_code = f'''
                pragma solidity ^{self.SOLC_VERSION};
                contract AnalyzedContract {{
                    {source_code}
                }}'''

            compiled_sol = solcx.compile_source(
                source_code,
                output_values=["abi", "bin", "bin-runtime"],
                optimize=optimization,
                solc_version=self.SOLC_VERSION,
                allow_paths="."
            )
            return compiled_sol

        except Exception as e:
            st.error(f"Compilation error: {str(e)}")
            st.code(source_code, language="solidity")  # Display problematic code
            return None

    def predict_vulnerabilities(self, bytecode: str) -> Optional[Dict]:
        """Predict vulnerabilities using the loaded model"""
        try:
            st.write("Extracting features...")
            features = extract_features_from_bytecode(bytecode)
            if features is None:
                return None
                
            # st.write(f"Features shape: {features.shape}")
            X = features.reshape(1, -1)
            
            st.write("Making prediction...")
            if self.model is None:
                st.error("Model not loaded")
                return None

            # Get prediction and probabilities
            prediction = self.model.predict(X)[0]
            probabilities = self.model.predict_proba(X)[0]

            # st.write(f"Raw prediction: {prediction}")
            # st.write(f"Probabilities: {probabilities}")

            # Map string labels to indices
            label_to_index = {
                "clean contract": 0,
                "gaslimit": 1,
                "integeroverflow": 2,
                "reentrancy": 3
            }

            # Map prediction to vulnerability info
            vulnerability_types = {
                0: "Clean Contract",    # No vulnerabilities detected
                1: "Gas Limit Issues",
                2: "Integer Overflow",
                3: "Reentrancy"
                 }

            severity_levels = {
                "Clean Contract": "None",  # Added clean case
                "Gas Limit Issues": "Medium",
                "Integer Overflow": "High",
                "Reentrancy": "Critical"
            }

            # Convert string label to index
            pred_index = label_to_index.get(str(prediction).lower(), 0)
            vuln_type = vulnerability_types[pred_index]
            
            if vuln_type == "Clean Contract":
                return {
                    "prediction": pred_index,
                    "vulnerability_type": "Clean Contract",
                    "severity": "None",
                    "confidence": float(np.max(probabilities)),
                    "probabilities": {
                        vulnerability_types[i]: float(prob)
                        for i, prob in enumerate(probabilities)
                    },
                    "is_clean": True  # Flag for clean contracts
                }
            else:
                return {
                    "prediction": pred_index,
                    "vulnerability_type": vuln_type,
                    "severity": severity_levels[vuln_type],
                    "confidence": float(np.max(probabilities)),
                    "probabilities": {
                        vulnerability_types[i]: float(prob)
                        for i, prob in enumerate(probabilities)
                    },
                    "is_clean": False
                }

        except Exception as e:
            st.error(f"Prediction error: {str(e)}")
            st.exception(e)
            return None

def get_valid_opcodes(bytecode: str) -> List[str]:
    """Get valid EVM opcodes from bytecode with error handling"""
    try:
        # Remove '0x' prefix if present
        bytecode = bytecode.replace('0x', '')
        
        # Initialize disassembler
        disassembler = EvmBytecode(bytecode)
        
        # Get instructions with validation
        valid_opcodes = []
        for instruction in disassembler.disassemble():
            try:
                # Only add valid opcodes
                if instruction.name and not instruction.name.startswith('INVALID'):
                    valid_opcodes.append(instruction.name)
            except AttributeError:
                continue
                
        return valid_opcodes
    except Exception as e:
        st.error(f"Error processing bytecode: {str(e)}")
        return []

def clean_opcodes(opcode_list):
    # Remove UNKNOWN and INVALID opcodes
    cleaned = [op for op in opcode_list if not (op.startswith('UNKNOWN_') or op.startswith('INVALID_'))]
    
    # Remove numeric values after opcodes (e.g., PUSH1, PUSH2 -> PUSH)
    cleaned = [op.rstrip('0123456789') for op in cleaned]
    
    return cleaned

def extract_features_from_bytecode(bytecode: str) -> np.ndarray:
    """Extract features from bytecode using methods from notebook"""
    try:
        # Get opcodes first
        opcodes = get_valid_opcodes(bytecode)
        if not opcodes:
            return None
            
        # Clean opcodes
        cleaned_opcodes = clean_opcodes(opcodes)
        opcode_text = " ".join(cleaned_opcodes)

        # Extract features based on vulnerability types
        features = {}
        
        # Basic block features
        block_features = {
            'num_nodes': len(set(cleaned_opcodes)),
            'num_edges': len(cleaned_opcodes) - 1,
            'max_in_degree': 0,
            'max_out_degree': 0,
            'avg_in_degree': 0,
            'avg_out_degree': 0,
            'density': 0,
            'clustering_coefficient': 0
        }

        # Build edges and calculate degrees
        edges = defaultdict(list)
        in_degree = defaultdict(int)
        out_degree = defaultdict(int)
        
        for i in range(len(cleaned_opcodes)-1):
            curr_op = cleaned_opcodes[i]
            next_op = cleaned_opcodes[i+1]
            edges[curr_op].append(next_op)
            out_degree[curr_op] += 1
            in_degree[next_op] += 1

        # Calculate advanced metrics
        num_nodes = len(set(cleaned_opcodes))
        if num_nodes > 0:
            block_features['max_in_degree'] = max(in_degree.values()) if in_degree else 0
            block_features['max_out_degree'] = max(out_degree.values()) if out_degree else 0
            block_features['avg_in_degree'] = sum(in_degree.values()) / num_nodes
            block_features['avg_out_degree'] = sum(out_degree.values()) / num_nodes
            block_features['density'] = len(edges) / (num_nodes * (num_nodes - 1)) if num_nodes > 1 else 0

        # Opcode frequency features
        opcode_categories = {
            'arithmetic': {'ADD', 'MUL', 'SUB', 'DIV', 'SDIV', 'MOD', 'SMOD', 'ADDMOD', 'MULMOD', 'EXP'},
            'bitwise': {'AND', 'OR', 'XOR', 'NOT', 'BYTE', 'SHL', 'SHR', 'SAR'},
            'comparison': {'LT', 'GT', 'SLT', 'SGT', 'EQ', 'ISZERO'},
            'memory': {'MLOAD', 'MSTORE', 'MSTORE8', 'MSIZE', 'MCOPY'},
            'storage': {'SLOAD', 'SSTORE'},
            'control': {'JUMP', 'JUMPI', 'JUMPDEST', 'PC', 'GAS'},
            'stack': {'POP', 'PUSH', 'DUP', 'SWAP'},
            'system': {'CREATE', 'CALL', 'CALLCODE', 'RETURN', 'DELEGATECALL', 'STATICCALL', 'REVERT'},
            'block': {'BLOCKHASH', 'COINBASE', 'TIMESTAMP', 'NUMBER', 'DIFFICULTY', 'GASLIMIT'},
            'environment': {'ADDRESS', 'BALANCE', 'ORIGIN', 'CALLER', 'CALLVALUE', 'CALLDATALOAD', 'CALLDATASIZE', 'CODESIZE', 'GASPRICE'}
        }

        total_ops = len(cleaned_opcodes)
        for category, ops in opcode_categories.items():
            count = sum(1 for op in cleaned_opcodes if any(o in op for o in ops))
            features[f'{category}_ratio'] = count / total_ops if total_ops > 0 else 0

        # Combine all features
        features.update(block_features)
        
        # Ensure 25 features in fixed order
        feature_keys = [
            'num_nodes', 'num_edges', 'max_in_degree', 'max_out_degree',
            'avg_in_degree', 'avg_out_degree', 'density', 'clustering_coefficient',
            'arithmetic_ratio', 'bitwise_ratio', 'comparison_ratio',
            'memory_ratio', 'storage_ratio', 'control_ratio',
            'stack_ratio', 'system_ratio', 'block_ratio', 'environment_ratio',
            # Additional derived features
            'jumps_to_pushes_ratio',
            'calls_ratio',
            'storage_to_memory_ratio',
            'avg_block_depth',
            'cyclomatic_complexity',
            'halstead_difficulty',
            'maintainability_index'
        ]
        
        # Calculate additional metrics
        features['jumps_to_pushes_ratio'] = features['control_ratio'] / features['stack_ratio'] if features['stack_ratio'] > 0 else 0
        features['calls_ratio'] = features['system_ratio']
        features['storage_to_memory_ratio'] = features['storage_ratio'] / features['memory_ratio'] if features['memory_ratio'] > 0 else 0
        features['avg_block_depth'] = block_features['avg_in_degree']
        features['cyclomatic_complexity'] = len([op for op in cleaned_opcodes if op in {'JUMPI', 'REVERT'}]) + 1
        features['halstead_difficulty'] = (features['arithmetic_ratio'] + features['bitwise_ratio']) * len(set(cleaned_opcodes))
        features['maintainability_index'] = 100 - (features['cyclomatic_complexity'] * features['density'] * 100)

        # Create feature vector with fixed dimensionality
        feature_array = np.array([features.get(k, 0.0) for k in feature_keys])
        return feature_array

    except Exception as e:
        st.error(f"Feature extraction error: {str(e)}")
        return None

def main():
    st.set_page_config(
        page_title="Cerberus | Smart Contract Security Analyzer",
        page_icon="🛡️",
        layout="wide"
    )

    # Custom CSS
    st.markdown("""
        <style>
        .main-header {
            color: #FF4B4B;
            font-size: 2.5rem;
            font-weight: bold;
            margin-bottom: 2rem;
        }
        .vulnerability-critical {
            color: #FF0000;
            font-weight: bold;
        }
        .vulnerability-high {
            color: #FF4B4B;
            font-weight: bold;
        }
        .vulnerability-medium {
            color: #FFA500;
            font-weight: bold;
        }
        </style>
    """, unsafe_allow_html=True)

    st.markdown("<h1 class='main-header'>🛡️ Cerberus Smart Contract Analyzer</h1>", unsafe_allow_html=True)
    st.markdown("### Detect vulnerabilities in your Solidity smart contracts")

    analyzer = CerberusAnalyzer()
    
    # # Settings sidebar
    # with st.sidebar:
    #     st.header("⚙️ Analysis Settings")
        # optimization = st.checkbox("Enable Optimization", value=True)
        # solc_version = st.selectbox("Solidity Version", ["0.4.26", "0.4.25", "0.4.24"])

    uploaded_file = st.file_uploader(
        "Upload Solidity Contract",
        type=["sol"],
        help="Upload a Solidity smart contract file for analysis"
    )

    if uploaded_file:
        source_code = uploaded_file.getvalue().decode("utf-8")
        col1, col2 = st.columns([1, 1])

        with col1:
            st.markdown("### 📝 Source Code")
            st.code(source_code, language="solidity")

        if st.button("🔍 Analyze Contract"):
            with st.spinner("Analyzing smart contract..."):
                try:
                    compiled_sol = analyzer.compile_contract(source_code, True)

                    if compiled_sol:
                        contract_id, contract_interface = compiled_sol.popitem()
                        bytecode = contract_interface["bin"]
                        abi = contract_interface["abi"]

                        with col2:
                            st.markdown("### 🎯 Analysis Results")
                            
                            contract_info = {
                                "Contract Name": Path(uploaded_file.name).stem,
                                "Size (bytes)": len(bytecode) // 2,
                                "Functions": len([x for x in abi if x["type"] == "function"])
                            }
                            st.json(contract_info)

                            st.write("Analyzing bytecode...")  # Debug log
                            result = analyzer.predict_vulnerabilities(bytecode)
                            
                            if result:
                                if result.get("is_clean", False):
                                    st.success("✅ No vulnerabilities detected")
                                    st.markdown(f"""
                                        #### Analysis Results
                                        - Status: Clean Contract
                                        - Confidence: {result['confidence']:.2%}
                                    """)
                                else:
                                    severity_class = f"vulnerability-{result['severity'].lower()}"
                                    st.markdown(f"""
                                        #### Detected Vulnerability
                                        - Type: <span class='{severity_class}'>{result['vulnerability_type']}</span>
                                        - Severity: <span class='{severity_class}'>{result['severity']}</span>
                                        - Confidence: {result['confidence']:.2%}
                                    """, unsafe_allow_html=True)

                                    st.markdown("#### Vulnerability Probabilities")
                                    for vuln_type, prob in result['probabilities'].items():
                                        st.write(f"- {vuln_type}: {prob:.2%}")
                            else:
                                st.error("No results generated from analysis")
            
                except Exception as e:
                    st.error("Analysis failed")
                    st.exception(e)

if __name__ == "__main__":
    main()