#include "gtest/gtest.h"
#include "gmock/gmock.h"

extern "C" {
#include "mbelib.h"
}

TEST(mbelib, synthesize_silence_f)
{
    float float_buf[160] = {1.23f, -1.12f, 4680.412f, 4800.12f, -4700.74f};

    mbe_synthesizeSilencef(float_buf);

    EXPECT_THAT(float_buf, testing::Each(0));
}

TEST(mbelib, synthesize_silence)
{
    short short_buf[160] = {3, -1, 1};

    mbe_synthesizeSilence(short_buf);

    EXPECT_THAT(short_buf, testing::Each(0));
}

TEST(mbelib, float_to_short)
{
    float float_buf[160] = {1.23f, -1.12f, 4680.412f, 4800.12f, -4700.74f};
    short short_buf[160];

    // There is a gain of 7, and clipping at +/- 32760
    short expected[160] = {8, -7, 32760, 32760, -32760};

    mbe_floattoshort(float_buf, short_buf);

    EXPECT_THAT(short_buf, testing::ElementsAreArray(expected, 160));
}
