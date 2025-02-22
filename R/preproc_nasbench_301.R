preproc_data_nb301 = function(config, seed = 123L, n_max = Inf, frac = 0.1) {
  set.seed(seed)
  path = config$data_path
  dt = readRDS(path)

  # Preproc train data
  if (frac) {
    train = dt[method != "rs", ]
  } else {
    train = dt
  }
  train = sample_max(train, n_max)
  train = map_dtc(train, function(x) {
    if (is.logical(x)) x = as.numeric(x)
    if (is.factor(x)) x = fct_drop(fct_explicit_na(x, "None"))
    if (length(unique(x)) == 1) x = NULL
    return(x)
  })
  train[, val_accuracy := val_accuracy / 100]
  trafos = map(train[, "runtime"], scale_base_0_1, base = 1, p = 0)
  train[, names(trafos) := pmap(list(.SD, trafos), function(x, t) {t$trafo(x)}), .SDcols = names(trafos)]
  y = as.matrix(train[, c("val_accuracy", "runtime"), with = FALSE])
  train[, method := NULL]
  train[, runtime := NULL]
  train[, val_accuracy := NULL]

  if (frac) {
    # Preproc test data
    oob = dt[method == "rs", ]
    oob = sample_max(oob, n_max)
    oob = map_dtc(oob, function(x) {
      if (is.logical(x)) x = as.numeric(x)
      if (is.factor(x)) x = fct_drop(fct_explicit_na(x, "None"))
      if (length(unique(x)) == 1) x = NULL
      return(x)
    })
    oob[, val_accuracy := val_accuracy / 100]
    oob[, names(trafos) := pmap(list(.SD, trafos), function(x, t) {t$trafo(x)}), .SDcols = names(trafos)]
    ytest = as.matrix(oob[, c("val_accuracy", "runtime")])
    if ("method" %in% colnames(oob)) oob[, method := NULL]
    oob[, runtime := NULL]
    oob[, val_accuracy := NULL]
  } else {
    oob = NULL
    ytest = NULL
  }

  list(
    xtrain = train,
    ytrain = y,
    xtest = oob,
    ytest = ytest,
    trafos = trafos
  )
}
