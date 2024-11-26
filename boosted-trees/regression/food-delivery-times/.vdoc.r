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
library('modeldata')        # Contains data for the assignment
library('skimr')            # Quickly summarise data
library('gt')               # Render "great tables"

library('xgboost')          # Package for leveraging boosted trees
library('tidymodels')       # Wrapper for convenient modeling framework
library('vip')              # Generating important feature plots
#
#
#
#
#
#
#
delivery_raw <- modeldata::deliveries       # Data for the assignment
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

dict_list <- list(
    list(variable = "time_to_delivery", datatype = "<numeric>", description = "Time from the initial order to receiving the food in minutes"), 
    list(variable = "hour", datatype = "<numeric>", description = "The time, in decimal hours, of the order"), 
    list(variable = "day", datatype = "<factor>", description = "The day of the week for the order"),  
    list(variable = "distance", datatype = "<numeric>", description = "The approximate distance in miles between the restaurant and the delivery location."),  
    list(variable = "item_##", datatype = "<integer>", description = "A set of 27 predictors that count the number of distinct menu items in the order") 
)

delivery_dict <- do.call(rbind, lapply(dict_list, as.data.frame))
#
#
#
#
#| html-table-processing: none

gt(delivery_dict) %>%                                   # Create a "great tables" (gt) object
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
skim(delivery_raw)
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
delivery_raw |>
    pivot_longer(
        cols = tidyr::starts_with("item"), 
        names_to = "item", 
        values_to = "quantity"
    ) |>
    filter(quantity != 0) |>
    group_by(item) |>
    summarise(stats = list(summary(time_to_delivery))) |>
    tidyr::unnest_wider(stats) |>
    mutate(Range = Max. - Min.) |>
    arrange(desc(Range)) |>
    gt() |>
    cols_label(                                                         # Rename some columns
        item = "Menu Item", 
        `1st Qu.` = "1st Quartile", 
        `3rd Qu.` = "3rd Quartile"
    ) %>%
    tab_options(
        column_labels.background.color = "#d9230f",                     # Apply red header background
        column_labels.font.weight = "bold",                             # Bold headers
        row.striping.background = '#FFFFFF'                             # Remove row striping
    )
```
#
#
#
#
#
#
#
delivery_raw |>
    mutate(total_qty = rowSums(across(item_01:item_27))) |>
    
    ggplot(aes(total_qty, time_to_delivery)) +
    geom_jitter(color = '#BE0000') + 
    labs(
        title = "Relationship between order quantity and delivery time", 
        x = "Total Quantity", 
        y = "Delivery Time"
    ) +
    theme_minimal() +
    theme(
        plot.title.position = "plot"
    )
#
#
#
#
#
delivery_raw |>
    mutate(
        total_qty = rowSums(across(item_01:item_27)), 
        distance_bin = cut(distance, 6)
    ) |>
    
    ggplot(aes(total_qty, time_to_delivery)) +
    geom_jitter(color = '#707271') + 
    facet_wrap(~distance_bin, ncol = 2) +
    labs(
        title = "Relationship between order quantity and delivery time", 
        x = "Total Quantity", 
        y = "Delivery Time"
    ) +
    theme_minimal() +
    theme(
        plot.title.position = "plot", 
        panel.background = element_rect(color = "#707271"), 
        strip.background = element_rect(fill = "#BE0000"), 
        strip.text = element_text(color = "white", face = "bold")
    )
#
#
#
#
#
delivery_raw |>
    mutate(
        total_qty = rowSums(across(item_01:item_27))
    ) |>
    
    ggplot(aes(total_qty, time_to_delivery)) +
    geom_jitter(color = '#707271') + 
    facet_wrap(~day, nrow = 2) +
    labs(
        title = "Relationship between order quantity and delivery time", 
        x = "Total Quantity", 
        y = "Delivery Time"
    ) +
    theme_minimal() +
    theme(
        plot.title.position = "plot", 
        panel.background = element_rect(color = "#707271"), 
        strip.background = element_rect(fill = "#BE0000"), 
        strip.text = element_text(color = "white", face = "bold")
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
set.seed(814)                                                               # Set reproducible seed
split_obj <- initial_split(delivery_raw, prop = 0.75)                        # Split object

delivery_train <- training(split_obj)                                          # Split for training
delivery_test <- testing(split_obj)                                            # Split for testing
#
#
#
#
#
#
#
delivery_rec <- recipe(time_to_delivery ~ ., delivery_train) |>
    step_dummy(day)
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
delivery_folds <- rsample::vfold_cv(delivery_train, v = 5)
#
#
#
#
#
#
#
delivery_modl <- boost_tree(
    trees = tune(), 
    tree_depth = tune(), 
    learn_rate = tune(), 
    mtry = tune()
) |>
    set_engine("xgboost", verbosity = 0) |>
    set_mode("regression")
#
#
#
#
#
#
#
#
#
delivery_tune_grid <- grid_regular(
    trees(), 
    tree_depth(), 
    learn_rate(), 
    mtry(c(1, ceiling(sqrt(30)))), 
    levels = 4
)

head(delivery_tune_grid)
tail(delivery_tune_grid)
#
#
#
#
#
#
#
#
#
delivery_wflw <-
    workflow() |>
    add_model(delivery_modl) |>
    add_recipe(delivery_rec)
#
#
#
#
#
doParallel::registerDoParallel(cores = 10)

set.seed(2015)
delivery_tune <-
    delivery_wflw |>
    tune_grid(
        resamples = delivery_folds, 
        grid = delivery_tune_grid, 
        metrics = metric_set(rmse)
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
results_tune <- collect_metrics(delivery_tune) |> arrange(mean)

head(results_tune)
tail(results_tune)
#
#
#
#
#
#
ggplot(
    results_tune |> pivot_longer(
        c(mtry, trees, tree_depth, learn_rate)
    ) |> mutate(mean_bin = cut(mean, 10)), 
    aes(x = value, y = mean, color = mean_bin)
) +
    geom_jitter(size = 5, alpha = 0.25) +
    facet_wrap(~name, scales = "free") +
    labs(
        title = "Boosted trees hyperparameter values", 
        x = "Hyperparameter Value", 
        y = "RMSE", 
        color = "RMSE Group"
    ) +
    theme_minimal() +
    theme(
        plot.title.position = "plot", 
        panel.background = element_rect(color = "#707271"), 
        strip.background = element_rect(fill = "#BE0000"), 
        strip.text = element_text(color = "white", face = "bold"), 
        legend.position = "top", 
        legend.justification.left = "top"
    )
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
best_modl <- delivery_tune |> select_best(metric = "rmse")
#
#
#
#
#
final_wflw <- delivery_wflw |> finalize_workflow(best_modl)
#
#
#
#
#
#
#
#
final_fit <- final_wflw |> last_fit(split = split_obj)
#
#
#
#
#
#
final_fit |> collect_metrics()
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
final_wflw |>
    fit(data = delivery_train) |>
    extract_fit_parsnip() |>
    vip(geom = "col", aesthetics = list(fill = "#BE0000")) +
    labs(
        title = "Important Features of Boosted Trees"
    ) +
    theme_minimal() +
    theme(
        plot.title.position = "plot"
    )
```
#
#
#
#
#
