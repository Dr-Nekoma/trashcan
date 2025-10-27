let
  keys = import ../keys;
  everyone = keys.allKeys keys.systems keys.users;
in
{
  "lyceum_erlang_cookie.age".publicKeys = everyone;
  "pg_bouncer_auth_file.age".publicKeys = everyone;
  "pg_user_lyceum.age".publicKeys = everyone;
  "pg_user_migrations.age".publicKeys = everyone;
  "server_ssh.age".publicKeys = everyone;
}
