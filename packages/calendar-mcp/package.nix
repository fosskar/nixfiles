{
  python3Packages,
  writers,
}:
writers.writePython3Bin "calendar-mcp" {
  libraries = [
    python3Packages.anyio
    python3Packages.caldav
    python3Packages.mcp
  ];
  # ruff formats to 88 columns; flake8 defaults to 79
  flakeIgnore = [ "E501" ];
} ./calendar_mcp.py
