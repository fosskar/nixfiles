_: {
  # default gatus endpoint shape used by service modules
  gatusEndpoint =
    {
      name,
      url,
      group,
      interval ? "5m",
      conditions ? [ "[STATUS] == 200" ],
    }:
    {
      inherit
        name
        url
        group
        interval
        conditions
        ;
      enabled = true;
      alerts = [ { type = "email"; } ];
    };
}
