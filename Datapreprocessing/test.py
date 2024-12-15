from sklearn.svm import SVC
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import GridSearchCV, learning_curve
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import classification_report, confusion_matrix
import numpy as np
import plotly.graph_objects as go
import plotly.express as px
import plotly.figure_factory as ff
import warnings
import pandas as pd
import os

# Suppress all warnings
warnings.filterwarnings('ignore')

# First, vectorize the features
vec = DictVectorizer(sparse=True)
X_train_vec = vec.fit_transform(X_train)
X_test_vec = vec.transform(X_test)

# Create pipeline with scaling and SVM
scaler = StandardScaler(with_mean=False)
svc_pipeline = make_pipeline(
    scaler,
    SVC(random_state=42, probability=True)
)

# Define parameter grid for tuning
param_grid = {
    'svc__C': [0.1, 1, 10, 100],
    'svc__kernel': ['rbf', 'linear'],
    'svc__gamma': ['scale', 'auto', 0.1, 0.01, 0.001],
    'svc__class_weight': ['balanced', None]
}

# Create and fit GridSearchCV
grid_search = GridSearchCV(
    estimator=svc_pipeline,
    param_grid=param_grid,
    cv=5,
    n_jobs=-1,
    scoring='f1_macro',
    verbose=2,
    return_train_score=True,
    error_score='raise'
)

# Fit the model
with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    grid_search.fit(X_train_vec, y_train)

# 1. Compare Training and Validation Scores
results = pd.DataFrame(grid_search.cv_results_)
results = results.sort_values('rank_test_score')

print("\nBest parameters:", grid_search.best_params_)
print("Best cross-validation score:", grid_search.best_score_)
print("\nBest model scores:")
print(f"Training score: {grid_search.score(X_train_vec, y_train):.4f}")
print(f"Test score: {grid_search.score(X_test_vec, y_test):.4f}")
charts_dir = "charts"
os.makedirs(charts_dir, exist_ok=True)
# 2. Plot Learning Curves using Plotly
def plot_learning_curves(estimator, X, y):
    train_sizes, train_scores, val_scores = learning_curve(
        estimator, X, y,
        train_sizes=np.linspace(0.1, 1.0, 10),
        cv=5,
        n_jobs=-1,
        scoring='f1_macro'
    )
    
    train_mean = np.mean(train_scores, axis=1)
    train_std = np.std(train_scores, axis=1)
    val_mean = np.mean(val_scores, axis=1)
    val_std = np.std(val_scores, axis=1)
    
    fig = go.Figure()
    
    # Add training score
    fig.add_trace(go.Scatter(
        x=train_sizes,
        y=train_mean,
        name='Training Score',
        line=dict(color='blue'),
        mode='lines'
    ))
    
    # Add training score error bands
    fig.add_trace(go.Scatter(
        x=np.concatenate([train_sizes, train_sizes[::-1]]),
        y=np.concatenate([train_mean + train_std, (train_mean - train_std)[::-1]]),
        fill='toself',
        fillcolor='rgba(0,0,255,0.1)',
        line=dict(color='rgba(255,255,255,0)'),
        name='Training Score Std'
    ))
    
    # Add validation score
    fig.add_trace(go.Scatter(
        x=train_sizes,
        y=val_mean,
        name='Cross-validation Score',
        line=dict(color='red'),
        mode='lines'
    ))
    
    # Add validation score error bands
    fig.add_trace(go.Scatter(
        x=np.concatenate([train_sizes, train_sizes[::-1]]),
        y=np.concatenate([val_mean + val_std, (val_mean - val_std)[::-1]]),
        fill='toself',
        fillcolor='rgba(255,0,0,0.1)',
        line=dict(color='rgba(255,255,255,0)'),
        name='Cross-validation Score Std'
    ))
    
    fig.update_layout(
        title='Learning Curves',
        xaxis_title='Training Examples',
        yaxis_title='F1 Score',
        showlegend=True,
        template='plotly_white'
    )
    
    # Save the figure
    fig.write_html(os.path.join(charts_dir, "learning_curves.html"))
    fig.show()

# Plot learning curves for the best model
best_model = grid_search.best_estimator_
plot_learning_curves(best_model, X_train_vec, y_train)

# 3. Print detailed classification report
y_pred = grid_search.predict(X_test_vec)
print("\nClassification Report:")
print(classification_report(y_test, y_pred))

# 4. Plot confusion matrix using Plotly
cm = confusion_matrix(y_test, y_pred)
labels = sorted(y_test.unique())

fig = go.Figure(data=go.Heatmap(
    z=cm,
    x=labels,
    y=labels,
    text=cm,
    texttemplate="%{text}",
    textfont={"size": 16},
    hoverongaps=False,
    colorscale='Blues'
))

fig.update_layout(
    title='Confusion Matrix',
    xaxis_title='Predicted Label',
    yaxis_title='True Label',
    xaxis=dict(tickmode='array', ticktext=labels, tickvals=labels),
    yaxis=dict(tickmode='array', ticktext=labels, tickvals=labels),
    width=600,
    height=600,
)

# Save the confusion matrix
fig.write_html(os.path.join(charts_dir, "confusion_matrix.html"))
fig.show()

# 5. Plot Parameter Comparison (new visualization)
param_comparison = results[['params', 'mean_test_score']].head(10)
param_comparison['param_string'] = param_comparison['params'].apply(
    lambda x: f"C={x['svc__C']}, kernel={x['svc__kernel']}, gamma={x['svc__gamma']}"
)

fig = px.bar(
    param_comparison,
    x='param_string',
    y='mean_test_score',
    title='Top 10 Parameter Combinations',
    labels={
        'param_string': 'Parameters',
        'mean_test_score': 'Mean Test Score'
    }
)

fig.update_layout(
    xaxis_tickangle=-45,
    showlegend=False,
    template='plotly_white'
)

# Save the parameter comparison
fig.write_html(os.path.join(charts_dir, "parameter_comparison.html"))
fig.show()

# Save the model
joblib.dump(grid_search, 'svm_model.joblib')

# To save as static images, first install:
# pip install -U kaleido

# Then use:
fig.write_image(os.path.join(charts_dir, "learning_curves.png"))
fig.write_image(os.path.join(charts_dir, "confusion_matrix.png"))
fig.write_image(os.path.join(charts_dir, "parameter_comparison.png"))