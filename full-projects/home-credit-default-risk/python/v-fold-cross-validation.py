import numpy as np
import statsmodels.api as sm

def run_logit(X, Y):
    log_reg = sm.Logit()

def cross_validate(df_preds, df_target, folds):
    fold_vals = list(range(1, folds + 1))
    rand_folds = np.random.choice(fold_vals, size=df_preds.shape[0], replace = True)

    df_preds = df_preds.assign(fold = rand_folds)
    df_target = df_target.assign(fold = rand_folds)

    for fold in fold_vals:
        idx = df_folds["fold"] == fold

        # Train Model
        train_x = df_preds.loc[:,-idx]
        train_y = df_target.loc[:,idx]
        log_reg = sm.Logit(train_y, train_x).fit()

        # Test Model

        print(test.head())
        print(train.head())


#cross_validate(app_docs, 5)