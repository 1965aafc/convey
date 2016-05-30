context("Svyrmir output survey.design and svyrep.design")
library(vardpoor)
library(survey)
data(eusilc) ; names( eusilc ) <- tolower( names( eusilc ) )

des_eusilc <- survey:::svydesign(ids = ~rb030, strata =~db040,  weights = ~rb050, data = eusilc)
des_eusilc <- convey_prep(des_eusilc)
des_eusilc_rep <-survey::: as.svrepdesign(des_eusilc, type= "bootstrap")

des_eusilc_rep <- convey_prep(des_eusilc_rep)

a1 <- svyrmir( ~eqincome , design = des_eusilc , age = ~age , agelim = 65 , med_old = TRUE )

a2 <- survey:::svyby(~eqincome, by = ~db040, design = des_eusilc, FUN = svyrmir, age = ~age,  agelim =65, deff = FALSE)

b1 <- svyrmir( ~eqincome , design = des_eusilc_rep , age = ~age , agelim = 65 , med_old = TRUE )

b2 <- survey:::svyby(~eqincome, by = ~db040, design = des_eusilc_rep, FUN = svyrmir, age = ~age, agelim =65, deff = FALSE)


test_that("output svyrmir",{
  expect_is(coef(a1),"numeric")
  expect_is(coef(a2), "numeric")
  expect_is(coef(b1),"numeric")
  expect_is(coef(b2),"numeric")
  expect_equal(coef(a1), coef(b1))
  expect_equal(coef(a2), coef(b2))
  expect_is(SE(a1),"numeric")
  expect_is(SE(a2), "numeric")
  expect_is(SE(b1),"numeric")
  expect_is(SE(b2),"numeric")
  expect_lte(confint(a1)[1], coef(a1))
  expect_gte(confint(a1)[2],coef(a1))
  expect_lte(confint(b1)[,1], coef(b1))
  expect_gte(confint(b1)[2], coef(b1))

  expect_equal(sum(confint(a2)[,1]<= coef(a2)),length(coef(a2)))
  expect_equal(sum(confint(a2)[,2]>= coef(a2)),length(coef(a2)))

  expect_equal(sum(confint(b2)[,1]<= coef(b2)),length(coef(b2)))
  expect_equal(sum(confint(b2)[,2]>= coef(b2)),length(coef(b2)))
})