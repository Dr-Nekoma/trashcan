{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    erlang
    rebar3
  ];

  environment.variables = {
    ERL_AFLAGS="+pc unicode -kernel shell_history enabled";
  };
}
