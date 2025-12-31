_: {
  # Force-enable the Page Table Isolation (PTI) Linux kernel feature
  # helps mitigate Meltdown and prevent some KASLR bypasses.
  security.forcePageTableIsolation = true;
}
