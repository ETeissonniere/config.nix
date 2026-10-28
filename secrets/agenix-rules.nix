# All keys and all secrets should be post quantum compliant. This file enforces this.

let
  recipients = map (path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile path)) [
    ./recipients/chiba.pub
    ./recipients/wintermute.pub
    ./recipients/recovery.pub
  ];
  secretFiles =
    directory: prefix:
    let
      entries = builtins.readDir directory;
    in
    builtins.concatMap (
      name:
      if entries.${name} == "directory" then
        secretFiles (directory + "/${name}") "${prefix}${name}/"
      else if entries.${name} == "regular" && builtins.match ".*\\.age" name != null then
        [ "${prefix}${name}" ]
      else
        [ ]
    ) (builtins.attrNames entries);
  # Agenix exports FILE before evaluating rules, including for a new secret.
  requestedFile = builtins.getEnv "FILE";
  files =
    secretFiles ./. ""
    ++ (if builtins.match ".*\\.age" requestedFile != null then [ requestedFile ] else [ ]);
in
# No classical fallback: every secret uses only post-quantum recipients.
assert builtins.all (recipient: builtins.substring 0 7 recipient == "age1pq1") recipients;
builtins.listToAttrs (
  map (name: {
    inherit name;
    value.publicKeys = recipients;
  }) files
)
