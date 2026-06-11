{ ... }:
# Host entry for the MacBook. Pulls in every reusable darwin module.
# Put machine-specific tweaks (hostname, host-only packages) here.
{
  imports = [
    ../../modules/darwin
  ];
}
