{ pkgs }:
pkgs.testers.runNixOSTest {
  name = "linux-builder-idle-shutdown";

  nodes.machine = { ... }: {
    imports = [ (import ../modules/darwin/linux-builder/guest.nix { idleTimeout = 1; }) ];
    # Control idle shutdown manually to skip the normal timer and keep the test fast.
    systemd.timers.builder-idle-shutdown.enable = false;
    services.openssh.enable = true;
    nix.nrBuildUsers = 1;
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("sshd.service")
    machine.succeed(
        'mkdir -p /root/.ssh; ssh-keygen -q -t ed25519 -N "" -f /root/.ssh/id_ed25519; '
        "cp /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys"
    )

    for activity, start, ready, stop in [
        (
            "SSH connection",
            "systemd-run --unit=ssh-client ssh -o StrictHostKeyChecking=no root@localhost sleep infinity",
            "ss -Htn state established '( sport = :22 )' | grep .",
            "systemctl stop ssh-client",
        ),
        (
            "disconnected build",
            "systemd-run --unit=build --uid=nixbld1 sleep infinity",
            "pgrep -u nixbld1",
            "systemctl stop build",
        ),
    ]:
        with subtest(f"{activity} resets the idle deadline and keeps the builder alive"):
            machine.succeed("systemctl start builder-idle-shutdown")
            machine.sleep(2)
            machine.succeed(start)
            machine.wait_until_succeeds(ready, timeout=10)
            machine.succeed("systemctl start builder-idle-shutdown")
            machine.sleep(2)
            machine.succeed("systemctl start builder-idle-shutdown")
            machine.succeed(stop)

    with subtest("builder shuts down once activity stops and the idle deadline expires"):
        machine.wait_until_fails("ss -Htn state established '( sport = :22 )' | grep .")
        machine.succeed("systemctl start builder-idle-shutdown")
        machine.sleep(2)
        machine.succeed("systemctl start --no-block builder-idle-shutdown")
        machine.wait_for_shutdown()
  '';
}
