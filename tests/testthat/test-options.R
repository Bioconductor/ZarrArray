
test_that("ZarrArray_option_is_set()", {
    expect_true(ZarrArray_option_is_set("realization.dump.dir"))
    expect_true(isSingleString(get_ZarrArray_option("realization.dump.dir")))

    expect_true(ZarrArray_option_is_set("realization.chunk.maxsize"))
    expect_true(isSingleNumber(get_ZarrArray_option("realization.chunk.maxsize")))

    expect_true(ZarrArray_option_is_set("realization.chunk.shape"))
    expect_true(isSingleString(get_ZarrArray_option("realization.chunk.shape")))
})

