{ ... }:
{
  # Backward compatibility layer:
  # Existing desktop hosts reference this path.
  # New hosts should use os/core/desktop or os/core/server directly.
  imports = [
    ../desktop
  ];
}
