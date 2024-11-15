#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
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

library('dataPreparation')  # Utilities for PCA prep 

#
#
#
#
#
#
#

ad_raw <- modeldata::ad_data        # Data for the assignment

#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
skim(ad_raw)
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
ad_numeric <- ad_raw |> select(where(is.numeric))
#
#
#
scale_obj <- build_scales(data_set = ad_numeric)
ad_scaled <- fast_scale(data_set = ad_numeric, scales = scale_obj, verbose = TRUE)
#
#
#
#
#
ad_cov <- cov(ad_scaled)
ad_eig <- eigen(ad_cov)

ad_eig_val <- ad_eig$values
ad_eig_vec <- ad_eig$vectors
#
#
#
var_expl <- round(ad_eig_val / sum(ad_eig_val), 3)
cum_var_expl <- cumsum(var_expl)
#
#
#
pca_results <- data.frame(
    var = cum_var_expl, 
    idx = 1:length(cum_var_expl)
)

thresh <- c(0.5, 0.75, 0.9, 0.95)
idx <- sapply(thresh, function(t) which.min(abs(cum_var_expl - t)))

pca_thresh <- data.frame(thresh, idx)
#
#
#
ggplot() +
    geom_area(aes(x = idx, y = var), pca_results, fill = "#E2E6E6") +
    geom_vline(aes(xintercept = idx), pca_thresh, color = "#BE0000") +
    geom_label(
        aes(
            x = idx, y = thresh, 
            label = stringr::str_wrap(
                paste("First", idx, "of", length(cum_var_expl), "principal components explain", thresh * 100, "% of overall variance"), 20
            )
        ), 
        pca_thresh, 
        color = "#BE0000"
    ) +
    scale_y_continuous(expand = expansion(mult = c(0,.05))) +
    labs(
        title = "Cumulative variance explained by first X principal component(s)", 
        subtitle = paste0("A summary of PCA results compared to original column dimensions (", length(cum_var_expl), ")"), 
        x = "Principal Component Index", 
        y = "% of Variance Explained"
    ) +
    theme_minimal()
#
#
#
#
#
#
#
#
#

set.seed(819)                                                   # Set reproducible seed
split_obj <- initial_split(sac_clean, prop = 0.75)              # Split object

sac_train <- training(split_obj)                                # Split for training
sac_test <- testing(split_obj)                                  # Split for testing

#
#
#
#
#
#
#
#
#
#

nFolds <- 10
foldid <- sample(rep(seq(nFolds), length.out = nrow(sac_train)))        # Randomize folds

model_fit <- cv.glmnet(                                                 # Run elastic net
    x = sac_train %>% select(-price_log) %>% data.matrix(),             # Predictors
    y = sac_train$price_log,                                            # Target
    family = "gaussian",                                                # Regression specification
    type.measure = "mse",                                               # Measure of interest
    nfolds = nFolds,                                                    # Number of cross-validation folds
    foldid = foldid                                                     # Reproducible folds
)

#
#
#
#
#
#
#
#

model_fit

#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

plot(model_fit)

#
#
#
#
#
#
#

coef(model_fit, s = "lambda.1se")

#
#
#
#
#
#
#
#
#
#
#
#
#
#

sac_pred <- predict(                            # Make predictions
    model_fit,                                  # Original fit from above
    newx = sac_test %>%                         # Using the testing data we haven't worked with yet
        select(-price_log) %>% 
        data.matrix(),
    s = "lambda.1se"                            # Use the penalty within 1 standard error
)

head(sac_pred)

#
#
#
#
#
#
#
#
#

sac_test_r <-                                   
    sac_test %>%
    mutate(                                                     # Transform data back into natural scale
        .pred = sac_pred[,1],                                   # Predicted value (log)
        .pred_n = exp(.pred),                                   # Predicted value (natural)
        sqft = exp(sqft_log),                                   # Sqft (natural)
        price = exp(price_log),                                 # Sales price (natural)
        diff = .pred_n - price                                  # Difference in price (natural)
    )


mean((sac_test_r$.pred - sac_test_r$price_log)^2)               # Calculate mean squared error on log scale

#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

sac_test_r %>%                                                          # Using the test data
    arrange(desc(diff)) %>%                                             # Sort by the difference
    select(city:type, sqft, price, .pred_n, diff) %>%                   # Select relevant columns
    head(10) %>%                                                        # Top-10 property values
    gt() %>%                                                            # Create a "great tables" object
    cols_label(                                                         # Add column labes
        city = "City", 
        zip = "Zip Code", 
        beds = "Bedroom No", 
        baths = "Bathroom No", 
        type = "Property Type", 
        sqft = "Square Feet", 
        price = "Sales Price", 
        .pred_n = "Predicted Price", 
        diff = "Modeled Value"
    ) %>%
    fmt_number(                                                         # Format sqft for decimals
        columns = c(sqft), 
        decimals = 0
    ) %>%
    fmt_currency(                                                       # Format pricing data for currency
        columns = c(price, .pred_n, diff), 
        decimals = 0, 
        suffixing = TRUE
    ) %>%
    tab_options(                                                        # Format the column headers
        column_labels.background.color = "#BE0000"
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

sac_map <-                                                              
    leaflet(height = 800, width = 800) %>%                              # Create a leaflet map object
    addTiles() %>%                                                      # Setup tile layer
    setView(lng = -121.478851, lat = 38.575764, zoom = 10)              # Localize zoom to Sacramento, CA

sac_map <- 
    sac_map %>%
    addProviderTiles("CartoDB.Positron") %>%                            # Use a grayscale map theme
    addCircleMarkers(                                                   # Add a circle point for every property
        data = sac_test_r %>% arrange(desc(diff)) %>% head(30),         # Top-30, high value properties
        lng = ~longitude,                                               # Mapped values
        lat = ~latitude,                                                # Mapped values
        radius = 6, 
        color = "#BE0000", 
        fillOpacity = 0.5
    )

sac_map

```
#
#
#
