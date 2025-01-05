import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
import numpy as np
import json
import os
from tqdm import tqdm
from sklearn.metrics import classification_report


class OpcodesDataset(Dataset):
    def __init__(self, features, labels, max_length=500):
        self.features = features
        self.labels = labels
        self.max_length = max_length

        # Create vocabulary from the features
        self.vocab = self._create_vocabulary()

    def _create_vocabulary(self):
        # Create a set of all unique tokens from numeric features
        vocab = set()
        for feature_dict in self.features:
            # Extract all numeric values as tokens
            tokens = [
                str(v) for v in feature_dict.values() if isinstance(v, (int, float))
            ]
            vocab.update(tokens)
        return {token: idx + 1 for idx, token in enumerate(sorted(vocab))}

    def __getitem__(self, idx):
        feature_dict = self.features[idx]
        label = self.labels[idx]

        # Convert numeric features to a sequence
        numeric_features = [
            v for v in feature_dict.values() if isinstance(v, (int, float))
        ]
        feature_tokens = [str(v) for v in numeric_features]

        # Convert tokens to indices and pad/truncate
        indices = [
            self.vocab.get(token, 0) for token in feature_tokens[: self.max_length]
        ]
        indices = indices + [0] * (self.max_length - len(indices))

        return {
            "input_ids": torch.tensor(indices, dtype=torch.long),
            "label": torch.tensor(label, dtype=torch.long),
        }

    def __len__(self):
        return len(self.features)


# 2. Update the BiLSTM model for our feature dimensions
class BiLSTMClassifier(nn.Module):
    def __init__(
        self,
        vocab_size,
        embedding_dim,
        hidden_dim,
        num_classes,
        num_layers=2,
        dropout=0.2,
    ):
        super().__init__()

        self.embedding = nn.Embedding(vocab_size, embedding_dim, padding_idx=0)
        self.lstm = nn.LSTM(
            embedding_dim,
            hidden_dim,
            num_layers=num_layers,
            bidirectional=True,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0,
        )
        self.dropout = nn.Dropout(dropout)
        self.fc = nn.Linear(hidden_dim * 2, num_classes)

    def forward(self, x):
        embedded = self.embedding(x)
        lstm_out, _ = self.lstm(embedded)

        # Global max pooling
        pooled = torch.max(lstm_out, dim=1)[0]
        dropped = self.dropout(pooled)
        output = self.fc(dropped)
        return output


# 3. Update the training function
def train_bilstm_model(
    X_train, X_val, X_test, y_train, y_val, y_test, output_dir="bilstm_artifacts"
):
    # Create output directory
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Convert lists to proper format if needed
    X_train = [dict(x) for x in X_train]
    X_val = [dict(x) for x in X_val]
    X_test = [dict(x) for x in X_test]

    # Create datasets
    train_dataset = OpcodesDataset(X_train, y_train)
    val_dataset = OpcodesDataset(X_val, y_val)
    test_dataset = OpcodesDataset(X_test, y_test)

    # Create dataloaders
    train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=32)
    test_loader = DataLoader(test_dataset, batch_size=32)

    # Initialize model
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model = BiLSTMClassifier(
        vocab_size=len(train_dataset.vocab) + 1,
        embedding_dim=64,
        hidden_dim=128,
        num_classes=3,
    ).to(device)

    # Define loss function and optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

    # Training loop
    num_epochs = 10
    best_val_loss = float("inf")

    for epoch in range(num_epochs):
        # Training phase
        model.train()
        train_loss = 0
        train_correct = 0
        train_total = 0

        for batch in tqdm(train_loader, desc=f"Epoch {epoch+1}/{num_epochs}"):
            input_ids = batch["input_ids"].to(device)
            labels = batch["label"].to(device)

            # Forward pass
            outputs = model(input_ids)
            loss = criterion(outputs, labels)

            # Backward pass and optimize
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            # Calculate accuracy
            _, predicted = torch.max(outputs.data, 1)
            train_total += labels.size(0)
            train_correct += (predicted == labels).sum().item()
            train_loss += loss.item()

        # Validation phase
        model.eval()
        val_loss = 0
        val_correct = 0
        val_total = 0

        with torch.no_grad():
            for batch in val_loader:
                input_ids = batch["input_ids"].to(device)
                labels = batch["label"].to(device)

                outputs = model(input_ids)
                loss = criterion(outputs, labels)

                _, predicted = torch.max(outputs.data, 1)
                val_total += labels.size(0)
                val_correct += (predicted == labels).sum().item()
                val_loss += loss.item()

        # Calculate epoch metrics
        train_loss = train_loss / len(train_loader)
        train_acc = 100 * train_correct / train_total
        val_loss = val_loss / len(val_loader)
        val_acc = 100 * val_correct / val_total

        print(f"\nEpoch {epoch+1}/{num_epochs}:")
        print(f"Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}%")
        print(f"Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.2f}%")

        # Save best model
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(
                {
                    "epoch": epoch,
                    "model_state_dict": model.state_dict(),
                    "optimizer_state_dict": optimizer.state_dict(),
                    "val_loss": val_loss,
                },
                os.path.join(output_dir, "best_model.pt"),
            )

    # Test phase
    model.eval()
    test_correct = 0
    test_total = 0
    all_preds = []
    all_labels = []

    with torch.no_grad():
        for batch in test_loader:
            input_ids = batch["input_ids"].to(device)
            labels = batch["label"].to(device)

            outputs = model(input_ids)
            _, predicted = torch.max(outputs.data, 1)

            test_total += labels.size(0)
            test_correct += (predicted == labels).sum().item()

            all_preds.extend(predicted.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    test_acc = 100 * test_correct / test_total
    print(f"\nTest Accuracy: {test_acc:.2f}%")

    # Save classification report
    report = classification_report(all_labels, all_preds, output_dict=True)
    with open(os.path.join(output_dir, "classification_report.json"), "w") as f:
        json.dump(report, f, indent=4)

    # Save vocabulary
    with open(os.path.join(output_dir, "vocab.json"), "w") as f:
        json.dump(train_dataset.vocab, f, indent=4)

    return model, train_dataset.vocab


# Run the training
try:
    print("\nStarting BiLSTM model training...")
    print(
        f"Using device: {torch.device('cuda' if torch.cuda.is_available() else 'cpu')}"
    )

    # Convert features to list of dicts if needed
    X_train = [dict(x) for x in X_train]
    X_val = [dict(x) for x in X_val]
    X_test = [dict(x) for x in X_test]

    model, vocab = train_bilstm_model(X_train, X_val, X_test, y_train, y_val, y_test)

    print("\nTraining completed successfully!")

except Exception as e:
    print(f"An error occurred during training: {str(e)}")
    raise  # This will show the full traceback
