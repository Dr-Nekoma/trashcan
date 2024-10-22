{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    erlang_27
    rebar3
  ];

  environment.variables = {
    ERL_AFLAGS="+pc unicode -kernel shell_history enabled";
  };
}
