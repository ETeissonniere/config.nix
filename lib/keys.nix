{
  # Each Mac also needs its age recipient in secrets/recipients/<host>.pub.
  macs = {
    armitage = {
      ssh = "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBFP6KFlQEI/Hr5GgGLd6qUjV/EWjF2GxjixcRgbRjZaT4B9TpjF1BEdNus0RJCzgJqHQXMslbyIMYSZFminQwTgAAAAEc3NoOg==";
      builder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIgFQInsg5+mfX2ACPTrT7QkFRWq/oF3+PgOxfMrcZ+Q";
    };
    wintermute = {
      ssh = "sk-ecdsa-sha2-nistp256@openssh.com AAAAInNrLWVjZHNhLXNoYTItbmlzdHAyNTZAb3BlbnNzaC5jb20AAAAIbmlzdHAyNTYAAABBBKiSfe4i1af5LEv8gduJ9tBg0UXpCrBbVa5BmMpoYCIhEkLy098mU2lwpkgKG9o/T+Npzn1p2VztR5DHRLvqGM4AAAAEc3NoOg== default";
      builder = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTON+etnnunpOKx7DG+Hk9teQNrwrSmUSTcs3RuY1RQ wintermute-builder";
    };
  };
  straylight-host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHUM0EkrzPmz6iTD6ul5GQ1xECjbMUoln/cQOO8E2JEx root@straylight";
}
