let
  keys = import ../keys;
  everyone = keys.allKeys keys.systems keys.users;
in
{
  "lyceum_application_env.age".publicKeys = everyone;
  "lyceum_erlang_cookie.age".publicKeys = everyone;
  "pg_bouncer_auth_file.age".publicKeys = everyone;
  "pg_user_lyceum.age".publicKeys = everyone;
  "pg_user_lyceum_application.age".publicKeys = everyone;
  "pg_user_lyceum_auth.age".publicKeys = everyone;
  "pg_user_lyceum_mnesia.age".publicKeys = everyone;
  "pg_user_migrations.age".publicKeys = everyone;
}
