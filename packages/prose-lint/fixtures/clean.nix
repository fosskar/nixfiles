# --wait
# -----
# the phrase "serves as the" and the word `pivotal` are mentioned, not used
# see https://example.com/pivotal
{
  a = "serves as the entry point — pivotal # not a comment";
  b = ''
    # I hope this helps — pivotal
    ''${not interpolated} '''quoted''' # still a string
  '';
  c = "${toString "nested # not a comment"} /* not a comment */";
  d' = 1;
  e = "escaped \" quote # not a comment";
}
