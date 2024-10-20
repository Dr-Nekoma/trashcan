{
  age = {
    secrets = {
      environment = {
        file = ../secrets/environment.age;
        group = "wheel";
        mode = "0440";
      };

      init_sql = {
        file = ../secrets/init_sql.age;
        group = "wheel";
        mode = "0440";
      };
    };
  };
}
