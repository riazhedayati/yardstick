context("metrics() and metric_set()")

library(testthat)
library(yardstick)
library(dplyr)

set.seed(1311)
three_class <- data.frame(obs = iris$Species,
                          pred = sample(iris$Species, replace = TRUE))
probs <- matrix(runif(150 * 3), nrow = 150)
probs <- t(apply(probs, 1, function(x) x/sum(x)))
colnames(probs) <- levels(iris$Species)
three_class <- cbind(three_class, as.data.frame(probs))


###################################################################

test_that('correct metrics returned', {
  expect_equal(
    metrics(two_class_example, truth, predicted)[[".metric"]],
    c("accuracy", "kap")
  )
  expect_equal(
    metrics(two_class_example, truth, predicted, Class1)[[".metric"]],
    c("accuracy", "kap", "mn_log_loss", "roc_auc")
  )
  expect_equal(
    metrics(three_class, "obs", "pred", setosa, versicolor, virginica)[[".metric"]],
    c("accuracy", "kap", "mn_log_loss", "roc_auc")
  )
  expect_equal(
    metrics(three_class, "obs", "pred", setosa, versicolor, virginica)[[".estimator"]],
    c("multiclass", "multiclass", "multiclass", "hand_till")
  )
  expect_equal(
    metrics(solubility_test, solubility, "prediction")[[".metric"]],
    c("rmse", "rsq", "mae")
  )
})

###################################################################

test_that('bad args', {
  expect_error(
    metrics(two_class_example, truth, Class1)
  )
  expect_error(
    metrics(two_class_example, Class1, truth)
  )
  expect_error(
    metrics(three_class, "obs", "pred", setosa, versicolor)
  )
})

###################################################################

class_res_1 <- bind_rows(
  accuracy(two_class_example, truth, predicted),
  kap(two_class_example, truth, predicted),
  mn_log_loss(two_class_example, truth, Class1),
  roc_auc(two_class_example, truth, Class1)
)

reg_res_1 <- bind_rows(
  rmse(solubility_test, solubility, "prediction"),
  rsq(solubility_test, solubility, prediction),
  mae(solubility_test, solubility, prediction)
)


test_that('correct results', {

  class_idx <- which(class_res_1$.metric %in% c("accuracy", "kap"))

  expect_equal(
    metrics(two_class_example, truth, predicted)[[".estimate"]],
    class_res_1[class_idx,][[".estimate"]]
  )
  expect_equal(
    metrics(two_class_example, truth, predicted, Class1)[[".estimate"]],
    class_res_1[[".estimate"]]
  )
  expect_equal(
    metrics(solubility_test, solubility, prediction)[[".estimate"]],
    reg_res_1[[".estimate"]]
  )
})

###################################################################

test_that('numeric metric sets', {

  reg_set <- metric_set(rmse, rsq, mae)

  expect_equal(
    reg_set(solubility_test, solubility, prediction),
    reg_res_1
  )
  # ensure helpful messages are printed
  expect_error(
    metric_set(rmse, "x")
  )

  # Can mix class and class prob together
  mixed_set <- metric_set(accuracy, roc_auc)
  expect_error(
    mixed_set(two_class_example, truth, Class1, estimate = predicted),
    NA
  )
})

test_that('mixing bad metric sets', {
  expect_error(
    metric_set(rmse, accuracy)
  )
})

test_that('can mix class and class prob metrics together', {
  expect_error(
    mixed_set <- metric_set(accuracy, roc_auc),
    NA
  )
  expect_error(
    mixed_set(two_class_example, truth, Class1, estimate = predicted),
    NA
  )
})
