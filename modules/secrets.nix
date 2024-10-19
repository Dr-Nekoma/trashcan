{
  age = {
    secrets = {
      environment = {
        file = ../secrets/environment.age;
        group = "wheel";
        mode = "0440";
      };

      "init.sql" = {
        file = ../secrets/init.sql.age;
        group = "wheel";
        mode = "0440";
      };
    };
  };
}
