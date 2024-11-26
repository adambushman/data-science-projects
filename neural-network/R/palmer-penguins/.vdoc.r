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
#
#
#
library('tidyverse')        # Wrapper for many convenient libraries
library('tidymodels')       # Wrapper for modeling libraries
library('modeldata')        # Contains data for the assignment
library('skimr')            # Quickly summarise data
library('gt')               # Render "great tables"

library('nnet')             # Loading neural network library
library('VIM')              # Nearest neighbors imputation
library('scutr')             # Library for generating a balanced data set w/ SMOTE
library('caret')            # Miscellaneous modeling functions
#
#
#
#
#
#
#
peng_raw <- modeldata::penguins        # Data for the assignment
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
#| include: false

peng_data_dict <- tibble(
    variable = c("species", "island", "bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g", "sex"), 
    datatype = c("<factor>", "<factor>", "<numeric>", "<numeric>", "<integer>", "<integer>", "<factor>"), 
    description = c(
        "Penguin species (Adelie, Chinstrap, Gentoo)", 
        "Island in Palmer Archipelago, Antartica (biscoe, Dream, or Torgerssen)", 
        "Bill length (millimeters)", 
        "Bill depth (millimeters)", 
        "Flipper length (millimeters)", 
        "Body mass (grams)", 
        "Penguin sex (female, male)"
    )
)
#
#
#
#
#| html-table-processing: none

gt(peng_data_dict) %>%                                  # Create a "great tables" (gt) object
    cols_label(                                         # Rename some columns
        variable = "Variable Name", 
        datatype = "Data Type", 
        description = "Variable Description"
    ) %>%
    tab_options(
        column_labels.background.color = "#d9230f",     # Apply red header background
        column_labels.font.weight = "bold",             # Bold headers
        row.striping.background = '#FFFFFF'             # Remove row striping
    )
```
#
#
#
#
#
skim(peng_raw)
```
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
#
#
#
#
#
#
#
#
#
peng_imputed <- kNN(
    peng_raw, 
    variable = c("sex", "bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g"), 
    k = 5
)
#
#
#
#
#
sapply(peng_imputed, function(x) sum(is.na(x))) 
#
#
#
#
#
get_imputed <- function(x) {
    peng_imputed |> 
        filter({{ x }}) |>
        select(-c(sex_imp:body_mass_g_imp))
}
#
#
#
print(get_imputed(sex_imp))
#
#
#
#
#
print(get_imputed(bill_length_mm_imp))
#
#
#
#
#
#
#
#
#
set.seed(819)                                           # Set reproducible seed
idx = createDataPartition(                              # Creat particion for the SMOTE data
    peng_imputed$species, 
    p = 0.7, 
    list = FALSE
)
peng_smote_test_imb <- peng_imputed[-idx,]              # Imbalanced testing data
peng_smote_train_imb <- peng_imputed[idx,]              # Imbalanced training data
#
#
#
#
#
#
#
peng_train_dmy <- dummyVars("~ . -species", peng_smote_train_imb)
peng_train_data_dmy <- data.frame(predict(peng_dmy, peng_smote_train_imb))
peng_test_dmy <- dummyVars("~ . -species", peng_smote_test_imb)
peng_test_data_dmy <- data.frame(predict(peng_dmy, peng_smote_test_imb)) |>
    mutate(species = peng_smote_test_imb$species)

peng_smote_train_bal <- SCUT(
    peng_data_dmy |> mutate(species = peng_smote_train_imb$species), 
    "species", 
    undersample = undersample_kmeans, 
    usamp_opts = list(k = 7)
)
#
#
#
table(peng_smote_train_bal$species) |> prop.table()
#
#
#
#
#
smote_data <- peng_smote_train_bal |> bind_rows(peng_test_data_dmy)

smote_split <- manual_rset(
    splits = list(make_splits(list(
        analysis = 1:nrow(peng_smote_train_bal),
        assessment = (nrow(peng_smote_train_bal)+1):nrow(smote_data)),
        data = smote_data
    )), 
    ids = "SMOTE_Split"
)
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
split_obj <- initial_split(peng_imputed, prop = 0.75)              # Split object

peng_train <- training(split_obj)                                # Split for training
peng_test <- testing(split_obj)                                  # Split for testing
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
preg_recipe <- recipe(species ~ ., peng_train) |>
    step_dummy(island, sex)
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
peng_tune_grid <- grid_regular(
    hidden_units(), 
    penalty(), 
    epochs(), 
    levels = 4
)

head(peng_tune_grid)
tail(peng_tune_grid)
#
#
#
#
#
peng_folds <- rsample::vfold_cv(peng_train, v = 5)
#
#
#
#
#
#
#
nn_mod01 <- mlp(
    hidden_units = tune(), 
    penalty = tune(), 
    epochs = tune()
) |>
    set_engine("nnet") |>
    set_mode("classification")

nn_mod01 |> translate()
#
#
#
#
#
#
#
#
#
peng_wflw <-
    workflow() |>
    add_model(nn_mod01) |>
    add_recipe(preg_recipe)
#
#
#
#
#
doParallel::registerDoParallel(cores = 3)

set.seed(2015)
peng_tune <-
    peng_wflw |>
    tune_grid(
        resamples = peng_folds, 
        grid = peng_tune_grid, 
        metrics = metric_set(roc_auc)
    )
#
#
#
#
#
#
#
results_tune <- collect_metrics(peng_tune) |> arrange(mean)

head(results_tune)
tail(results_tune)
#
#
#
ggplot(
    results_tune |> 
        pivot_longer(
            c(hidden_units:epochs)
        ), 
    aes(value, mean)
) +
    geom_line() + 
    geom_point() +
    facet_wrap(~name, nrow = 1, scales = "free")
#
#
#
#
peng_best <- peng_tune |> select_best(metric = "roc_auc")
peng_best
#
#
#
#
#
preg_recipe_02 <- recipe(species ~ ., peng_smote_train_bal)

nn_mod02 <- mlp(
    hidden_units = 7, 
    penalty = 0.000464, 
    epochs = 340
) |>
    set_engine("nnet") |>
    set_mode("classification")

peng_wflw_02 <-
    workflow() |>
    add_model(nn_mod02) |>
    add_recipe(preg_recipe_02)
#
#
#
#
doParallel::registerDoParallel(cores = 3)

results <- fit_resamples(
    peng_wflw_02, 
    resamples = smote_split, 
    metrics = metric_set(roc_auc)
)
#
#
#
#
collect_metrics(results)
#
#
#
