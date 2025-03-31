#include <gtest/gtest.h>
#include "../src/AhoCorasick.cpp"

TEST(AhoCorasickTest, BasicMatch) {
    AhoCorasick ac;
    string arr[] = {"he", "she", "his", "hers"};
    string text = "ahishers";
    int k = sizeof(arr) / sizeof(arr[0]);
    unordered_map<string, int> resultDict;

    ac.searchWords(arr, k, text, resultDict);

    EXPECT_EQ(resultDict["he"], 1);
    EXPECT_EQ(resultDict["she"], 1);
    EXPECT_EQ(resultDict["his"], 1);
    EXPECT_EQ(resultDict["hers"], 1);
}

TEST(AhoCorasickTest, NoMatch) {
    AhoCorasick ac;
    string arr[] = {"xyz", "abc"};
    string text = "ahishers";
    int k = sizeof(arr) / sizeof(arr[0]);
    unordered_map<string, int> resultDict;

    ac.searchWords(arr, k, text, resultDict);

    EXPECT_EQ(resultDict["xyz"], 0);
    EXPECT_EQ(resultDict["abc"], 0);
}

TEST(AhoCorasickTest, MultipleOccurrences) {
    AhoCorasick ac;
    string arr[] = {"test", "test2"};
    string text = "testtest2test";
    int k = sizeof(arr) / sizeof(arr[0]);
    unordered_map<string, int> resultDict;

    ac.searchWords(arr, k, text, resultDict);

    EXPECT_EQ(resultDict["test"], 2);
    EXPECT_EQ(resultDict["test2"], 1);
}

TEST(AhoCorasickTest, OverlappingMatches) {
    AhoCorasick ac;
    string arr[] = {"ab", "bc", "abc"};
    string text = "abc";
    int k = sizeof(arr) / sizeof(arr[0]);
    unordered_map<string, int> resultDict;

    ac.searchWords(arr, k, text, resultDict);

    EXPECT_EQ(resultDict["ab"], 1);
    EXPECT_EQ(resultDict["bc"], 1);
    EXPECT_EQ(resultDict["abc"], 1);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
