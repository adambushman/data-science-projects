# type: ignore
# flake8: noqa
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

# Loading libraries
import pandas as pd
import numpy as np
from sklearn import tree
from pandas_summary import DataFrameSummary

# Load data into session
cancer = pd.read_csv("breast-cancer-dataset.csv")

#
#
#
#
#

# Understand fields
cancer_summary = DataFrameSummary(cancer)
cancer_summary.summary()

#
#
#
#
#

cancer.columns = ["Pat_Id", "Year", "Age", "Menopause", "Tumor_Size_Cm", "Inv_Nodes", "Breast", "Metastasis", "Breast_Quadrant", "History", "Diagnosis_Result"]

def replace_hash(col):
    return col.replace("#",np.nan)

cancer_clean = cancer.apply(replace_hash, axis=0)

cancer_clean["Tumor_Size_Cm"] = cancer_clean["Tumor_Size_Cm"].apply(pd.to_numeric)

# There are "#" codes in the data to figure out...

#
#
#
#
#
#

# Defining a split

# Training and testing sets

#
#
#
#
#

# Model

# Recipe

# Workflow

#
#
#
#
#

# Tuning grid

# Setting up the tuning

#
#
#
#
#
#

# Extracting results from the tuned grid

# Plot accuracy metric

#
#
#
#
#

# Official model

# Official workflow

# Fitting the training data

#
#
#
#
#

# Predicting the testing data based on training

# Assembling results 

# Comparing results

#
#
#
#
