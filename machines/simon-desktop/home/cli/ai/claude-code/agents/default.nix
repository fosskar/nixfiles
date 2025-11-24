let
  # automatically import all .md files from current directory
  agentFiles = builtins.readDir ./.;

  # convert filename to attribute name (remove .md extension)
  # e.g., "devops-troubleshooter.md" -> "devops-troubleshooter"
  toAgentName = filename: builtins.head (builtins.match "(.*)\.md" filename);

  # create agent entries from all .md files
  agentEntries = builtins.listToAttrs (
    builtins.filter (x: x != null) (
      builtins.map (
        filename:
        if agentFiles.${filename} == "regular" && builtins.match ".*\.md" filename != null then
          {
            name = toAgentName filename;
            value = builtins.readFile ./${filename};
          }
        else
          null
      ) (builtins.attrNames agentFiles)
    )
  );
in
{
  programs = {
    claude-code = {
      agents = agentEntries;
    };
  };
}
