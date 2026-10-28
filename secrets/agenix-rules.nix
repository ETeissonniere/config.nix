# All keys and all secrets should be post quantum compliant. This file enforces this.

let
  readRecipient = path: builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile path);
  recoveryRecipients = map readRecipient [
    ./recipients/wintermute.pub
    ./recipients/recovery.pub
  ];
  recipientsFor =
    name:
    recoveryRecipients
    ++ [
      (readRecipient (
        if builtins.match "straylight/.*" name != null then
          ./recipients/straylight.pub
        else
          ./recipients/chiba.pub
      ))
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
builtins.listToAttrs (
  map (
    name:
    let
      recipients = recipientsFor name;
    in
    assert builtins.all (recipient: builtins.substring 0 7 recipient == "age1pq1") recipients;
    {
      inherit name;
      value.publicKeys = recipients;
    }
  ) files
)
